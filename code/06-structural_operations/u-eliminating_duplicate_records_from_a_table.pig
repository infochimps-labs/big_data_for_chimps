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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Eliminating Duplicate Records from a Group
--

team_parkslist = FOREACH (GROUP park_teams BY team_id) {
  parks = DISTINCT park_teams.park_id;
  GENERATE group AS team_id, BagToString(parks, '|');
};

EXPLAIN team_parkslist;

-- -- CL1     CHI02|CIN01|CLE01
-- -- CL2     CLE02
-- -- CL3     CLE03|CLE09|GEA01|NEW03
-- -- CL4     CHI08|CLE03|CLE05|CLL01|DET01|IND06|PHI09|ROC02|ROC03|STL05

-- (omit from book) The output is a bit more meaningful if we add the team name
-- and park names to the list:
--
tm_pk_named_a = FOREACH (JOIN park_teams    BY team_id, teams BY team_id) GENERATE teams::team_id AS team_id, park_teams::park_id    AS park_id, teams::team_name AS team_name;
tm_pk_named   = FOREACH (JOIN tm_pk_named_a BY park_id, parks BY park_id) GENERATE team_id,                   tm_pk_named_a::park_id AS park_id, team_name,  park_name;
team_parksnamed = FOREACH (GROUP tm_pk_named BY team_id) {
  parks = DISTINCT tm_pk_named.(park_id, park_name);
  GENERATE group AS team_id, FLATTEN(FirstTupleFromBag(tm_pk_named.team_name, (''))), BagToString(parks, '|');
};


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Eliminating All But One Duplicate Based on a Key
--

DEFINE DistinctByYear datafu.pig.bags.DistinctBy('0');

pltmyrs = FOREACH bat_seasons GENERATE player_id, year_id, team_id;
player_teams = FOREACH (GROUP pltmyrs BY player_id) {
  pltmyrs_o = ORDER pltmyrs.(team_id, year_id) BY team_id; -- TODO does this use secondary sort, or cause a POSort?
  pltmyrs = DistinctByYear(pltmyrs);
  GENERATE player_id, BagToString(pltmyrs, '|');
};


STORE_TABLE(tm_pk_pairs,     'tm_pk_pairs');
STORE_TABLE(team_parkslist,  'team_parkslist');
STORE_TABLE(team_parksnamed, 'team_parksnamed');
