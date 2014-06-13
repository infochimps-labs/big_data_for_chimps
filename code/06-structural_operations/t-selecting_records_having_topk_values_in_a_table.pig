IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

sig_seasons = load_sig_seasons();

-- ***************************************************************************
--
-- === Selecting Records Having the Top K Values in a Table
--

-- Find the top 40 seasons by hits.  Pig is smart about eliminating records at
-- the map stage, dramatically decreasing the data size.

top_H_seasons = LIMIT (ORDER sig_seasons BY H DESC, player_id ASC) 40;
-- top_H_seasons = RANK top_H_seasons;

-- A simple ORDER BY..LIMIT stanza may not be what you need, however. It will
-- always return K records exactly, even if there are ties for K'th place.
-- (Strangely enough, that is the case for the number we've chosen.)

-- The standard SQL trick is to identify the key for the K'th element (here,
-- it's Jim Bottomley's 227 hits in 1925) and then filter for records matching
-- or exceeding it. Unless K is so large that the top-k starts to rival
-- available memory, we're better off doing it in-reducer using a nested
-- FOREACH, just like we 

-- 
-- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/Over.html[Piggybank's Over UDF]
-- allows us to 
--
-- We limit within each group to the top `topk_window` (60) items, assuming
-- there are not 16 players tied for fourth in H. We don't assume for too long
-- -- an `ASSERT` statement verifies there aren't so many records tied for 4th
-- place that it overflows the 20 highest records we retained for consideration.


%DEFAULT topk_window 60
%DEFAULT topk        40
DEFINE IOver                  org.apache.pig.piggybank.evaluation.Over('int');
ranked_Hs = FOREACH (GROUP bats BY year_id) {
  bats_H  = ORDER bats BY H DESC;
  bats_N  = LIMIT bats_H $topk_window; -- making a bet, asserted below
  ranked  = Stitch(bats_N, IOver(bats_N, 'rank', -1, -1, 15)); -- beginning to end, rank on the 16th field (H)
  GENERATE
    group   AS year_id,
    ranked  AS ranked:{(player_id, year_id, team_id, lg_id, age, G, PA, AB, HBP, SH, BB, H, h1B, h2B, h3B, H, R, RBI, OBP, SLG, rank_H)}
    ;
};
-- verify there aren't so many records tied for $topk'th place that it overflows
-- the $topk_window number of highest records we retained for consideration
ASSERT ranked_Hs BY MAX(ranked.rank_H) > $topk; --  'LIMIT was too strong; more than $topk_window players were tied for $topk th place';

top_season_Hs = FOREACH ranked_Hs {
  ranked_Hs = FILTER ranked BY rank_H <= $topk;
  GENERATE ranked_Hs;
  };

STORE_TABLE(top_H_seasons, 'top_H_seasons');
-- STORE_TABLE('top_season_Hs', top_season_Hs);
