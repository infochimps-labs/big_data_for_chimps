IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
numbers_10k = load_numbers_10k();

-- ***************************************************************************
--
-- === Joining on an Integer Table to Fill Holes in a List

-- In some cases you want to ensure that there is an output row for each
-- potential value of a key. For example, a histogram of career hits will show
-- that Pete Rose (4256 hits) and Ty Cobb (4189 hits) have so many more hits
-- than the third-most player (Hank Aaron, 3771 hits) there are gaps in the
-- output bins.
--
-- To fill the gaps, generate a list of all the potential keys, then generate
-- your (possibly hole-y) result table, and do a join of the keys list (LEFT
-- OUTER) with results. In some cases, this requires one job to enumerate the
-- keys and a separate job to calculate the results. For our purposes here, we
-- can simply use the integer table. (We told you it was surprisingly useful!)


--
-- Regular old histogram of career hits, bin size 100
--
H_vals = FOREACH (GROUP bat_seasons BY player_id) GENERATE
  100*ROUND(SUM(bat_seasons.H)/100.0) AS bin;
H_hist_0 = FOREACH (GROUP H_vals BY bin) GENERATE
  group AS bin, COUNT_STAR(H_vals) AS ct;

--
-- Generate a list of all the bins we want to keep.
--
H_bins = FOREACH (FILTER numbers_10k BY num0 <= 43) GENERATE 100*num0  AS bin;

--
-- Perform a LEFT JOIN of bins with histogram counts Missing rows will have a
-- null `ct` value, which we can convert to zero.
--
H_hist = FOREACH (JOIN H_bins BY bin LEFT OUTER, H_hist_0 BY bin) GENERATE
  H_bins::bin,
  ct,                    -- leaves missing values as null
  (ct IS NULL ? 0 : ct)  -- converts missing values to zero
;

STORE_TABLE(H_hist, 'histogram_H');
