IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bats_a = load_bat_seasons();
bats_b = load_bat_seasons();

bats_a = FOREACH bats_a GENERATE player_id;
bats_b = FOREACH bats_b GENERATE player_id;

a_xor_b = FILTER (COGROUP bats_a BY player_id, bats_b BY player_id)
  BY ((COUNT_STAR(bats_a) == 0L) OR (COUNT_STAR(bats_b) == 0L));

STORE_TABLE(a_xor_b, 'foo');
