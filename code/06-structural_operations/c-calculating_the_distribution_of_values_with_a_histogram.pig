IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
numbers     = load_numbers_10k();

bat_careers = LOAD_RESULT('bat_careers');

-- ***************************************************************************
--
-- === Calculating the Distribution of Numeric Values with a Histogram


-- One of the most common uses of a group-and-aggregate is to create a histogram
-- showing how often each value (or range of values) of a field occur. This
-- calculates the distribution of seasons played -- that is, it counts the
-- number of players whose career lasted only a single season; who played for
-- two seasons; and so forth, up

vals = FOREACH bat_careers GENERATE n_seasons AS bin;
hist_seasons = FOREACH (GROUP vals BY bin) GENERATE
  group AS bin, COUNT_STAR(vals) AS ct;

vals = FOREACH (GROUP bat_seasons BY (player_id, name_first, name_last)) GENERATE
  COUNT_STAR(bat_seasons) AS bin, flatten(group);
hist_seasons = FOREACH (GROUP vals BY bin) {
  some_vals = LIMIT vals 3;
  GENERATE group AS bin, COUNT_STAR(vals) AS ct, BagToString(some_vals, '|');
};

-- So the pattern here is to
--
-- * project only the values,
-- * Group by the values,
-- * Produce the group as key and the count as value.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Binning Data for a Histogram
--

G_vals = FOREACH bat_careers GENERATE G AS bin;
hist_G_nobin = FOREACH (GROUP G_vals BY bin) GENERATE
  group AS bin, COUNT_STAR(G_vals) AS ct;


G_vals = FOREACH bat_careers GENERATE 50*(G/50) AS bin;
hist_G = FOREACH (GROUP G_vals BY bin) GENERATE
  group AS bin, COUNT_STAR(G_vals) AS ct;
hist_G = ORDER hist_G BY bin ASC;

--
-- ===== Power-law (Long-Tail) Distribution: Wikipedia Pageviews
--
pagecount_views = LOAD '/data/outd/wikipedia/pagecount-views.tsv' AS (val:long);
pagecount_bytes = LOAD '/data/outd/wikipedia/pagecount-bytes.tsv' AS (val:long);

view_vals = FOREACH pagecount_views GENERATE
  (long)EXP( FLOOR(LOG((val == 0 ? 0.001 : val)) * 10)/10.0) AS bin;
hist_wp_view = FOREACH (GROUP view_vals BY bin) GENERATE
  group AS bin, COUNT_STAR(view_vals) AS ct;


%default eps         0.001
%default binsz_bytes 10000
  ;

byte_vals = FOREACH pagecount_bytes {
  logbin = EXP(FLOOR( LOG((val == 0 ? 0.001 : val)) *10)/10.0);
  linbin = (long)($binsz_bytes*FLOOR(logbin / $binsz_bytes) + $binsz_bytes/2);
  GENERATE linbin AS bin;
  };
hist_wp_byte = FOREACH (GROUP byte_vals BY bin) GENERATE
  group AS bin, COUNT_STAR(byte_vals) AS ct;

-- STORE_TABLE(hist_wp_G_nobin, 'hist_G_nobin');
-- STORE_TABLE(hist_G,       'hist_G');

hist_wp_view = ORDER hist_wp_view BY bin ASC;
STORE_TABLE(hist_wp_view, 'hist_wp_view');

hist_wp_byte = ORDER hist_wp_byte BY bin ASC;
STORE_TABLE(hist_wp_byte, 'hist_wp_byte');


