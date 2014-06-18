IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

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
seasons_hist = FOREACH (GROUP vals BY bin) GENERATE
  group AS bin, COUNT_STAR(vals) AS ct;

vals = FOREACH (GROUP bat_seasons BY (player_id, name_first, name_last)) GENERATE
  COUNT_STAR(bat_seasons) AS bin, flatten(group);
seasons_hist = FOREACH (GROUP vals BY bin) {
  some_vals = LIMIT vals 3;
  GENERATE group AS bin, COUNT_STAR(vals) AS ct, BagToString(some_vals, '|');
}

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Binning Data for a Histogram
--

H_vals = FOREACH bat_seasons GENERATE H;
H_hist = FOREACH (GROUP H_vals BY H) GENERATE
  group AS val, COUNT_STAR(H_vals) AS ct;

-- QEM: needs prose (perhaps able to draw from prose file)

--
-- Note: the above snippet is what's in the book. We're actually going to steal
-- a topic from later ("Filling Gaps in a List") because it makes it much easier
-- to import into excel.
--
all_bins = FILTER numbers BY (num0 < 280);
H_hist = FOREACH (COGROUP H_vals BY H, all_bins BY num0) GENERATE
  group AS val, (COUNT_STAR(H_vals) == 0L ? Null : COUNT_STAR(H_vals)) AS ct;


-- What binsize? These zoom in on the tail -- more than 2000 games played. A bin size of 200 is too coarse; it washes out the legitimate gaps. The bin size of 2 is too fine -- the counts are small and there are many trivial gaps. We chose a bin size of 50 games; it's meaningful (50 games represents about 1/3 of a season), it gives meaty counts per bin even when the population starts to become sparse, while preserving the gaps that demonstrate the epic scope of the career of Pete Rose (our 3,562-game outlier).


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Interpreting Histograms and Quantiles
--

-- Different underlying mechanics will give different distributions.

DEFINE histogram(table, key) RETURNS dist {
  vals = FOREACH $table GENERATE $key;
  $dist = FOREACH (GROUP vals BY $key) GENERATE
    group AS val, COUNT_STAR(vals) AS ct;
};

DEFINE binned_histogram(table, key, binsize, maxval) RETURNS dist {
  numbers = load_numbers_10k();
  vals = FOREACH $table GENERATE (ROUND($key / $binsize) * $binsize) AS bin;
  all_bins = FOREACH numbers GENERATE (num0 * $binsize) AS bin;
  all_bins = FILTER  all_bins BY (bin <= $maxval);
  $dist = FOREACH (COGROUP vals BY bin, all_bins BY bin) GENERATE
    group AS bin, (COUNT_STAR(vals) == 0L ? Null : COUNT_STAR(vals)) AS ct;
};

season_G_hist = histogram(bat_seasons, 'G');
career_G_hist = binned_histogram(bat_careers, 'G', 50, 3600);

career_G_hist_2   = binned_histogram(bat_careers, 'G', 2, 3600);
career_G_hist_200 = binned_histogram(bat_careers, 'G', 200, 3600);

career_HR_hist = binned_histogram(bat_careers, 'HR', 10, 800);


-- Distribution of Games Played

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Extreme Populations and Confounding Factors

-- To reach the major leagues, a player must possess multiple extreme
-- attributes: ones that are easy to measure, like being tall or being born in a
-- country where baseball is popular; and ones that are not, like field vision,
-- clutch performance, the drive to put in outlandishly many hours practicing
-- skills. Any time you are working with extremes as we are, you must be very
-- careful to assume their characteristics resemble the overall population's.

-- Here again are the graphs for players' height and weight, but now graphed
-- against (in light blue) the distribution of height/weight for US males aged
-- 20-29 footnote:[US Census Department, Statistical Abstract of the United States.
-- Tables 206 and 209, Cumulative Percent Distribution of Population by
-- (Weight/Height) and Sex, 2007-2008; uses data from the U.S. National Center
-- for Health Statistics].
--
-- The overall-population distribution is shown with light blue bars, overlaid
-- with a normal distribution curve for illustrative purposes. The population of
-- baseball players deviates predictably from the overall population: it's an
-- advantage to The distribution of player weights, meanwhile, is shifted
-- somewhat but with a dramatically smaller spread.


-- Surely at least baseball players are born and die like the rest of us, though?

-- Distribution of Birth and Death day of year

vitals = FOREACH peeps GENERATE
  height_in,
  10*CEIL(weight_lb/10.0) AS weight_lb,
  birth_month,
  death_month;

birth_month_hist = histogram(vitals, 'birth_month');
death_month_hist = histogram(vitals, 'death_month');
height_hist = histogram(vitals, 'height_in');
weight_hist = histogram(vitals, 'weight_lb');

attr_vals = FOREACH vitals GENERATE
  FLATTEN(Transpose(height, weight, birth_month, death_month)) AS (attr, val);

attr_vals_nn = FILTER attr_vals BY val IS NOT NULL;

-- peep_stats   = FOREACH (GROUP attr_vals_nn BY attr) GENERATE
--   group                        AS attr,
--   COUNT_STAR(attr_vals_nn)     AS ct_all,
--   COUNT_STAR(attr_vals_nn.val) AS ct;

peep_stats = FOREACH (GROUP attr_vals_nn ALL) GENERATE
  BagToMap(CountVals(attr_vals_nn.attr)) AS cts:map[long];

peep_hist = FOREACH (GROUP attr_vals BY (attr, val)) {
  ct = COUNT_STAR(attr_vals);
  GENERATE
    FLATTEN(group) AS (attr, val),
    ct             AS ct
    -- , (float)ct / ((float)peep_stats.ct) AS freq
    ;
};
peep_hist = ORDER peep_hist BY attr, val;

one = LOAD '$data_dir/stats/numbers/one.tsv' AS (num:int);
ht = FOREACH one GENERATE peep_stats.cts#'height';

-- A lot of big data analyses explore population extremes: manufacturing
-- defects, security threats, disease carriers, peak performers.  Elements
-- arrive into these extremes exactly because multiple causative features drive
-- them there (such as an advantageous height or birth month); and a host of
-- other conflated features follow from those deviations (such as those stemming
-- from the level of fitness athletes maintain).
--
-- So whenever you are examining populations of outliers, you cannot depend on
-- their behavior resembling the universal population. Normal distributions may
-- not remain normal and may not even retain a central tendency; independent
-- features in the general population may become tightly coupled in the outlier
-- group; and a host of other easy assumptions become invalid. Stay alert.
--


STORE_TABLE(seasons_hist, 'seasons_hist');
-- STORE_TABLE(career_G_hist,     'career_G_hist');
-- STORE_TABLE(career_G_hist_2,   'career_G_hist_2');
-- STORE_TABLE(career_G_hist_200, 'career_G_hist_200');
-- STORE_TABLE(career_HR_hist,    'career_HR_hist');

-- STORE_TABLE(peep_hist, 'peep_hist');
-- STORE_TABLE(birth_month_hist, 'birth_month_hist');
-- STORE_TABLE(death_month_hist, 'death_month_hist');
-- STORE_TABLE(height_hist, 'height_hist');
-- STORE_TABLE(weight_hist, 'weight_hist');
