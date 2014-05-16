IMPORT 'common_macros.pig';
%DEFAULT rawd    '/data/rawd';
%DEFAULT out_dir '/data/out/baseball';

bats = load_bat_seasons();
bats = FILTER bats BY (year_id >= 2000);


-- Sort the seasons table by OPS


-- Find the top 20 seasons by OPS.  Pig is smart about eliminating records at
-- the map stage, dramatically decreasing the data size.




-- Use ORDER BY within a nested FOREACH to sort within a group. Here, we select
-- the top ten players by OPS for each season.  The first request to sort a
-- group does not require extra operations -- Pig simply specifies those fields
-- as secondary sort keys.



-- To select the records having the highest value for an expression, it does not
-- work to use MAX (that gives the value but not the records) and it does not
-- work to use ORDER BY .. LIMIT 1 (there might be more than one record).
-- Instead, use

DEFINE LongOver org.apache.pig.piggybank.evaluation.Over('int');

%DEFAULT topk_window 20
%DEFAULT topk        4
;

-- If you'd like to retain records tied with or above the Nth largest value, use
-- the windowed query functionality from Over.
-- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/Over.html
--
top_HRs = FOREACH (GROUP bats BY year_id) {
  bats_HR = ORDER bats BY HR DESC;
  bats_N  = LIMIT bats_HR $topk_window; -- making a bet, asserted below
  ranked  = Stitch(bats_N, LongOver(bats_N, 'rank', -1, -1, 15)); -- HR is the 16th field
  GENERATE
    group AS year_id,
    ranked  AS ranked:{(player_id, year_id, team_id, lg_id, age, G, PA, AB, HBP, SH, BB, H, h1B, h2B, h3B, HR, R, RBI, OBP, SLG, rank_HR)}
    ;
};
DESCRIBE top_HRs;

DESCRIBE bats;

ASSERT top_HRs BY MAX(ranked.rank_HR) > $topk; --  'LIMIT was too strong; more than $topk_window players were tied for $topk th place';

top_season_HRs = FOREACH top_HRs {
  top_HRs = FILTER ranked BY rank_HR <= $topk;
  GENERATE top_HRs;
  };

-- STORE_TABLE('top_season_HRs', top_season_HRs);


    