-- -- QEM: needs prose (perhaps able to draw from prose file)
--
-- --
-- -- Note: the above snippet is what's in the book. We're actually going to steal
-- -- a topic from later ("Filling Gaps in a List") because it makes it much easier
-- -- to import into excel.
-- --
-- all_bins = FILTER numbers BY (num0 < 280);
-- hist_H = FOREACH (COGROUP H_vals BY H, all_bins BY num0) GENERATE
--   group AS val, (COUNT_STAR(H_vals) == 0L ? Null : COUNT_STAR(H_vals)) AS ct;
--
--
-- -- What binsize? These zoom in on the tail -- more than 2000 games played. A bin size of 200 is too coarse; it washes out the legitimate gaps. The bin size of 2 is too fine -- the counts are small and there are many trivial gaps. We chose a bin size of 50 games; it's meaningful (50 games represents about 1/3 of a season), it gives meaty counts per bin even when the population starts to become sparse, while preserving the gaps that demonstrate the epic scope of the career of Pete Rose (our 3,562-game outlier).
--
--
-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- --
-- -- ==== Interpreting Histograms and Quantiles
-- --
--
-- -- Different underlying mechanics will give different distributions.
--
-- DEFINE histogram(table, key) RETURNS dist {
--   vals = FOREACH $table GENERATE $key;
--   $dist = FOREACH (GROUP vals BY $key) GENERATE
--     group AS val, COUNT_STAR(vals) AS ct;
-- };
--
-- DEFINE hist_binnedogram(table, key, binsize, maxval) RETURNS dist {
--   numbers = load_numbers_10k();
--   vals = FOREACH $table GENERATE (ROUND($key / $binsize) * $binsize) AS bin;
--   all_bins = FOREACH numbers GENERATE (num0 * $binsize) AS bin;
--   all_bins = FILTER  all_bins BY (bin <= $maxval);
--   $dist = FOREACH (COGROUP vals BY bin, all_bins BY bin) GENERATE
--     group AS bin, (COUNT_STAR(vals) == 0L ? Null : COUNT_STAR(vals)) AS ct;
-- };
--
-- season_hist_G = histogram(bat_seasons, 'G');
-- career_hist_G = hist_binnedogram(bat_careers, 'G', 50, 3600);
--
-- career_hist_G_2   = hist_binnedogram(bat_careers, 'G', 2, 3600);
-- career_hist_G_200 = hist_binnedogram(bat_careers, 'G', 200, 3600);
--
-- career_hist_HR = hist_binnedogram(bat_careers, 'HR', 10, 800);
--
--
-- -- Distribution of Games Played
--
-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- --
-- -- ==== Extreme Populations and Confounding Factors
--
-- -- To reach the major leagues, a player must possess multiple extreme
-- -- attributes: ones that are easy to measure, like being tall or being born in a
-- -- country where baseball is popular; and ones that are not, like field vision,
-- -- clutch performance, the drive to put in outlandishly many hours practicing
-- -- skills. Any time you are working with extremes as we are, you must be very
-- -- careful to assume their characteristics resemble the overall population's.
--
-- -- Here again are the graphs for players' height and weight, but now graphed
-- -- against (in light blue) the distribution of height/weight for US males aged
-- -- 20-29 footnote:[US Census Department, Statistical Abstract of the United States.
-- -- Tables 206 and 209, Cumulative Percent Distribution of Population by
-- -- (Weight/Height) and Sex, 2007-2008; uses data from the U.S. National Center
-- -- for Health Statistics].
-- --
-- -- The overall-population distribution is shown with light blue bars, overlaid
-- -- with a normal distribution curve for illustrative purposes. The population of
-- -- baseball players deviates predictably from the overall population: it's an
-- -- advantage to The distribution of player weights, meanwhile, is shifted
-- -- somewhat but with a dramatically smaller spread.
--
--
-- -- Surely at least baseball players are born and die like the rest of us, though?
--
-- -- Distribution of Birth and Death day of year
--
-- vitals = FOREACH peeps GENERATE
--   height_in,
--   10*CEIL(weight_lb/10.0) AS weight_lb,
--   birth_month,
--   death_month;
--
-- birth_hist_month = histogram(vitals, 'birth_month');
-- death_hist_month = histogram(vitals, 'death_month');
-- hist_height = histogram(vitals, 'height_in');
-- hist_weight = histogram(vitals, 'weight_lb');
--
-- attr_vals = FOREACH vitals GENERATE
--   FLATTEN(Transpose(height, weight, birth_month, death_month)) AS (attr, val);
--
-- attr_vals_nn = FILTER attr_vals BY val IS NOT NULL;
--
-- -- peep_stats   = FOREACH (GROUP attr_vals_nn BY attr) GENERATE
-- --   group                        AS attr,
-- --   COUNT_STAR(attr_vals_nn)     AS ct_all,
-- --   COUNT_STAR(attr_vals_nn.val) AS ct;
--
-- peep_stats = FOREACH (GROUP attr_vals_nn ALL) GENERATE
--   BagToMap(CountVals(attr_vals_nn.attr)) AS cts:map[long];
--
-- hist_peep = FOREACH (GROUP attr_vals BY (attr, val)) {
--   ct = COUNT_STAR(attr_vals);
--   GENERATE
--     FLATTEN(group) AS (attr, val),
--     ct             AS ct
--     -- , (float)ct / ((float)peep_stats.ct) AS freq
--     ;
-- };
-- hist_peep = ORDER hist_peep BY attr, val;
--
-- one = LOAD '$data_dir/stats/numbers/one.tsv' AS (num:int);
-- ht = FOREACH one GENERATE peep_stats.cts#'height';
--
-- -- A lot of big data analyses explore population extremes: manufacturing
-- -- defects, security threats, disease carriers, peak performers.  Elements
-- -- arrive into these extremes exactly because multiple causative features drive
-- -- them there (such as an advantageous height or birth month); and a host of
-- -- other conflated features follow from those deviations (such as those stemming
-- -- from the level of fitness athletes maintain).
-- --
-- -- So whenever you are examining populations of outliers, you cannot depend on
-- -- their behavior resembling the universal population. Normal distributions may
-- -- not remain normal and may not even retain a central tendency; independent
-- -- features in the general population may become tightly coupled in the outlier
-- -- group; and a host of other easy assumptions become invalid. Stay alert.
-- --
--
--
-- STORE_TABLE(hist_seasons, 'hist_seasons');
-- -- STORE_TABLE(career_hist_G,     'career_hist_G');
-- -- STORE_TABLE(career_hist_G_2,   'career_hist_G_2');
-- -- STORE_TABLE(career_hist_G_200, 'career_hist_G_200');
-- -- STORE_TABLE(career_hist_HR,    'career_hist_HR');
--
-- -- STORE_TABLE(hist_peep, 'hist_peep');
-- -- STORE_TABLE(birth_hist_month, 'birth_hist_month');
-- -- STORE_TABLE(death_hist_month, 'death_hist_month');
-- -- STORE_TABLE(hist_height, 'hist_height');
-- -- STORE_TABLE(hist_weight, 'hist_weight');
