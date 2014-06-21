IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
allstars    = load_allstars();

-- ***************************************************************************
--
-- === Selecting Only Records That Lack a Match in Another Table (anti-join)
--

-- Project just the fields we need
allstars_p  = FOREACH allstars GENERATE player_id, year_id;

-- An outer join of the two will leave both matches and non-matches.
scrub_seasons_jn = JOIN
  bat_seasons BY (player_id, year_id) LEFT OUTER,
  allstars_p  BY (player_id, year_id);

-- ...and the non-matches will have Nulls in all the allstars slots
scrub_seasons_jn_f = FILTER scrub_seasons_jn
  BY allstars_p::player_id IS NULL;

-- Once the matches have been eliminated, pick off the first table's fields.
scrub_seasons_jn   = FOREACH scrub_seasons_jn_f
  GENERATE bat_seasons::player_id..bat_seasons::RBI;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- An Alternative version: use a COGROUP
--

-- Players with no entry in the allstars_p table have an empty allstars_p bag
bats_ast_cg = COGROUP
  bat_seasons BY (player_id, year_id),
  allstars_p BY (player_id, year_id);

-- Select all cogrouped rows where there were no all-star records, and project
-- the batting table fields.
scrub_seasons_cg = FOREACH
  (FILTER bats_ast_cg BY (COUNT_STAR(allstars_p) == 0L))
  GENERATE FLATTEN(bat_seasons);

-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(scrub_seasons_jn, 'scrub_seasons_jn');
STORE_TABLE(scrub_seasons_cg, 'scrub_seasons_cg');
