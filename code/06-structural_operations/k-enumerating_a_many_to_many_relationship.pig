IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

SET pig.auto.local.enabled true;

bat_seasons = load_bat_seasons();
park_teams  = load_park_teams();

-- ***************************************************************************
--
-- === Enumerating a Many-to-Many Relationship
--
-- In the previous examples there's been a direct pairing of each line in the
-- main table with the unique line from the other table that decorates it.
-- Therefore, there output had exactly the same number of rows as the larger
-- input table. When there are multiple records per key, however, the the output
-- will have one row for each _pairing_ of records from each table. A key with
-- two records from the left table and 3 records from the right table yields six
-- output records.

player_team_years = FOREACH bat_seasons GENERATE year_id, team_id, player_id;
park_team_years   = FOREACH park_teams  GENERATE year_id, team_id, park_id;

player_stadia = FOREACH (JOIN
  player_team_years BY (year_id, team_id),
  park_team_years   BY (year_id, team_id)
  ) GENERATE
  player_team_years::year_id AS year_id, player_team_years::team_id AS team_id,
  player_id,  park_id;

--
-- By consulting the Jobtracker counters (map input records vs reduce output
-- records) or by explicitly using Pig to count records, you'll see that the
-- 77939 batting_seasons became 80565 home stadium-player pairings. The
-- cross-product behavior didn't cause a big explosion in counts -- as opposed
-- to our next example, which will generate much more data.
--
bat_seasons_info   = FOREACH (GROUP bat_seasons   ALL) GENERATE 'batting seasons count', COUNT_STAR(bat_seasons)   AS ct;
player_stadia_info = FOREACH (GROUP player_stadia ALL) GENERATE 'player_stadia count',   COUNT_STAR(player_stadia) AS ct;

STORE_TABLE(player_stadia, 'player_stadia');
DUMP bat_seasons_info;
DUMP player_stadia_info;


