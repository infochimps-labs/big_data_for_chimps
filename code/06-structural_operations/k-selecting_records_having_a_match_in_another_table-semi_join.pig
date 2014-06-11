IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons    = load_bat_seasons();
allstars = load_allstars();

-- ***************************************************************************
--
-- === Selecting Records Having a Match in Another Table (semi-join)
--

--
-- !!! Don't use a join for this !!!
--
-- From 1959-1962 there were _two_ all-star games, and so the allstar table has multiple entries;
-- this means that players will appear twice in the results
--

-- Project just the fields we need
allstars_py   = FOREACH allstars GENERATE player_id, year_id;

-- An outer join of the two will leave both matches and non-matches
seasons_allstars_jn = JOIN
  bat_seasons BY (player_id, year_id) LEFT OUTER,
  allstars_py BY (player_id, year_id);

-- And we can filter-then-project just as for the anti-join case
bat_seasons_ast_jn  = FOREACH
  (FILTER seasons_allstars_jn BY allstars_py::player_id IS NOT NULL)
  GENERATE bat_seasons::player_id..bat_seasons::RBI;

-- but also
-- produce multiple rows where there was more than one all-star game in a year

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Instead, in this case you must use a COGROUP
--

-- Players with no entry in the allstars_py table have an empty allstars_py bag
bats_ast_cg = COGROUP
  bat_seasons BY (player_id, year_id),
  allstars_py BY (player_id, year_id);

-- Select all cogrouped rows where there was an all-star record
-- Project the batting table fields.
--
-- One row in the batting table => One row in the result
bat_seasons_ast_cg = FOREACH
  (FILTER bats_ast_cg BY (COUNT_STAR(allstars_py) > 0L))
  GENERATE FLATTEN(bat_seasons);


-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(bat_seasons_ast_jn, 'bat_seasons_ast_jn');
STORE_TABLE(bat_seasons_ast_cg, 'bat_seasons_ast_cg');
