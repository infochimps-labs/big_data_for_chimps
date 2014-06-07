IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();

-- ***************************************************************************
--
-- === Calculating the Distribution of Numeric Values with a Histogram

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Binning Data for a Histogram
--

G_vals = FOREACH bat_seasons GENERATE G;
G_hist = FOREACH (GROUP G_vals BY G) GENERATE 
  group AS G, COUNT_STAR(G_vals) AS n_seasons;

--
-- We can separate out the two eras using the summing trick: 
--
G_vals_2 = FOREACH bat_seasons GENERATE G,
  (year_id <  1961 AND year_id > 1900 ? 1 : 0) AS G_154,
  (year_id >= 1961                   ? 1 : 0) AS G_162
  ;
G_hist_154_vs_162 = FOREACH (GROUP G_vals_2 BY G) GENERATE 
  group AS G,
  COUNT_STAR(G_vals_2) AS n_seasons,
  SUM(G_vals_2.G_154)  AS n_seasons_154,
  SUM(G_vals_2.G_162)  AS n_seasons_162
  ;


-- STORE_TABLE(G_hist, 'G_hist');
-- STORE_TABLE(G_hist_154_vs_162, 'G_hist_154_vs_162');


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Interpreting a Histogram
--

-- Different underlying mechanics will give different distributions.


DEFINE hist(table, key) RETURNS dist {
  vals = FOREACH $table GENERATE $key;
  $dist = FOREACH (GROUP vals BY $key) GENERATE
    group AS val, COUNT_STAR(vals) AS ct;
}

-- we have to be careful here because *nothing* about a professional should be taken as typical of the overall population
-- you are drawing from the extreme tails of the extreme tails of the population,
-- and there are very few 

-- Distribution of Games Played

-- Distribution of Players' Weight

age_hist = hist(bat_seasons, 'age');

-- Surely they are born and die like the rest of us?

-- Distribution of Birth and Death day of year

vitals = FOREACH peeps GENERATE
  height_in,
  10*CEIL(weight_lb/10.0) AS weight_lb,
  birth_month,
  death_month;

birth_month_hist = hist(vitals, 'birth_month');
death_month_hist = hist(vitals, 'death_month');
height_hist = hist(vitals, 'height_in');
weight_hist = hist(vitals, 'weight_lb');

STORE_TABLE(birth_month_hist, 'birth_month_hist');
STORE_TABLE(death_month_hist, 'death_month_hist');
STORE_TABLE(height_hist, 'height_hist');
STORE_TABLE(weight_hist, 'weight_hist');

-- attr_vals = FOREACH vitals GENERATE
--   FLATTEN(Transpose(height, weight, birth_month, death_month)) AS (attr, val);
-- 
-- attr_vals_nn = FILTER attr_vals BY val IS NOT NULL;
-- 
-- -- peep_stats   = FOREACH (GROUP attr_vals_nn BY attr) GENERATE
-- --   group                    AS attr,
-- --   COUNT_STAR(attr_vals_nn) AS ct_all,
-- --   COUNT(attr_vals_nn.val)  AS ct;
-- 
-- peep_stats = FOREACH (GROUP attr_vals_nn ALL) GENERATE
--   BagToMap(CountVals(attr_vals_nn.attr)) AS cts:map[long];
-- 
-- peep_hist = FOREACH (GROUP attr_vals BY (attr, val)) {
--   ct = COUNT_STAR(attr_vals);
--   GENERATE
--     FLATTEN(group) AS (attr, val),
--     ct             AS ct
--     -- , (float)ct / ((float)peep_stats.ct) AS freq
--     ;
-- };
-- peep_hist = ORDER peep_hist BY attr, val;
-- 
-- -- STORE_TABLE(peep_hist, 'peep_hist');
-- DUMP peep_stats;
-- 
-- one = LOAD '$data_dir/stats/numbers/one.tsv' AS (num:int);
-- ht = FOREACH one GENERATE peep_stats.cts#'height';
-- DUMP ht;

-- A lot of big data explorations involve population extremes: manufacturing defects, security threats, high- or low-performers. In such cases you must not rely on easy assumptions such as distributions having a central tendency, outliers being rare, or that the impact of errors can be bounded.

-- nf_chars = FOREACH bat_seasons GENERATE
--   FLATTEN(STRSPLITBAG(name_first, '(?!^)')) AS char;
-- chars_hist = FOREACH (GROUP nf_chars BY char) {
--   GENERATE group AS char, COUNT_STAR(nf_chars.char) AS ct;
-- };
-- chars_hist = ORDER chars_hist BY ct;
