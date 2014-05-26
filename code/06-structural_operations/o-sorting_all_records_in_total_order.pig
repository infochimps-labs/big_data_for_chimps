IMPORT 'common_macros.pig';
%DEFAULT rawd    '/data/rawd';
%DEFAULT out_dir '/data/out/baseball';

SET default_parallel 3;

bats = load_bat_seasons();
bats = FILTER bats BY (year_id >= 2000);

-- Sort the seasons table by OPS


-- Find the top 20 seasons by OPS.  Pig is smart about eliminating records at
-- the map stage, dramatically decreasing the data size.



-- Use ORDER BY within a nested FOREACH to sort within a group. Here, we select
-- the top ten players by OPS for each season.  The first request to sort a
-- group does not require extra operations -- Pig simply specifies those fields
-- as secondary sort keys.

-- -- Making a leaderboard of records with say the top ten values for a field is
-- -- not as simple as saying `ORDER BY..LIMIT`, as there could be many records
-- -- tied for the final place on the list.
-- --
-- -- If you'd like to retain records tied with or above the Nth largest value, use
-- -- the windowed query functionality from Over.
-- -- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/Over.html
-- --
-- -- We limit within each group to the top `topk_window` (20) items, assuming
-- -- there are not 16 players tied for fourth in HR. We don't assume for too long
-- -- -- an `ASSERT` statement verifies there aren't so many records tied for 4th
-- -- place that it overflows the 20 highest records we retained for consideration.
-- --
-- %DEFAULT topk_window 20
-- %DEFAULT topk        4
-- DEFINE IOver                  org.apache.pig.piggybank.evaluation.Over('int');
-- ranked_HRs = FOREACH (GROUP bats BY year_id) {
--   bats_HR = ORDER bats BY HR DESC;
--   bats_N  = LIMIT bats_HR $topk_window; -- making a bet, asserted below
--   ranked  = Stitch(bats_N, IOver(bats_N, 'rank', -1, -1, 15)); -- beginning to end, rank on the 16th field (HR)
--   GENERATE
--     group   AS year_id,
--     ranked  AS ranked:{(player_id, year_id, team_id, lg_id, age, G, PA, AB, HBP, SH, BB, H, h1B, h2B, h3B, HR, R, RBI, OBP, SLG, rank_HR)}
--     ;
-- };
-- -- verify there aren't so many records tied for $topk'th place that it overflows
-- -- the $topk_window number of highest records we retained for consideration
-- ASSERT ranked_HRs BY MAX(ranked.rank_HR) > $topk; --  'LIMIT was too strong; more than $topk_window players were tied for $topk th place';

-- top_season_HRs = FOREACH ranked_HRs {
--   ranked_HRs = FILTER ranked BY rank_HR <= $topk;
--   GENERATE ranked_HRs;
--   };

-- STORE_TABLE('top_season_HRs', top_season_HRs);

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
