IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
parks       = load_parks();
major_cities   = LOAD '$rawd/geo/census/us_city_pops.tsv' AS (city:chararray, state:chararray, pop_2011:int);

bat_seasons = FILTER bat_seasons BY PA      >= 450;
parks       = FILTER parks       BY n_games >=  50;

-- === Set Operations
-- ==== Distinct Union
-- ==== Set Intersection
-- ==== Set Difference
-- ==== Set Equality
-- ==== Symmetric Set Difference

bball_cities = FOREACH parks GENERATE park_id, city;

combined = COGROUP major_cities BY city, bball_cities BY city;

major_or_bball    = FOREACH combined GENERATE group AS city;

major_and_bball   = FOREACH (FILTER combined BY
  (NOT IsEmpty(major_cities)) AND (NOT IsEmpty(bball_cities))) GENERATE group AS city;

major_minus_bball = FOREACH (FILTER combined BY
  (IsEmpty(bball_cities))) GENERATE group AS city;

bball_minus_major = FOREACH (FILTER combined BY
  (IsEmpty(major_cities))) GENERATE group AS city;

major_xor_bball   = FOREACH (FILTER combined BY
  (IsEmpty(major_cities)) OR (IsEmpty(bball_cities))) GENERATE group AS city;

STORE_TABLE(major_or_bball,    'major_or_bball');
STORE_TABLE(major_and_bball,   'major_and_bball');
STORE_TABLE(major_minus_bball, 'major_minus_bball');
STORE_TABLE(bball_minus_major, 'bball_minus_major');
STORE_TABLE(major_xor_bball,   'major_xor_bball');
