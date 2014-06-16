IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

park_teams = load_park_teams();
parks      = load_parks();
teams      = load_teams();

--
-- === Finding Duplicate and Unique Records
--

-- ***************************************************************************
--
-- ==== Eliminating Duplicate Records from a Table
--

-- The park_teams table has a row for every season. To find every distinct pair
-- of team and home ballpark, use the DISTINCT operator. This is equivalent to
-- the SQL statement `SELECT DISTINCT player_id, team_id from batting;`.

tm_pk_pairs_many = FOREACH park_teams GENERATE team_id, park_id;
tm_pk_pairs = DISTINCT tm_pk_pairs_many;

-- -- ALT     ALT01
-- -- ANA     ANA01
-- -- ARI     PHO01
-- -- ATL     ATL01
-- -- ATL     ATL02

-- Don't fall in the trap of using a GROUP statement to find distinct values:
--
dont_do_this = FOREACH (GROUP tm_pk_pairs_many BY (team_id, park_id)) GENERATE
  group.team_id, group.park_id;
--
-- the DISTINCT operation is able to use a combiner, eliminating duplicates at
-- the mapper before shipping them to the reducer. This is a big win when there
-- are frequent duplicates, especially if duplicates are likely to occur near
-- each other. For example, duplicates in web logs (from refreshes, callbacks,
-- etc) will be sparse globally, but found often in the same log file.
--
-- The combiner may impose a minor penalty when there are very few or very
-- sparse duplicates. In that case, you should still use DISTINCT, but disable
-- combiners with the `pig.exec.nocombiner=true` setting.




-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Eliminating Duplicate Records from a Group
--

-- Eliminate duplicates from a group with the DISTINCT operator inside a nested
-- foreach. Instead of finding every distinct (team, home ballpark) pair as we
-- just did, let's find the list of distinct home ballparks for each team:

team_parkslist = FOREACH (GROUP park_teams BY team_id) {
  parks = DISTINCT park_teams.park_id;
  GENERATE group AS team_id, BagToString(parks, '|');
};

EXPLAIN team_parkslist;

-- -- CL1     CHI02|CIN01|CLE01
-- -- CL2     CLE02
-- -- CL3     CLE03|CLE09|GEA01|NEW03
-- -- CL4     CHI08|CLE03|CLE05|CLL01|DET01|IND06|PHI09|ROC02|ROC03|STL05


-- SELECT team_id, GROUP_CONCAT(DISTINCT park_id ORDER BY park_id) AS park_ids
--   FROM park_team_years
--   GROUP BY team_id
--   ORDER BY team_id, park_id DESC
--   ;


-- (omit from book) The output is a bit more meaningful if we add the team name
-- and park names to the list:
--
tm_pk_named_a = FOREACH (JOIN park_teams    BY team_id, teams BY team_id) GENERATE teams::team_id AS team_id, park_teams::park_id    AS park_id, teams::team_name AS team_name;
tm_pk_named   = FOREACH (JOIN tm_pk_named_a BY park_id, parks BY park_id) GENERATE team_id,                   tm_pk_named_a::park_id AS park_id, team_name,  park_name;
team_parksnamed = FOREACH (GROUP tm_pk_named BY team_id) {
  parks = DISTINCT tm_pk_named.(park_id, park_name);
  GENERATE group AS team_id, FLATTEN(FirstTupleFromBag(tm_pk_named.team_name, (''))), BagToString(parks, '|');
};

STORE_TABLE(tm_pk_pairs,     'tm_pk_pairs');
STORE_TABLE(team_parkslist,  'team_parkslist');
STORE_TABLE(team_parksnamed, 'team_parksnamed');
