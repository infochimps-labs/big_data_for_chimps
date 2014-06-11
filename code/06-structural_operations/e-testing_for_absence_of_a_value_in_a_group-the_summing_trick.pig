IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Testing for Absence of a Value Within a Group
--

-- We can answer to the question "what players have ever played for the Red Sox"
-- by selecting seasons with team id `BOS`, then eliminating duplicates:

-- Players who were on the Red Sox at some time
onetime_sox_ids = FOREACH (FILTER bat_seasons BY (team_id == 'BOS')) GENERATE player_id;
onetime_sox     = DISTINCT onetime_sox_ids;

-- However, filtering for `team_id != 'BOS'` does *not* work to select players
-- who were _never_ on the Red Sox. (It finds players who played at least one
-- season for another team.) The elegant way to do this involves the 'summing
-- trick', a device that will reoccur several times in this chapter.

player_soxness   = FOREACH bat_seasons GENERATE
  player_id, (team_id == 'BOS' ? 1 : 0) AS is_soxy;

player_soxness_g = FILTER (GROUP player_soxness BY player_id)
  BY SUM(is_soxy) == 0L;

never_sox = FOREACH player_soxness_g GENERATE group AS player_id;

-- The summing trick involves projecting a new field whose value is based on
-- whether it's in the desired set, then forming the group we want to
-- summarize. For the irrelevant records, we assign a value that is ignored by
-- the aggregate function (typically zero or NULL), and so even though we
-- operate on the group as a whole, only the relevant records contribute.
--
-- Another example will help you see what we mean -- next, we'll use one GROUP
-- operation to summarize multiple subsets of a table at the same time.
