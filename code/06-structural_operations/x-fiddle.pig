IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

-- bats_a = load_bat_seasons();
-- bats_b = load_bat_seasons();
-- --
-- -- bats_a = FOREACH bats_a GENERATE player_id;
-- -- bats_b = FOREACH bats_b GENERATE player_id;
-- --
-- -- a_xor_b = FILTER (COGROUP bats_a BY player_id, bats_b BY player_id)
-- --   BY ((COUNT_STAR(bats_a) == 0L) OR (COUNT_STAR(bats_b) == 0L));
-- --
-- -- STORE_TABLE(a_xor_b, 'foo');
-- 
-- 
-- -- a = load '/tmp/empty' AS (val:int); -- load an empty file
-- -- -- neither of the statements below actually ever get executed
-- -- b = group a all;
-- -- c = foreach b generate COUNT_STAR(a), COUNT(a), SUM(a.val);
-- --
-- -- STORE_TABLE(c,'bob');
-- --
-- -- empty = FILTER bats_a BY 1 == 2;
-- -- empty_g = GROUP empty ALL;
-- -- empty_stats = FOREACH empty_g GENERATE COUNT(empty);
-- --
-- -- STORE_TABLE(empty_stats, 'empty_stats');
-- 
-- 
-- empty_2 = FILTER bats_a BY 1 == 2;
-- empty_2_g = GROUP empty_2 BY 1;
-- empty_stats = FOREACH empty_2_g GENERATE COUNT(empty_2);
-- 
-- STORE_TABLE(empty_stats, 'empty_stats');


-- events = LOAD '$data_dir/sports/baseball/events_lite.tsv' USING PigStorage('~') AS (line:chararray);
-- ruthy = FILTER events BY line MATCHES '.*ruth.*';
-- STORE ruthy INTO '/tmp/ruthy';




IMPORT 'summarizer_bot_9000.pig';
SET pig.auto.local.enabled true
  ;
events = load_events();
events_info   = summarize_numeric(events, 'home_score', 'ALL');

EXPLAIN events_info;
STORE_TABLE(events_info, 'events_info');

