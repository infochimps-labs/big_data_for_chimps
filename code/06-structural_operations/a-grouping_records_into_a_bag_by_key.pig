IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Grouping Records into a Bag by Key
--

-- The GROUP BY operation is at the heart of every structural operation. It's a
-- one-liner in Pig to collect all the stadiums each team has played for:
--
park_teams_g = GROUP park_teams BY team_id;

-- DESCRIBE park_teams_g;
-- -- park_teams_g: {
-- --    group: chararray,
-- --    park_teams: {
-- --        ( park_id: chararray, team_id: chararray, year_id: long,
-- --          beg_date: chararray, end_date: chararray, n_games: long ) } }

-- This means it's pretty common to immediately project using a FOREACH, and we
-- can even put the `GROUP BY` statement inline:
--
team_pkyr_pairs = FOREACH (GROUP park_teams BY team_id) GENERATE
  group AS team_id, park_teams.(park_id,year_id);
-- -- (ALT,{(ALT01,1884)})
-- -- (ANA,{(ANA01,2001),(ANA01,2010),(ANA01,2002),...})

-- Notice the `park_teams.(park_id,year_id)` form, which gives us a bag of
-- (park_id,year_id) pairs. Using `park_teams.park_id, park_teams.year_id`
-- instead gives two bags, one with park_id tuples and one with year_id tuples:
--
team_pkyr_bags = FOREACH (GROUP park_teams BY team_id) GENERATE
  group AS team_id, park_teams.park_id, park_teams.year_id;
-- -- (ALT, {(ALT01)}, {(1884)})
-- -- (ANA, {(ANA01),(ANA01),(ANA01),...}, {(2001),(2010),(2002),...})

DESCRIBE team_pkyr_pairs;
-- -- team_parks: { team_id: chararray, { (park_id: chararray, year_id: long) } }

DESCRIBE team_pkyr_bags;
-- -- team_parks: { team_id: chararray, { (park_id: chararray) }, { (year_id: long) } }

-- You can group on multiple fields.  For each team and year, we can find the
-- park(s) that team called home:
--
team_yr_parks_g = GROUP park_teams BY (year_id, team_id);

-- The first field is still called 'group', but it's now a tuple.
DESCRIBE team_yr_parks_g;
--   team_yr_parks_g: {
--     group: (year_id: long,team_id: chararray),
--     park_teams: {(park_id: chararray, team_id: chararray, year_id: long, ...)}}

-- and so our `FOREACH` statement looks a bit different:
team_yr_parks = FOREACH(GROUP park_teams BY (year_id, team_id)) GENERATE
  group.team_id, park_teams.park_id;
--
=> LIMIT team_yr_parks 4; DUMP @;
--   (BS1,{(BOS01),(NYC01)})
--   (CH1,{(NYC01),(CHI01)})
--   (CL1,{(CIN01),(CLE01)})
--   (FW1,{(FOR01)})

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Counting Occurrences of a Key
--
team_n_parks = FOREACH (GROUP park_teams BY (team_id,year_id)) GENERATE
  group.team_id, COUNT_STAR(park_teams) AS n_parks;
vagabonds = FILTER team_n_parks BY n_parks >= 3;
DUMP vagabonds;
-- (CL4,7)
-- (CLE,5)
-- (WS3,4)
-- (CLE,3)
-- (DET,3)
-- ... (others)

