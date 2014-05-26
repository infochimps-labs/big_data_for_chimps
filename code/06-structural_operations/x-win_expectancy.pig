IMPORT './common_macros.pig';
%DEFAULT beg_year 1993
%DEFAULT end_year 2010


--
-- Here are Tangotiger's results for comparison, giving the average runs scored,
-- from given base/out state to end of inning (for completed innings through the
-- 8th inning); uses Retrosheet 1950-2010 data as of 2010.
-- http://www.tangotiger.net/re24.html
-- 
--                   1993-2010            1969-1992           1950-1968
-- bases \ outs 0_out 1_out 2_out   0_out 1_out 2_out   0_out 1_out 2_out
--
-- -  -   -     0.544 0.291 0.112   0.477 0.252 0.094   0.476 0.256 0.098
-- -  -   3B    1.433 0.989 0.385   1.340 0.943 0.373   1.342 0.926 0.378
-- -  2B  -     1.170 0.721 0.348   1.102 0.678 0.325   1.094 0.680 0.330
-- -  2B  3B    2.050 1.447 0.626   1.967 1.380 0.594   1.977 1.385 0.620
-- 1B -   -     0.941 0.562 0.245   0.853 0.504 0.216   0.837 0.507 0.216
-- 1B -   3B    1.853 1.211 0.530   1.715 1.149 0.484   1.696 1.151 0.504
-- 1B 2B  -     1.556 0.963 0.471   1.476 0.902 0.435   1.472 0.927 0.441
-- 1B 2B  3B    2.390 1.631 0.814   2.343 1.545 0.752   2.315 1.540 0.747
--
--               1993-2010               1969-1992           1950-1968              1950-2010
-- -  -   -     0.539 0.287 0.111   0.471 0.248 0.092   0.471 0.252 0.096     0.4957  0.2634  0.0998  
-- -  -   3B    1.442 0.981 0.382   1.299 0.92  0.368   1.285 0.904 0.373     1.3408  0.9393  0.374   
-- -  2B  -     1.172 0.715 0.339   1.081 0.663 0.316   1.055 0.662 0.322     1.1121  0.682   0.3257  
-- -  2B  3B    2.046 1.428 0.599   1.927 1.341 0.56    1.936 1.338 0.59      1.9754  1.3732  0.5814  
-- 1B -   -     0.932 0.554 0.239   0.843 0.496 0.21    0.828 0.5   0.211     0.8721  0.5181  0.2211  
-- 1B -   3B    1.841 1.196 0.517   1.699 1.131 0.47    1.688 1.132 0.491     1.7478  1.1552  0.4922  
-- 1B 2B  -     1.543 0.949 0.456   1.461 0.886 0.42    1.456 0.912 0.426     1.4921  0.9157  0.4349  
-- 1B 2B  3B    2.374 1.61  0.787   2.325 1.522 0.721   2.297 1.513 0.724     2.3392  1.5547  0.7482  

  
-- load the right range of years and extract stats to be used if needed
events      = load_events($beg_year, $end_year);
event_stats = FOREACH (GROUP events ALL) GENERATE COUNT_STAR(events) AS ct;

--
-- Get the game state (inning + top/bottom; number of outs; bases occupied;
-- score differential), and summable-trick fields for finding the score at the
-- end of the inning and at the end of the game.
--
-- Only one record per inning will have a value for end_inn_sc_maybe, and only
-- one per game for end_game_sc_maybe: so taking the 'MAX' gives only the value
-- of that entry.
--
-- Only innings of 3 full outs are useful for the run expectancy table;
-- otherwise no end_inn_sc is calculated.
-- 
evs_summable = FOREACH events {
  beg_sc  = (home_score - away_score);
  end_sc  = beg_sc + ev_runs_ct;
  GENERATE
    game_id                   AS game_id,
    inn                       AS inn,
    (inn_home == 1 ? 1 : -1)  AS inn_sign:int,
    beg_outs_ct               AS beg_outs_ct,
    (run1_id != '' ? 1 : 0)   AS occ1:int,
    (run2_id != '' ? 1 : 0)   AS occ2:int,
    (run3_id != '' ? 1 : 0)   AS occ3:int,
    beg_sc                    AS beg_sc:int,
    ((is_end_inn  == 1) AND (beg_outs_ct + ev_outs_ct == 3) ? end_sc : NULL) AS end_inn_sc_maybe:int,
    (is_end_game == 1 ? end_sc : NULL)                                       AS end_game_sc_maybe:int
    -- , away_score, home_score, ev_runs_ct, ev_outs_ct, is_end_inn, is_end_game, event_seq
    ;
  };

--
-- Decorate each game's records with the end-of-game score, then partially
-- flatten by inning+half. The result is as if we had initially grouped on
-- (game_id, inn, inn_sign) -- but since each (game) group strictly contains
-- each (game, inn, inn_sign) subgroup, we don't have to do another reduce!
--
evs_by_inning = FOREACH (GROUP evs_summable BY game_id) {
  GENERATE
    MAX(evs_summable.end_game_sc_maybe) AS end_game_sc,
    FLATTEN(BagGroup(evs_summable, evs_summable.(inn, inn_sign)))
    ;
  };

