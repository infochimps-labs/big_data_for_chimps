IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
allstars    = load_allstars();

-- ***************************************************************************
--
-- === Selecting Records Having a Match in Another Table (semi-join)
--

--   -- Don't do this... produces duplicates!
-- bats_g    = JOIN allstar BY (player_id, year_id), bats BY (player_id, year_id);
-- bats_as   = FOREACH bats_g GENERATE bats::player_id .. bats::HR;


-- Project just the fields we need allstars_p = FOREACH allstars GENERATE
player_id, year_id;

-- Will not work: look for multiple duplicated rows in the 1959-1962 years
allstar_seasons_broken_j = JOIN
  bat_seasons BY (player_id, year_id) LEFT OUTER,
  allstars_p  BY (player_id, year_id);
allstar_seasons_broken   = FILTER allstar_seasons_broken_j
  BY allstars_p::player_id IS NOT NULL;

--
-- Instead, in this case you must use a COGROUP.
--

-- Players with no entry in the allstars_p table have an empty allstars_p bag
allstar_seasons_cg = COGROUP
  bat_seasons BY (player_id, year_id),
  allstars_p BY (player_id, year_id);

-- Select all cogrouped rows where there was an all-star record; Project the
-- batting table fields. One row in the batting table => One row in the result
--
allstar_seasons_cg = FOREACH
  (FILTER allstar_seasons_cg BY (COUNT_STAR(allstars_p) > 0L))
  GENERATE FLATTEN(bat_seasons);

-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(allstar_seasons_jn, 'allstar_seasons_jn');
STORE_TABLE(allstar_seasons_cg, 'allstar_seasons_cg');
