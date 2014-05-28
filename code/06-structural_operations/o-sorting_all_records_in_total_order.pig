IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
SET default_parallel 3;

bats = load_bat_seasons();
bats = FILTER bats BY (year_id >= 2000);


-- ***************************************************************************
--
-- === Sorting All Records in Total Order

-- Look at the jobtracker


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Cannot Use an Expression in an ORDER BY statement
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Sorting by Multiple Fields
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Floating Values to the Head or Tail of the Sort Order
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Case-insensitive Sorting
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Dealing with Nulls When Sorting
--

-- Sort the seasons table by OPS


-- Find the top 20 seasons by OPS.  Pig is smart about eliminating records at
-- the map stage, dramatically decreasing the data size.

-- player_seasons = LOAD `player_seasons` AS (...);
-- qual_player_seasons = FILTER player_years BY plapp > what it should be;
-- player_season_stats = FOREACH qual_player_seasons GENERATE
--    player_id, name, games,
--    hits/ab AS batting_avg,
--    whatever AS slugging_avg,
--    whatever AS offensive_pct
--    ;
-- player_season_stats_ordered = ORDER player_season_stats BY (slugging_avg + offensive_pct) DESC;
-- STORE player_season_stats INTO '/tmp/baseball/player_season_stats';

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
