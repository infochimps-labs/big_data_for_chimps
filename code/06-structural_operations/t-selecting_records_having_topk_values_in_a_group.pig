IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Selecting Records Having the Top K Values in a Group (discarding ties)
--

-- Let's find the top ten home-run hitters for each season
--

%DEFAULT k_leaders 10
;

%DEFAULT topk_window 60
%DEFAULT topk        40
DEFINE IOver                  org.apache.pig.piggybank.evaluation.Over('int');


H_seasons = FOREACH bat_seasons GENERATE
  H, year_id, player_id;
H_seasons = FILTER H_seasons BY year_id >= 2000;

top_H_season_c = FOREACH (GROUP H_seasons BY year_id) {
  candidates = TOP(25, 0, H_seasons.(H, player_id));
  GENERATE group AS year_id, candidates AS candidates;
};

top_H_season_r = FOREACH top_H_season_c {
  candidates_o = ORDER candidates BY H DESC;
  ranked = Stitch(IOver(candidates_o, 'rank', -1, 0, 0), candidates_o); -- from first (-1) to last (-1), rank on H (0th field)
  is_ok = AssertUDF((MAX(ranked.result) > 10 ? 1 : 0),
    'All candidates for topk were accepted, so we cannot be sure that all candidates were found');
  GENERATE year_id, ranked AS candidates:bag{t:(rk:int, H:int, player_id:chararray)}, is_ok;
};

top_H_season = FOREACH top_H_season_r {
  topk = FILTER candidates BY rk <= 10;
  topk_str = FOREACH topk GENERATE SPRINTF('%2d %3d %-9s', rk, H, player_id) AS str;
  GENERATE year_id, MIN(topk.H), MIN(candidates.H), BagToString(topk_str, ' | ');
};

-- top_H_season_groupie = FOREACH (GROUP H_seasons BY year_id) {
--   candidates = TOP(25, 0, H_seasons.(H, player_id));
--   topk       = TOP(10, 0, H_seasons.H);
--   GENERATE
--     group AS year_id,
--     MIN(topk) AS topk_threshold,
--     FLATTEN(candidates) AS (H:int, player_id:chararray);
-- };
-- top_H_season_groupie = GROUP (FILTER top_H_season_groupie BY H >= topk_threshold) BY year_id;

DESCRIBE top_H_season_c;
DESCRIBE top_H_season_r;
DESCRIBE top_H_season;

DUMP     top_H_season;
-- DUMP     top_H_season_groupie;
-- STORE_TABLE(top_H_season, 'top_H_season');
-- STORE_TABLE(t2, 't2');


-- DEFINE MostHits org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');  
-- top_H_season = FOREACH (GROUP H_seasons BY year_id) {
--   top_k     = TOP(10, 0, H_seasons);
--   top_1     = MostHits(H_seasons);
--   top_1_bag = TOP(1,  0, H_seasons);
--   GENERATE
--     group                 AS year_id,
--     MAX(top_k.H)         AS max_H,
--     -- FLATTEN(top_1.H)      AS max_H_2,
--     -- top_1_bag.H           AS max_H_3,
--     -- top_1                 AS top_1,
--     -- FLATTEN(top_1_bag)    AS (H:int, year_id:int, player_id:chararray),
--     -- top_1_bag             AS top_1_bag:bag{t:(H:int, year_id:int, player_id:chararray)},
--     -- top_1_bag.H AS tH, -- :bag{t:(t1H:int)},
--     top_k.(player_id, H) AS top_k;
-- };
-- 
-- top_H_season_2 = FOREACH top_H_season {
--   top_k_o = FILTER top_k BY (H >= max_H);
--   -- firsties = CROSS top_k, tH;
--   -- top_k_o = ORDER top_k BY H DESC;
--   GENERATE year_id, max_H, top_k_o;
-- };
-- 
-- DESCRIBE top_H_season;
-- DESCRIBE top_H_season_2;
-- 
-- -- DUMP top_H_season;
-- DUMP top_H_season_2;

-- HR_leaders = FOREACH HR_leaders {
--   top_k_o = ORDER top_k BY HR DESC;
--   GENERATE
--
--   top_k  =
--   GENERATE top_k_o;
--   };
--
--   top_k_o = ORDER top_k BY HR DESC;

--
-- STORE_TABLE(HR_leaders, 'HR_leaders');

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Selecting Attribute wdw
-- -- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/ExtremalTupleByNthField.html
-- DEFINE BiggestInBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');
--
-- pl_best = FOREACH (GROUP bat_seasons BY player_id) GENERATE
--   group AS player_id,
--   BiggestInBag(bat_seasons.(H,   year_id, team_id)),
--   BiggestInBag(bat_seasons.(HR,  year_id, team_id)),
--   BiggestInBag(bat_seasons.(OBP, year_id, team_id)),
--   BiggestInBag(bat_seasons.(SLG, year_id, team_id)),
--   BiggestInBag(bat_seasons.(OPS, year_id, team_id))
--   ;
--
-- DESCRIBE pl_best;
--
-- rmf                 $out_dir/pl_best;
-- STORE pl_best INTO '$out_dir/pl_best';
