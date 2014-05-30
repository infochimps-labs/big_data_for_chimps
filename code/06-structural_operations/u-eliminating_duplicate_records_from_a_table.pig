IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

park_teams = load_park_teams();
parks      = load_parks();
teams       = load_teams();

-- ***************************************************************************
--
-- === Eliminating Duplicate Records from a Table
--

-- Every distinct (team, home ballpark) pair:

tm_pk_pairs_many = FOREACH park_teams GENERATE team_id, park_id;

tm_pk_pairs_dist = DISTINCT tm_pk_pairs_many;

-- -- ALT     ALT01
-- -- ANA     ANA01
-- -- ARI     PHO01
-- -- ATL     ATL01
-- -- ATL     ATL02

--
-- Equivalent SQL: `SELECT DISTINCT player_id, team_id from batting;`
--
-- This gives the same result as, but is less efficient than
--
tm_pk_pairs_dont = FOREACH (GROUP park_teams BY (team_id, park_id)) 
  GENERATE group.team_id, group.park_id;
-- -- ALT     ALT01
-- -- ANA     ANA01
-- -- ARI     PHO01
-- -- ATL     ATL01
-- -- ATL     ATL02

--
-- the DISTINCT operation is able to use a combiner - to eliminate duplicates at
-- the mapper before shipping them to the reducer. This is a big win when there
-- are frequent duplicates, especially if duplicates are likely to occur near
-- each other. For example, duplicates in web logs (from refreshes, callbacks,
-- etc) will be sparse globally, but found often in the same log file. In the
-- case of very few or very sparse duplicates, the combiner may impose a minor
-- penalty. You should still use DISTINCT, but set `pig.exec.nocombiner=true`.

STORE_TABLE(tm_pk_pairs_dist, 'tm_pk_pairs_dist');
STORE_TABLE(tm_pk_pairs_dont, 'tm_pk_pairs_dont');

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- === Eliminating Duplicate Records from a Group
--

-- Eliminating duplicates from a group just requires using a nested
-- foreach. Instead of finding every distinct (team, home ballpark) pair as we
-- just did, let's find the list of distinct home ballparks for each team:

team_parkslist = FOREACH (GROUP park_teams BY team_id) {
  parks = DISTINCT park_teams.park_id;
  GENERATE group AS team_id, BagToString(parks, '|');
};

EXPLAIN team_parkslist;

STORE_TABLE(team_parkslist, 'team_parkslist');

-- -- CL1     CHI02|CIN01|CLE01                                          
-- -- CL2     CLE02                                                      
-- -- CL3     CLE03|CLE09|GEA01|NEW03                                    
-- -- CL4     CHI08|CLE03|CLE05|CLL01|DET01|IND06|PHI09|ROC02|ROC03|STL05

-- Same deal, but slap the stadium names on there first:
--
-- tm_pk_named_a = FOREACH (JOIN park_teams    BY team_id, teams BY team_id) GENERATE teams::team_id AS team_id, park_teams::park_id AS park_id, teams::team_name AS team_name;
-- tm_pk_named   = FOREACH (JOIN tm_pk_named_a BY park_id, parks BY park_id) GENERATE team_id,                tm_pk_named_a::park_id AS park_id, team_name,  park_name;
-- team_parkslist = FOREACH (GROUP tm_pk_named BY team_id) {
--   parks = DISTINCT tm_pk_named.(park_id, park_name);
--   GENERATE group AS team_id, FLATTEN(FirstTupleFromBag(tm_pk_named.team_name, (''))), BagToString(parks, '|');
-- };
-- DUMP team_parkslist;
