IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- (work into the chapter introduction)
-- The overriding focus here is to equip you with the toolkit of analytic patterns.
-- The most meaningful way to introduce these patterns is to demonstrate their use in service of a question of real interest.
-- the main storyline of these chapters will be to find quantitative indicators of exceptional performance, and we'll pick that thread up repeatedly.
-- But where a pattern has no natural demonstration in service of that primary story, we non-sequitur into questions that could form a necessary piece of some other investigation:
-- "here's how you'd track changes in each team's roster over time", "is the stereotypical picture of the big brawny home-run hitter true." (TODO-qem please replace with what you found to be the most interesting one-offs (ie side-roads we didn't explore)).
-- And at several points, immediately on peeking down a side road the data comes forth with a story of its own, and so there are also a few brief side trips to follow such a tale.
-- But as we revisit the player-performance exploration, you should recognize not just a way for fantasy baseball players to get an edge, but strategies for quantifying the behavior of any sort of outlier. Here, it's baseball players, but similar questions will apply when examining agents posing security threats, factors causing manufacturing defects, cell strains with a significantly positive response, and many other topics of importance.
--
-- Although
-- in some cases, it's not wo



-- ***************************************************************************
--
-- === Grouping Records into a Bag by Key
--

-- The GROUP BY operation is at the heart of every structural operation. It's a
-- one-liner in Pig to collect all the stadiums each team has played for:
--
park_tm_yr_g = GROUP park_tm_yr BY team_id;

-- The result of a group is always a field called 'group', having the schema of
-- the key (atom) or keys (tuple); and then one field per grouped table, each
-- named for the table it came from. Notice that the name we used to refer to
-- the _table_ is now also the name for a _field_. This will confuse you at
-- first, but soon become natural. Until then, use `DESCRIBE` liberally.
--
-- DESCRIBE park_tm_yr_g;
-- -- park_tm_yr_g: {
-- --    group: chararray,
-- --    park_tm_yr: {
-- --        ( park_id: chararray, team_id: chararray, year_id: long,
-- --          beg_date: chararray, end_date: chararray, n_games: long ) } }

-- Notice that the _full record_ is kept, even including the keys:
--
-- => LIMIT park_tm_yr_g 2 ; DUMP @;
-- (ALT,{(ALT01,ALT,1884,1884-04-30,1884-05-31,18)})
-- (ANA,{(ANA01,ANA,2001,2001-04-10,2001-10-07,81),(ANA01,ANA,2010,2010-04-05,2010-09-29,81),...})

-- Because of this redundancy, it's pretty common to immediately project using a
-- FOREACH, .
--
-- This means it's pretty common to immediately project using a FOREACH, and we
-- can even put the `GROUP BY` statement inline:

-- We want to keep the team_id
team_py_pairs = FOREACH (GROUP park_tm_yr BY team_id) GENERATE
  group AS team_id, park_tm_yr.(park_id,year_id);
-- -- (ALT,{(ALT01,1884)})
-- -- (ANA,{(ANA01,2001),(ANA01,2010),(ANA01,2002),...})

-- Notice the `park_tm_yr.(park_id,year_id)` form, which gives us a bag of
-- (park_id,year_id) pairs. Using `park_tm_yr.park_id, park_tm_yr.year_id`
-- instead gives two bags, one with park_id tuples and one with year_id tuples:
team_py_bags = FOREACH (GROUP park_tm_yr BY team_id) GENERATE
  group AS team_id, park_tm_yr.park_id, park_tm_yr.year_id;

-- Notice the `park_tm_yr.(park_id,year_id)` form, which gives us a bag of
-- (park_id,year_id) pairs. Using `park_tm_yr.park_id, park_tm_yr.year_id`
-- instead gives two bags, one with park_id tuples and one with year_id tuples:

------
team_py_bags = FOREACH (GROUP park_tm_yr BY team_id)
  GENERATE group AS team_id, park_tm_yr.park_id, park_tm_yr.year_id;
-- -- (ALT, {(ALT01)}, {(1884)})
-- -- (ANA, {(ANA01),(ANA01),(ANA01),...}, {(2001),(2010),(2002),...})

DESCRIBE team_py_pairs;
-- -- team_parks: { team_id: chararray, { (park_id: chararray, year_id: long) } }

DESCRIBE team_py_bags;
-- -- team_parks: { team_id: chararray, { (park_id: chararray) }, { (year_id: long) } }

-- You can group on multiple fields.  For each park and team, find all the years
-- that the park hosted that team:

-- (Notice the which you can do cleanly with an inline GROUP BY statement
-- QEM: reword

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
-- -- park_team_g: {
-- --   group: (park_id: chararray, team_id: chararray),
-- --   park_tm_yr: { (park_id: chararray, team_id: chararray, year_id: long, ...) } }

-- ====


-- The first field is still called 'group', but it's now a tuple, and so our `FOREACH` statement looks a bit different:

-- And so we have to dereference into group:
park_team_occupied = FOREACH(GROUP park_tm_yr BY (park_id, team_id)) GENERATE
  group.park_id, group.team_id, park_tm_yr.year_id;
--
-- => LIMIT park_team_occupied 3 ; DUMP @;
-- -- (ALB01,TRN,{(1882),(1880),(1881)})
-- -- (ALT01,ALT,{(1884)})
-- -- (ANA01,ANA,{(2009),(2008),(1997)...})

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== FOREACH with GROUP BY lets you summarize and
--
-- Operations that summarize the grouped value: This finds all teams that called
-- more than one stadium "home" during a year:
--
-- The typical reason to do a group is to operate on it, and that's how we'll
-- spend much of this chapter. For example, sometimes a team has more than one
-- "home" stadium in a season, typically due to stadium repairs or late-season
-- makeups for cancelled games; for publicity MLB has opened the season with a
-- series in Japan or Mexico a few times.
--
-- team_n_parks = FOREACH (GROUP park_tm_yr BY (team_id,year_id)) GENERATE
--   group.team_id,
--   group.year_id,
--   COUNT_STAR(park_tm_yr) AS n_parks;
-- vagabonds = FILTER team_n_parks BY n_parks > 1;
--
-- => LIMIT (ORDER vagabonds BY n_parks DESC) 4; DUMP @;
-- -- (CL4,1898,7)
-- -- (CLE,1902,5)
-- -- (WS3,1871,4)
-- -- (BSN,1894,3)
-- -- ...
--
-- Always, always look through the data and seek 'second stories'. In this case
-- you'll notice that the 1898 Cleveland Spiders used seven(!) stadiums as home
-- field.
--
-- === How a group works
--
-- mapper(array_fields_of: ParkTeamYear) do |park_id, team_id, year_id, beg_date, end_date, n_games|
--  yield [team_id, year_id]
-- end
--
-- # In effect, what is happening in Java:
-- reducer do |(team_id, year_id), stream|
--   n_parks = 0
--   stream.each do |*_|
--     n_parks += 1
--   end
--   yield [team_id, year_id, n_parks] if n_parks > 1
-- end
--
-- # (ln actual practice, the ruby version would call stream.size rather than iterating:
-- #  n_parks = stream.size ; yield [team_id, year_id, n_parks] if n_parks > 1

