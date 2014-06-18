IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

sig_seasons = load_sig_seasons();


-- ***************************************************************************
--
-- === Calculating a Histogram Within a Group
--

-- As long as the groups in question do not rival the available memory, counting how often each value occurs within a group is easily done using the DataFu `CountEach` UDF. There's been a trend over baseball's history for increased specialization

-- http://datafu.incubator.apache.org/docs/datafu/guide/bag-operations.html

-- You'll see the

DEFINE CountVals              datafu.pig.bags.CountEach('flatten');

binned = FOREACH sig_seasons GENERATE
  ( 5 * ROUND(year_id/ 5.0f)) AS year_bin,
  (20 * ROUND(H      /20.0f)) AS H_bin;

-- hist_by_year_bags = FOREACH (GROUP binned BY year_bin) {
--   H_hist_cts = CountVals(binned.H_bin);
--   GENERATE group AS year_bin, H_hist_cts AS H_hist_cts;
-- };

-- We want to normalize this to be a relative-fraction histogram, so that we can
-- make comparisons across eras even as the number of active players grows.
-- Finding the total count to divide by is a straightforward COUNT_STAR on the
-- group, but a peccadillo of Pig's syntax makes using it a bit frustrating.
-- Annoyingly, a nested FOREACH can only "see" values from the bag it's
-- operating on, so there's no natural way to reference the calculated total
-- from the FOREACH statement.
--
-- -- Won't work:
-- hist_by_year_bags = FOREACH (GROUP binned BY year_bin) {
--   H_hist_cts = CountVals(binned.H_bin);
--   tot        = 1.0f*COUNT_STAR(binned);
--   H_hist_rel = FOREACH H_hist_cts GENERATE H_bin, (float)count/tot;
--   GENERATE group AS year_bin, H_hist_cts AS H_hist_cts, tot AS tot;
-- };

--
-- The best current workaround is to generate the whole-group total in the form
-- of a bag having just that one value. Then we use the CROSS operator to graft
-- it onto each (bin,count) tuple, giving us a bag with (bin,count,total) tuples
-- -- yes, every tuple in the bag will have the same group-wide value. Finally,
-- This lets us iterate across those tuples to find the relative frequency.
--
-- It's more verbose than we'd like, but the performance hit is limited to the
-- CPU and GC overhead of creating three bags (`{(result,count)}`,
-- `{(result,count,total)}`, `{(result,count,freq)}`) in quick order.
--
hist_by_year_bags = FOREACH (GROUP binned BY year_bin) {
  H_hist_cts = CountVals(binned.H_bin);
  tot        = COUNT_STAR(binned);
  GENERATE
    group      AS year_bin,
    H_hist_cts AS H_hist,
    {(tot)}    AS info:bag{(tot:long)}; -- single-tuple bag we can feed to CROSS
};

hist_by_year = FOREACH hist_by_year_bags {
  -- Combines H_hist bag {(100,93),(120,198)...} and dummy tot bag {(882.0)}
  -- to make new (bin,count,total) bag: {(100,93,882.0),(120,198,882.0)...}
  H_hist_with_tot = CROSS   H_hist, info;
  -- Then turn the (bin,count,total) bag into the (bin,count,freq) bag we want
  H_hist_rel      = FOREACH H_hist_with_tot
    GENERATE H_bin, count AS ct, count/((float)tot) AS freq;
  GENERATE year_bin, H_hist_rel;
};

DESCRIBE hist_by_year;

STORE_TABLE(hist_by_year, 'hist_by_year');

--
-- Exercise: generate histograms-by-year