--
-- Flatten further back into single-event records, but now decorated with the
-- end-game and end-inning scores and won/loss/tie status:
--
-- * Decorate each inning's records with the end-of-inning score
-- * Figure out if the game was a win / loss / tie
-- * Convert end-of-* score differentials from (home-away) to (batting-fielding)
-- * Flatten back into individual events.
-- * Decorate each inning's records with the gain-to-end-of-inning. note that
--   this is a batting-fielding differential, not home-away differential
--
-- Must use two steps because end_inn_sc is used to find inn_gain, and you can't
-- iterate inside flatten.
--
evs_decorated = FOREACH evs_by_inning {
  is_win  = ((group.inn_sign*end_game_sc >  0) ? 1 : 0);
  is_loss = ((group.inn_sign*end_game_sc <  0) ? 1 : 0);
  is_tie  = ((group.inn_sign*end_game_sc == 0) ? 1 : 0);
  end_inn_sc = MAX(evs_summable.end_inn_sc_maybe);
  GENERATE
    group.inn, group.inn_sign,
    FLATTEN(evs_summable.(beg_outs_ct, occ1, occ2, occ3, beg_sc
    -- , away_score, home_score, ev_runs_ct, ev_outs_ct, is_end_inn, is_end_game, event_seq, game_id
    )) AS (beg_outs_ct, occ1, occ2, occ3, beg_sc),
    end_game_sc AS end_game_sc,
    end_inn_sc AS end_inn_sc,
    is_win, is_loss, is_tie
    ;
  };
evs_decorated = FOREACH evs_decorated GENERATE
    inn, inn_sign, beg_outs_ct, occ1, occ2, occ3, beg_sc,
  -- away_score, home_score, ev_runs_ct, ev_outs_ct, is_end_inn, is_end_game, event_seq, game_id,
    inn_sign*(end_inn_sc - beg_sc) AS inn_gain,
    end_inn_sc, end_game_sc, is_win, is_loss, is_tie
    ;

-- -- for debugging; make sure to add back the away_score...game_id fields in FOREACH's above
-- DESCRIBE evs_decorated;
-- evs_decorated = ORDER evs_decorated BY game_id, event_seq;
STORE_TABLE('evs_decorated-$beg_year-$end_year', evs_decorated);

--
-- === Run Expectancy
-- 
-- How many runs is a game state worth from the perspective of any inning?
-- Bases are cleared away at inning finish, so the average number of runs scored
-- from an event to the end of its inning is the dominant factor.
-- 

-- Only want non-walkoff and full innings
re_evs      = FILTER evs_decorated BY (inn <= 8) AND (end_inn_sc IS NOT NULL);
re_ev_stats = FOREACH (GROUP re_evs ALL) {
  re_ev_ct = COUNT_STAR(re_evs);
  GENERATE re_ev_ct AS ct, ((double)re_ev_ct / (double)event_stats.ct) AS re_ev_fraction;
  };

-- Group on game state in inning (outs and bases occupied),
-- and find the average score gain
run_expectancy = FOREACH (GROUP re_evs BY (beg_outs_ct, occ1, occ2, occ3)) {
  GENERATE
    FLATTEN(group)       AS (beg_outs_ct, occ1, occ2, occ3),
    AVG(re_evs.inn_gain) AS avg_inn_gain,
    COUNT_STAR(re_evs)   AS ct,
    (long)re_ev_stats.ct AS tot_ct,
    (long)event_stats.ct AS tot_unfiltered_ct;
  };

STORE_TABLE('run_expectancy-$beg_year-$end_year', run_expectancy);
-- run_expectancy = LOAD '/tmp/run_expectancy-$beg_year-$end_year' AS (
--   beg_outs_ct:int, occ1:int, occ2:int, occ3:int, avg_inn_gain:float, ct:int, tot_ct:int);

--
-- Baseball Researchers usually format run expectancy tables with rows as bases
-- and columns as outs.  The summable trick will let us create a pivot table of
-- bases vs. runs.

re_summable = FOREACH run_expectancy GENERATE
  CONCAT((occ1 IS NULL ? '-  ' : '1B '), (occ2 IS NULL ? '-  ' : '2B '), (occ3 IS NULL ? '-  ' : '3B ')) AS bases:chararray,
  (beg_outs_ct == 0 ? avg_inn_gain : 0) AS outs_0_col,
  (beg_outs_ct == 1 ? avg_inn_gain : 0) AS outs_1_col,
  (beg_outs_ct == 2 ? avg_inn_gain : 0) AS outs_2_col
  ;
re_pretty = FOREACH (GROUP re_summable BY bases) GENERATE
  group AS bases,
  ROUND_TO(MAX(re_summable.outs_0_col), 3) AS outs_0_col,
  ROUND_TO(MAX(re_summable.outs_1_col), 3) AS outs_1_col,
  ROUND_TO(MAX(re_summable.outs_2_col), 3) AS outs_2_col,
  $beg_year AS beg_year, $end_year AS end_year
  ;

STORE_TABLE('run_expectancy-$beg_year-$end_year-pretty', re_pretty);

