IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
people            = load_people();
teams             = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Completely Summarizing the Values of a Field


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Completely Summarizing the Values of a String Field
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Finding the Size of a String in Bytes or in Characters
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Completely Summarizing the Values of a Numeric Field
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Calculating Quantiles
--

tc_cities = LOAD '$rawd/geo/census/us_city_pops.tsv' AS (city:chararray, state:chararray, pop_2011:int);

parks = load_parks();
parks  = FILTER parks BY n_games > 50;
bb_cities = FOREACH parks GENERATE park_id, city;

summary = summarize_strings_by(parks, 'park_id',    'ALL'); DUMP summary;
summary = summarize_strings_by(parks, 'park_name',  'ALL'); DUMP summary;
summary = summarize_strings_by(parks, 'city',       'ALL'); DUMP summary;
summary = summarize_strings_by(parks, 'streetaddr', 'ALL'); DUMP summary;
summary = summarize_strings_by(parks, 'url',        'ALL'); DUMP summary;
summary = summarize_strings_by(parks, 'allnames',   'ALL'); DUMP summary;
summary = summarize_strings_by(parks, 'allteams',   'ALL'); DUMP summary;
summary = summarize_strings_by(parks, 'comments',   'ALL'); DUMP summary;
summary = summarize_strings_by(parks, 'state_id',   'ALL'); DUMP summary;
summary = summarize_strings_by(parks, 'country_id', 'ALL'); DUMP summary;
