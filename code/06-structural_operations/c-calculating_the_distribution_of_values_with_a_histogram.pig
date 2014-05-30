IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Calculating the Distribution of Values with a Histogram


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Binning Data for a Histogram
--

G_vals = FOREACH bat_seasons GENERATE G;
G_hist = FOREACH (GROUP G_vals BY G) GENERATE 
  group AS G, COUNT(G_vals) AS n_seasons;

rmf                $out_dir/g_hist;
STORE G_hist INTO '$out_dir/g_hist';

-- -- We can separate out the two eras using the summing trick: 
-- 
-- G_vals = FOREACH bat_seasons GENERATE G,
--   (year_id <  1961 AND year_id > 1900 ? 1 : 0) AS G_154,
--   (year_id >= 1961                   ? 1 : 0) AS G_162
--   ;
-- G_hist = FOREACH (GROUP G_vals BY G) GENERATE 
--   group AS G,
--   COUNT(G_vals) AS n_seasons,
--   SUM(G_vals.G_154) AS n_seasons_154,
--   SUM(G_vals.G_162) AS n_seasons_162
--   ;
-- 
-- rmf                         $out_dir/g_hist_154_vs_162;
-- STORE winloss_record2 INTO '$out_dir/g_hist_154_vs_162';
