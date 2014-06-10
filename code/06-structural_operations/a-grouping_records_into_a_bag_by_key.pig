IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Grouping Records into a Bag by Key
--

-- The GROUP BY operation is at the heart of every structural operation.
-- Here, we collect all the stadiums each team has played for:
--
park_tm_yr_g = GROUP park_tm_yr BY team_id;

-- The result of a group is always a field called 'group', having the schema of
-- the key (atom) or keys (tuple); and then one field per grouped table, each
-- named for the table it came from. Notice that the name we used to refer to
-- the _table_ is now also the name for a _field_. This will confuse you at
-- first, but soon become natural. Until then, use `DESCRIBE` liberally.
--
-- DESCRIBE park_tm_yr_g;
--   park_tm_yr_g: {
--     group: chararray,
--     park_tm_yr: {
--         ( park_id: chararray, team_id: chararray, year_id: long,
--           beg_date: chararray, end_date: chararray, n_games: long ) } }

-- Notice that the _full record_ is kept, even including the keys:
--
-- => LIMIT park_tm_yr_g 2 ; DUMP @;
-- (ALT,{(ALT01,ALT,1884,1884-04-30,1884-05-31,18)})
-- (ANA,{(ANA01,ANA,2001,2001-04-10,2001-10-07,81),(ANA01,ANA,2010,2010-04-05,2010-09-29,81),...})

-- Because of this redundancy, it's pretty common to immediately project using a
-- FOREACH, .
--
-- We want to keep the team_id 
team_py_pairs = FOREACH (GROUP park_tm_yr BY team_id) GENERATE
  group AS team_id, park_tm_yr.(park_id,year_id);

-- Notice the `park_tm_yr.(park_id,year_id)` form, which gives us a bag of
-- (park_id,year_id) pairs. Using `park_tm_yr.park_id, park_tm_yr.year_id`
-- instead gives two bags, one with park_id tuples and one with year_id tuples:
team_py_bags = FOREACH (GROUP park_tm_yr BY team_id) GENERATE
  group AS team_id, park_tm_yr.park_id, park_tm_yr.year_id;

-- (Notice the which you can do cleanly with an inline GROUP BY statement

-- Compare:
--
-- => LIMIT team_py_pairs 2 ; DUMP @;
-- (ALT,{(ALT01,1884)})
-- (ANA,{(ANA01,2001),(ANA01,2010),(ANA01,2002),...})
-- => LIMIT team_py_bags 2 ; DUMP @;
-- (ALT, {(ALT01)}, {(1884)})
-- (ANA, {(ANA01),(ANA01),(ANA01),...}, {(2001),(2010),(2002),...})
--
-- DESCRIBE team_py_pairs;
--   team_parks: { team_id: chararray, { (park_id: chararray, year_id: long) } }
-- DESCRIBE team_py_bags;
--   team_parks: { team_id: chararray, { (park_id: chararray) }, { (year_id: long) } }

-- You can group on multiple fields.  For each park and team, find all the years
-- that the park hosted that team:
--
park_team_g = GROUP park_tm_yr BY (park_id, team_id);

-- The first field is still called 'group', but it's now a tuple
DESCRIBE park_team_g;
--   park_team_g: {
--     group: (park_id: chararray, team_id: chararray),
--     park_tm_yr: { (park_id: chararray, team_id: chararray, year_id: long, ...) } }

-- ====

-- And so we have to dereference into group:
park_team_occupied = FOREACH(GROUP park_tm_yr BY (park_id, team_id)) GENERATE
  group.park_id, group.team_id, park_tm_yr.year_id;
--
-- => LIMIT park_team_occupied 3 ; DUMP @;
-- (ALB01,TRN,{(1882),(1880),(1881)})
-- (ALT01,ALT,{(1884)})
-- (ANA01,ANA,{(2009),(2008),(1997)...})
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== FOREACH with GROUP BY lets you summarize and 
--

-- Operations that summarize the grouped value: This finds all teams that called
-- more than one stadium "home" during a year:
team_n_parks = FOREACH (GROUP park_tm_yr BY (team_id,year_id)) GENERATE
  group.team_id,
  group.year_id,
  COUNT_STAR(park_tm_yr) AS n_parks;
vagabonds = FILTER team_n_parks BY n_parks > 1;
-- => LIMIT (ORDER vagabonds BY n_parks DESC) 4; DUMP @;

-- Always, always look through the data and seek 'second stories'. In this case
-- you'll notice that the 1898 Cleveland Spiders used seven(!) stadiums as home
-- field.

