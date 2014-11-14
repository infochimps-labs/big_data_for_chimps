IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

parks        = load_parks();
major_cities = load_us_city_pops();

-- === Set Operations on Full Tables

-- Limit our attention to prominent US stadiums:
main_parks   = FILTER parks       BY n_games >=  50 AND country_id == 'US';

-- ==== Distinct Union
--
bball_city_names = FOREACH main_parks   GENERATE city;
major_city_names = FOREACH major_cities GENERATE city;
major_or_bball    = DISTINCT (UNION bball_city_names, major_city_names);


-- ==== Distinct Union (alternative method)
--
-- Every row in combined comes from one table or the other, so we don't need to
-- filter.  To prove the point about doing the set operation on a key (rather
-- than the full record) let's keep around the state, population, and all
-- park_ids from the city.

combined     = COGROUP major_cities BY city, main_parks BY city;

major_or_parks    = FOREACH combined
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Intersection
--
-- Records lie in the set intersection when neither bag is empty.
--
major_and_parks   = FOREACH (FILTER combined BY (COUNT_STAR(major_cities) > 0L) AND (COUNT_STAR(main_parks) > 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Difference
--
-- Records lie in A-B when the second bag is empty.
--
major_minus_parks = FOREACH (FILTER combined BY (COUNT_STAR(main_parks) == 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

parks_minus_major = FOREACH (FILTER combined BY (COUNT_STAR(major_cities) == 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Symmetric Set Difference: (A-B)+(B-A)
--
-- Records lie in the symmetric difference when one or the other bag is
-- empty. (We don't have to test for them both being empty -- there wouldn't be
-- a row if that were the case)
--
major_xor_parks   = FOREACH (FILTER combined BY (COUNT_STAR(major_cities) == 0L) OR (COUNT_STAR(main_parks) == 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Equality
--
-- To illustrate the problem, we'll use a pair of trivially equal tables:
major_city_names_also = FOREACH major_cities GENERATE city;
major_xor_major = FILTER (COGROUP major_city_names BY city, major_city_names_also BY city)
  BY ((COUNT_STAR(major_city_names) == 0L) OR (COUNT_STAR(major_city_names_also) == 0L));

-- Does not work: file is empty when sets are equal
major_equals_major_fail = FOREACH (GROUP major_xor_major ALL) GENERATE
   (COUNT_STAR(major_xor_major) == 0L ? 1 : 0) AS is_equal;

-- Our integer table to the rescue! We keep around a one-record version called
-- 'one_line.tsv' having fields uno (value `1`) and zilch (value `0`)
one_line = LOAD '$data_dir/stats/numbers/one_line.tsv' AS (uno:int, zilch:int);

-- Now do a COGROUP with our one_line friend and the constant value `1`. Since
-- there is exactly one possible value for the group key, there will only be one
-- row in the output.

-- will be `1` (true)
major_equals_major = FOREACH (COGROUP one_line BY uno, major_xor_major BY 1)
  GENERATE (COUNT_STAR(major_xor_major) == 0L ? 1 : 0) AS is_equal;

-- will be `0` (false)
major_equals_parks = FOREACH (COGROUP one_line BY uno, major_xor_parks BY 1)
  GENERATE (COUNT_STAR(major_xor_parks) == 0L ? 1 : 0) AS is_equal;

STORE_TABLE(major_or_parks,     'major_or_parks');
STORE_TABLE(major_and_parks,    'major_and_parks');
STORE_TABLE(major_minus_parks,  'major_minus_parks');
STORE_TABLE(parks_minus_major,  'parks_minus_major');
STORE_TABLE(major_xor_parks,    'major_xor_parks');
STORE_TABLE(major_equals_parks, 'major_equals_parks');
STORE_TABLE(major_equals_major, 'major_equals_major');
