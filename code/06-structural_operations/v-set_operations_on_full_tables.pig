IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

parks        = load_parks();
major_cities = load_us_city_pops();

-- === Set Operations on Full Tables

-- To demonstrate full-table set operations, we can relate the locations of
-- baseball stadiums with the set of major US cities footnote:[We'll take "major
-- city" to mean one of the top 60 incorporated places in the United States or
-- Puerto Rico; see the "Overview of Datasets" (REF) for source information].

-- Limit our attention to prominent US stadiums:
main_parks   = FILTER parks       BY n_games >=  50 AND country_id == 'US';

-- ==== Distinct Union
--
-- If the only contents of the tables are the set membership keys, finding the
-- distinct union of two tables is done just how it's spelled: apply union, then
-- distinct.
--
bball_city_names = FOREACH main_parks   GENERATE city;
major_city_names = FOREACH major_cities GENERATE city;
major_or_bball    = DISTINCT (UNION bball_city_names, major_city_names);

--
-- For all the other set operations, or when you want to base the distinct union on
-- keys (rather than the full record),
--
-- Two notes. First, since COUNT_STAR returns a value of type long, we do the
-- comparison against `0L` (a long) and not `0` (an int). Second, we test
-- against the value of `COUNT_STAR(bag)`, and not `SIZE(bag)` or
-- `IsEmpty(bag)`. Those latter two require actually materializing the bag --
-- all the data is sent to the reducer, and no combiners can be used.
--

combined     = COGROUP major_cities BY city, main_parks BY city;

-- ==== Distinct Union (alternative method)
--
-- Every row in combined comes from one table or the other.
major_or_parks    = FOREACH combined
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Intersection
major_and_parks   = FOREACH (FILTER combined BY (COUNT_STAR(major_cities) > 0L) AND (COUNT_STAR(main_parks) > 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Difference: A-B
major_minus_parks = FOREACH (FILTER combined BY (COUNT_STAR(main_parks) == 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Difference: B-A
parks_minus_major = FOREACH (FILTER combined BY (COUNT_STAR(major_cities) == 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Symmetric Set Difference: (A-B)+(B-A)
major_xor_parks   = FOREACH (FILTER combined BY (COUNT_STAR(major_cities) == 0L) OR (COUNT_STAR(main_parks) == 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Equality
--
-- Any of the tests described under "Set Operations within Groups" (REF) will
-- work to determine set equality, but unless you're already calculating one of
-- the set operations above you should use the "symmetric difference is empty"
-- test. Doing so is a bit more fiddly than you'd think.
--
-- To illustrate the problem, we'll use a pair of trivially equal tables:
major_city_names_also = FOREACH major_cities GENERATE city;
major_xor_major = FILTER (COGROUP major_city_names BY city, major_city_names_also BY city)
  BY ((COUNT_STAR(major_city_names) == 0L) OR (COUNT_STAR(major_city_names_also) == 0L));

-- Now you'd think that counting the elements of `major_xor_major` would work.
-- But since `major_xor_major` is empty, _the FOREACH has no lines to operate
-- on_. When the two sets of keys are equal, the output file is not a `1` as
-- you'd expect, it's an empty file.

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

-- STORE_TABLE(major_or_parks,     'major_or_parks');
-- STORE_TABLE(major_and_parks,    'major_and_parks');
-- STORE_TABLE(major_minus_parks,  'major_minus_parks');
-- STORE_TABLE(parks_minus_major,  'parks_minus_major');
-- STORE_TABLE(major_xor_parks,    'major_xor_parks');
-- STORE_TABLE(major_equals_parks, 'major_equals_parks');
STORE_TABLE(major_equals_major, 'major_equals_major');
