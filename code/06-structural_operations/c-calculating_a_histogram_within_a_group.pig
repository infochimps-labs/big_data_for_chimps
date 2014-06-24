IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

sig_seasons = load_sig_seasons();

%DEFAULT yr_binsz 5
%DEFAULT HH_binsz 25
%DEFAULT HR_binsz 10
  ;

-- ***************************************************************************
--
-- === Calculating a Histogram Within a Group
--

DEFINE CountVals              datafu.pig.bags.CountEach('flatten');

binned = FOREACH sig_seasons GENERATE
  ($yr_binsz * (int)FLOOR(1.0f* year_id / $yr_binsz)) AS year_bin,
  ($HH_binsz * (int)FLOOR(1.0f* H       / $HH_binsz)) AS HH_bin;

year_hists_bags = FOREACH (GROUP binned BY year_bin) {
  HH_cts = CountVals(binned.HH_bin);
  GENERATE
    group  AS year_bin,
    HH_cts AS HH_cts:bag{t:(bin:int, ct:int)};
};

-- -- Won't work:
-- year_hists_bags = FOREACH (GROUP binned BY year_bin) {
--   HH_cts = CountVals(binned.HH_bin);
--   tot        = 1.0f*COUNT_STAR(binned);
--   HH_hist_rel = FOREACH HH_cts GENERATE bin, (float)count/tot;
--   GENERATE group AS year_bin, HH_cts AS HH_cts, tot AS tot;
-- };

-- Workaround: generate bag having just that one value, CROSS it onto each (bin,count) tuple,
-- divide to find the relative frequency.
--
year_hists_bags = FOREACH (GROUP binned BY year_bin) {
  HH_cts = CountVals(binned.HH_bin);
  tot    = COUNT_STAR(binned);
  GENERATE
    group      AS year_bin,
    HH_cts     AS HH_cts:bag{t:(bin:int, ct:int)},
    {(tot)}    AS info:bag{(tot:long)}; -- single-tuple bag we can feed to CROSS
};

year_hists = FOREACH year_hists_bags {
  -- Combines HH_hist bag {(100,93),(120,198)...} and dummy tot bag {(882.0)}
  -- to make new (bin,count,total) bag: {(100,93,882.0),(120,198,882.0)...}
  HH_hist_with_tot = CROSS   HH_cts, info;
  -- Then turn the (bin,count,total) bag into the (bin,count,freq) bag we want
  HH_hist_rel      = FOREACH HH_hist_with_tot
    GENERATE bin, ct, ct/((float)tot) AS freq;
  GENERATE year_bin, HH_hist_rel;
};

DESCRIBE year_hists;


-- ***************************************************************************
--
-- Omit from book: do this with H and HR both
--

binned = FOREACH sig_seasons GENERATE year_id,
  ($yr_binsz * (int)FLOOR(1.0f* year_id / $yr_binsz)) AS year_bin, 
  ($HH_binsz * (int)FLOOR(1.0f* H       / $HH_binsz)) AS HH_bin,
  ($HR_binsz * (int)FLOOR(1.0f* HR      / $HR_binsz)) AS HR_bin;

year_hists_bags = FOREACH (GROUP binned BY year_bin) {
  HH_cts = CountVals(binned.HH_bin);
  HR_cts = CountVals(binned.HR_bin);
  tot    = COUNT_STAR(binned);
  GENERATE
    group      AS year_bin,
    MIN(binned.year_id) AS year_bin_min, MAX(binned.year_id) AS year_bin_max,
    HH_cts     AS HH_cts:bag{t:(bin:int, ct:int)},
    HR_cts     AS HR_cts:bag{t:(bin:int, ct:int)},
    {(tot)}    AS info:bag{(tot:long)}; -- single-tuple bag we can feed to CROSS
};

year_hists = FOREACH year_hists_bags {
  -- Make (bin,count,total) bag, turn it into the (bin,count,freq) bag we want
  HH_hist_with_tot = CROSS   HH_cts, info;
  HH_hist_rel      = FOREACH HH_hist_with_tot
    GENERATE bin, ct, ct/((float)tot) AS freq;

  HR_hist_with_tot = CROSS   HR_cts, info;
  HR_hist_rel      = FOREACH HR_hist_with_tot
    GENERATE bin, ct, ct/((float)tot) AS freq;
  GENERATE year_bin, year_bin_min, year_bin_max, HH_hist_rel, HR_hist_rel;
};

DESCRIBE year_hists;

year_hists_HH = FOREACH year_hists {
  HH_hist_rel_o = ORDER HH_hist_rel BY bin ASC;
  HH_hist_rel_x = FILTER HH_hist_rel_o BY (bin >= 90);
  HH_hist_vis   = FOREACH HH_hist_rel_x GENERATE 
    SPRINTF('%1$3d: %3$4.0f', bin, ct, ROUND_TO(100*freq, 1));
  GENERATE year_bin, BagToString(HH_hist_vis, '  ');
  };

year_hists_HR = FOREACH year_hists {
  HR_hist_rel_o = ORDER HR_hist_rel BY bin ASC;
  HR_hist_rel_x = FILTER HR_hist_rel_o BY (bin >= 0);
  HR_hist_vis   = FOREACH HR_hist_rel_x GENERATE
    SPRINTF('%1$3d: %3$4.0f', bin, ct, ROUND_TO(100*freq, 1));
  GENERATE year_bin, BagToString(HR_hist_vis, '  ');
  };

-- SPRINTF((freq < 0.05 ? '%3d: %-4.1f' : '%3d: %-4.0f'), bin, ROUND_TO(100*freq, 1));

STORE_TABLE(year_hists_HH, 'HH_year_hists');
STORE_TABLE(year_hists_HR, 'HR_year_hists');

sh cat $out_dir/HH_year_hists/part*
sh cat $out_dir/HR_year_hists/part*
--
-- Exercise: generate histograms-by-year
