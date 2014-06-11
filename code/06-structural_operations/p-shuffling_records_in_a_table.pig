IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

vals = LOAD 'us_city_pops.tsv' USING PigStorage('\t', '-tagMetadata')
  AS (metadata:map[], city:chararray, state:chararray, pop:int);

-- === Shuffle all Records in a Table
-- ==== Shuffle all Records in a Table Consistently

-- Use a hash with good mixing properties to shuffle. MD5 is OK but murmur3 from
-- DATAFU-47 would be even better.
DEFINE HashVal datafu.pig.hash.Hasher('murmur3-32');

vals_rked     = RANK vals;

DESCRIBE vals_rked;

vals_ided = FOREACH vals_rked GENERATE
  rank_vals,
  metadata,
  metadata#'pathname'  AS pathname:chararray,
  metadata#'sp_index'  AS sp_index:int,
  metadata#'sp_offset' AS sp_offset:long,
  metadata#'sp_bytes'  AS sp_bytes:long,
  city, state, pop;

vals_ided = FOREACH vals_ided GENERATE
  HashVal(pathname) AS pathhash, metadata,
  sp_index, sp_offset, sp_bytes, city, state, pop;

STORE_TABLE('vals_ided',  vals_ided);
-- USING MultiStorage

-- vals_wtag = FOREACH vals_rked {
--   line_info   = CONCAT((chararray)split_info, '#', (chararray)rank_vals);
--   GENERATE HashVal((chararray)line_info) AS rand_id, city, state, pop, FLATTEN(split_attrs) AS (sp_path, sp_idx, sp_offs, sp_size);
--   };
-- vals_shuffled = FOREACH (ORDER vals_wtag BY rand_id) GENERATE *;
-- STORE vals_shuffled INTO '/data/out/vals_shuffled';


DEFINE Hasher datafu.pig.hash.MD5('hex');
-- DEFINE Hasher org.apache.pig.piggybank.evaluation.string.HashFNV();

-- evs = LOAD '/data/rawd/sports/baseball/events_lite-smallblks.tsv' USING PigStorage('\t', '-tagSplit') AS (
--     split_info:chararray, game_id:chararray, event_seq:int, year_id:int, game_date:chararray, game_seq:int, away_team_id:chararray, home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int, away_score:int, home_score:int, event_desc:chararray, event_cd:int, hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int, run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int, bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray, bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
--     );
-- evs_numd = RANK evs;
-- evs_ided = FOREACH evs_numd {
--   line_info = CONCAT((chararray)split_info, '#', (chararray)rank_evs);
--   GENERATE MurmurH32(line_info) AS rand_id, *; -- game_id..run3_id;
--   };
-- DESCRIBE evs_ided;
-- evs_shuffled = FOREACH (ORDER evs_ided BY rand_id) GENERATE $1..;
-- STORE_TABLE('evs_shuffled', evs_shuffled);

-- -- -smallblks
-- vals = LOAD '/data/rawd/sports/baseball/events_lite.tsv' USING PigStorage('\t', '-tagSplit') AS (
--     split_info:chararray, game_id:chararray, event_seq:int, year_id:int, game_date:chararray, game_seq:int, away_team_id:chararray, home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int, away_score:int, home_score:int, event_desc:chararray, event_cd:int, hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int, run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int, bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray, bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
--     );
-- vals = FOREACH vals GENERATE MurmurH32((chararray)split_info) AS split_info:chararray, $1..;

vals = LOAD '$rawd/geo/census/us_city_pops.tsv' USING PigStorage('\t', '-tagSplit')
  AS (split_info:chararray, city:chararray, state:chararray, pop:int);

vals_rk = RANK vals;
vals_ided = FOREACH vals_rk {
  line_info = CONCAT((chararray)split_info, '#', (chararray)rank_vals);
  GENERATE Hasher((chararray)line_info) AS rand_id, *; -- $2..;
  };
DESCRIBE vals_ided;
DUMP     vals_ided;

vals_shuffled = FOREACH (ORDER vals_ided BY rand_id) GENERATE *; -- $1..;
DESCRIBE vals_shuffled;

STORE_TABLE('vals_shuffled', vals_shuffled);


-- vals_shuffled = LOAD '/data/rawd/sports/baseball/events_lite.tsv' AS (
--     sh_key:chararray, line_id:int, spl_key:chararray, game_id:chararray, event_seq:int, year_id:int, game_date:chararray, game_seq:int, away_team_id:chararray, home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int, away_score:int, home_score:int, event_desc:chararray, event_cd:int, hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int, run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int, bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray, bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
--     );
-- vals_foo = ORDER vals_shuffled BY sh_key;
-- STORE_TABLE('vals_foo', vals_shuffled);

-- numbered = RANK cities;
-- DESCRIBE numbered;
-- ided = FOREACH numbered {
--   line_info = CONCAT((chararray)split_info, '#', (chararray)rank_cities);
--   GENERATE
--     *;
--   };
-- DESCRIBE ided;
-- STORE_TABLE('cities_with_ids', ided);
--
-- sampled_lines = FILTER(FOREACH ided GENERATE MD5(id_md5) AS digest, id_md5) BY (STARTSWITH(digest, 'b'));
-- STORE_TABLE('sampled_lines', sampled_lines);
--
-- data_in = LOAD 'input' as (val:chararray);
--
-- data_out = FOREACH data_in GENERATE
--   DefaultH(val),   GoodH(val),       BetterH(val),
--   MurmurH32(val),  MurmurH32A(val),  MurmurH32B(val),
--   MurmurH128(val), MurmurH128A(val), MurmurH128B(val),
--   SHA1H(val),      SHA256H(val),    SHA512H(val),
--   MD5H(val)
-- ;
--
-- STORE_TABLE('data_out', data_out);
