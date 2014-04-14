IMPORT 'common_macros.pig'; %DEFAULT out_dir '/data/out/baseball'; 
bats    = load_bat_seasons();
allstar = load_allstar();

-- Project just what we need
ast       = FOREACH allstar GENERATE player_id, year_id;

-- Cogroup; players without an entry in the ast table will have an empty ast bag
bats_g    = COGROUP ast     BY (player_id, year_id), bats BY (player_id, year_id);
bats_f    = FILTER  bats_g  BY NOT IsEmpty(ast);

-- Project only the batting table fields. One row in the batting table => One row in the result
bats_as   = FOREACH bats_f  GENERATE FLATTEN(bats);

rmf                 $out_dir/all_star_seasons;
STORE bats_as INTO '$out_dir/all_star_seasons';

-- --
-- -- !!! Don't use a join for this !!!
-- --
-- -- From 1959-1962 there were _two_ all-star games, and so the allstar table has multiple entries;
-- -- this means that players will appear twice in the results
-- --
-- 
-- -- This will eliminate the non-allstars... but also produce duplicates!
-- bats_g    = JOIN ast BY (player_id, year_id), bats BY (player_id, year_id);
-- bats_as   = FOREACH bats_g GENERATE bats::player_id .. bats::HR;
-- 
-- rmf                 $out_dir/all_star_seasons-bad;
-- STORE bats_as INTO '$out_dir/all_star_seasons-bad';

