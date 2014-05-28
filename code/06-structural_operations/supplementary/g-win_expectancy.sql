
-- --
-- -- Bottom of the inning, bases loaded, two outs -- grand slam home run for the win!
-- --
-- SELECT home_score - away_score AS scdiff, ev.* FROM ezevents ev
--   WHERE is_end_game = 1 AND (home_score - away_score = -3) AND (beg_outs_ct = 2) AND (ev_runs_ct = 4)
--   ORDER BY ev_runs_ct DESC, scdiff, year_id ASC
--   ;

-- use the year_id in join criteria so that partitioning can be used

SET @min_year := 1970;
SET @max_year := 2050;

DROP   TABLE IF     EXISTS decorated_ev;
CREATE TABLE IF NOT EXISTS decorated_ev ( INDEX(inn, inn_home, beg_outs_ct, beg_sc, occ1, occ2, occ3) )
AS
SELECT
    -- ev.game_id, ev.event_seq,
    ev.year_id AS year_id,
    IF(ev.inn <= 9, ev.inn, 99)     AS inn,
    ev.inn_home, ev.beg_outs_ct,
    @sc_sign := IF(ev.inn_home = 1, 1, -1) AS sc_sign,
    IF(ev.run1_id != '', 1, 0) AS occ1, IF(ev.run2_id != '', 1, 0) AS occ2, IF(ev.run3_id != '', 1, 0) AS occ3,
    (ev.home_score - ev.away_score) * @sc_sign AS beg_sc,
    ein.end_inn_sc   * @sc_sign AS end_inn_sc,
    egm.end_game_sc  * @sc_sign AS end_game_sc,
    IF( egm.end_game_sc  * @sc_sign > 0, 1, 0) AS is_win,
    IF( egm.end_game_sc  * @sc_sign < 0, 1, 0) AS is_loss,
    IF( egm.end_game_sc  * @sc_sign = 0, 1, 0) AS is_tie
  FROM `ezevents` ev
  JOIN (SELECT year_id, game_id, inn, inn_home,
          home_score + ev_runs_ct - away_score AS end_inn_sc
        FROM `ezevents` WHERE is_end_inn = 1
        AND year_id BETWEEN @min_year AND @max_year
        ) ein
    ON (ein.year_id = ev.year_id) AND (ein.game_id = ev.game_id) AND (ein.inn = ev.inn) AND (ein.inn_home = ev.inn_home)
  JOIN (SELECT year_id, game_id,
          home_score + ev_runs_ct - away_score AS end_game_sc
        FROM `ezevents` WHERE is_end_game = 1
        AND year_id BETWEEN @min_year AND @max_year
        ) egm
    ON (egm.year_id = ev.year_id) AND (egm.game_id = ev.game_id)
  WHERE
    ev.year_id BETWEEN @min_year AND @max_year
;

-- AND e.BAT_HOME_ID = c.BAT_HOME_ID
-- AND BAT_EVENT_FL = "T"
-- AND PA_TRUNC_FL = "F"

-- SELECT
--     inn, inn_home, beg_outs_ct, beg_sc, occ1, occ2, occ3,
--     --
--     SUM(is_win) + SUM(is_loss) AS n_evs,
--     SUM(is_win)  AS n_wins,
--     SUM(is_win) / (SUM(is_win) + SUM(is_loss)) AS win_exp,
--     --
--     AVG(end_game_sc - beg_sc) AS avg_game_gain,
--     AVG(end_inn_sc  - beg_sc) AS avg_inn_gain
--   FROM decorated_ev dev
--   WHERE
--     -- (beg_sc BETWEEN -1 AND 1) AND (inn BETWEEN 7 AND 9)
--     ((inn < 9) OR (inn >= 9 AND inn_home = 0))
--     AND year_id BETWEEN @min_year AND @max_year
--   GROUP BY inn, inn_home, beg_outs_ct, beg_sc, occ1, occ2, occ3
--   ;

SELECT
    inn, inn_home, 
    beg_outs_ct, beg_sc, 
    occ1, occ2, occ3,
    --
    SUM(is_win) + SUM(is_loss) AS n_evs,
    SUM(is_win)  AS n_wins,
    SUM(is_win) / (SUM(is_win) + SUM(is_loss)) AS win_exp,
    --
    AVG(end_game_sc - beg_sc) AS avg_game_gain,
    AVG(end_inn_sc  - beg_sc) AS avg_inn_gain
  FROM decorated_ev dev
  WHERE 1
    AND (beg_sc BETWEEN -4 AND 4) AND (inn BETWEEN 6 AND 9)
    -- AND ((inn < 9) OR (inn = 9 AND inn_home = 0))
    AND year_id >= 1993 AND year_id <= 2010
    AND inn = 6
  GROUP BY occ3, occ2, occ1, beg_outs_ct, beg_sc
  ;
