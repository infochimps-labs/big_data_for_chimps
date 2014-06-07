IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
parks       = load_parks();
big_cities  = load_us_city_pops();

bat_seasons = FILTER bat_seasons BY PA      >= 450;
parks       = FILTER parks       BY n_games >=  50;

-- === Set Operations

bball_cities = FOREACH parks GENERATE park_id, city;

combined     = COGROUP big_cities BY city, bball_cities BY city;
-- output (note: in execution Pig will project out the rest of the fields besides city)
-- -- (Tucson,{(Tucson,Arizona,525796)},{})
-- -- (Anaheim,{(Anaheim,California,341361)},{(ANA01,Anaheim)})
-- -- (Atlanta,{(Atlanta,Georgia,432427)},{(ATL01,Atlanta),(ATL02,Atlanta)})
-- -- (Buffalo,{},{(BUF02,Buffalo),(BUF01,Buffalo),(BUF04,Buffalo),(BUF03,Buffalo)})

-- ==== Distinct Union
big_or_bball    = FOREACH combined
  GENERATE group AS city;

-- ==== Set Intersection
big_and_bball   = FOREACH (FILTER combined BY
  (NOT IsEmpty(big_cities)) AND (NOT IsEmpty(bball_cities)))
  GENERATE group AS city;

-- ==== Set Difference
big_minus_bball = FOREACH (FILTER combined BY
  (IsEmpty(bball_cities)))
  GENERATE group AS city;

-- ==== Set Equality
bball_minus_big = FOREACH (FILTER combined BY
  (IsEmpty(big_cities)))
  GENERATE group AS city;

-- ==== Symmetric Set Difference
big_xor_bball   = FOREACH (FILTER combined BY
  (IsEmpty(big_cities)) OR (IsEmpty(bball_cities)))
  GENERATE group AS city;

STORE_TABLE(big_or_bball,    'big_or_bball');
STORE_TABLE(big_and_bball,   'big_and_bball');
STORE_TABLE(big_minus_bball, 'big_minus_bball');
STORE_TABLE(bball_minus_big, 'bball_minus_big');
STORE_TABLE(big_xor_bball,   'big_xor_bball');
