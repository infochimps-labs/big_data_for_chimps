IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

sig_seasons = load_sig_seasons();

-- ***************************************************************************
--
-- === Selecting Records Having the Top K Values in a Table
--


-- Find the top 20 seasons by OPS.  Pig is smart about eliminating records at
-- the map stage, dramatically decreasing the data size.

player_season_stats = FOREACH sig_seasons GENERATE
   player_id, name, games,
   hits/ab AS batting_avg,
   whatever AS slugging_avg,
   whatever AS offensive_pct
   ;
player_season_stats_ordered = ORDER player_season_stats BY (slugging_avg + offensive_pct) DESC;
STORE player_season_stats INTO '/tmp/baseball/player_season_stats';

-- A simple ORDER BY..LIMIT stanza may not be what you need, however. It will
-- always return K records exactly, even if there are ties for K'th place.


-- Making a leaderboard of records with say the top ten values for a field is
-- not as simple as saying `ORDER BY..LIMIT`, as there could be many records
-- tied for the final place on the list.
--
-- If you'd like to retain records tied with or above the Nth largest value, use
-- the windowed query functionality from Over.
-- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/Over.html
--
-- We limit within each group to the top `topk_window` (20) items, assuming
-- there are not 16 players tied for fourth in HR. We don't assume for too long
-- -- an `ASSERT` statement verifies there aren't so many records tied for 4th
-- place that it overflows the 20 highest records we retained for consideration.
--
%DEFAULT topk_window 20
%DEFAULT topk        4
DEFINE IOver                  org.apache.pig.piggybank.evaluation.Over('int');
ranked_HRs = FOREACH (GROUP bats BY year_id) {
  bats_HR = ORDER bats BY HR DESC;
  bats_N  = LIMIT bats_HR $topk_window; -- making a bet, asserted below
  ranked  = Stitch(bats_N, IOver(bats_N, 'rank', -1, -1, 15)); -- beginning to end, rank on the 16th field (HR)
  GENERATE
    group   AS year_id,
    ranked  AS ranked:{(player_id, year_id, team_id, lg_id, age, G, PA, AB, HBP, SH, BB, H, h1B, h2B, h3B, HR, R, RBI, OBP, SLG, rank_HR)}
    ;
};
-- verify there aren't so many records tied for $topk'th place that it overflows
-- the $topk_window number of highest records we retained for consideration
ASSERT ranked_HRs BY MAX(ranked.rank_HR) > $topk; --  'LIMIT was too strong; more than $topk_window players were tied for $topk th place';

top_season_HRs = FOREACH ranked_HRs {
  ranked_HRs = FILTER ranked BY rank_HR <= $topk;
  GENERATE ranked_HRs;
  };

STORE_TABLE('top_season_HRs', top_season_HRs);
