--
-- ==== Generate a won-loss record
--


SELECT team_id, year_id, SUM(win) AS wins, SUM(loss) AS loss, SUM(tie) AS ties,
    SUM(home_team) AS Ghome, COUNT(*) AS G
  FROM (
    SELECT home_team_id AS team_id, year_id,
        1 AS home_team,
        IF (home_runs_ct > away_runs_ct, 1,0) AS win,
        IF (home_runs_ct < away_runs_ct, 1,0) AS loss,
        IF (home_runs_ct = away_runs_ct, 1,0) AS tie
      FROM retrosheet.games
      WHERE year_id < 2013
    UNION ALL
    SELECT away_team_id AS team_id, year_id,
        0 AS home_team,
        IF (home_runs_ct < away_runs_ct, 1,0) AS win,
        IF (home_runs_ct > away_runs_ct, 1,0) AS loss,
        IF (home_runs_ct = away_runs_ct, 1,0) AS tie
      FROM retrosheet.games
      WHERE year_id < 2013
    ) g1
  GROUP BY team_id, year_id
  ;


-- SELECT t.team_id, ev.team_id, t.year_id, ev.year_id,
--     t.W, ev.wins,
--     t.L, ev.loss,
--     t.G - (t.W + t.L)  AS bdb_ties, ev.ties AS rs_ties,
--     t.G, ev.G, t.Ghome AS bdb_Ghome, ev.Ghome AS rs_Ghome,
--     ABS(t.W - ev.wins) + ABS(t.L - ev.loss) + ABS(t.G - ev.G) + ABS(t.Ghome - ev.Ghome) AS diff
--   FROM      lahman.teams t
--   RIGHT JOIN (
--     SELECT team_id, year_id, SUM(win) AS wins, SUM(loss) AS loss, SUM(tie) AS ties,
--         SUM(home_team) AS Ghome, COUNT(*) AS G
--       FROM (
--         SELECT home_team_id AS team_id, year_id,
--             1 AS home_team,
--             IF ((forfeit_info = "" AND home_runs_ct > away_runs_ct) OR forfeit_info = "H", 1,0) AS win,
--             IF ((forfeit_info = "" AND home_runs_ct < away_runs_ct) OR forfeit_info = "V", 1,0) AS loss,
--             IF ((forfeit_info = "" AND home_runs_ct = away_runs_ct), 1,0) AS tie
--           FROM games
--           WHERE year_id < 2013
--         UNION ALL
--         SELECT away_team_id AS team_id, year_id,
--             0 AS home_team,
--             IF ((forfeit_info = "" AND home_runs_ct < away_runs_ct) OR forfeit_info = "V", 1,0) AS win,
--             IF ((forfeit_info = "" AND home_runs_ct > away_runs_ct) OR forfeit_info = "H", 1,0) AS loss,
--             IF ((forfeit_info = "" AND home_runs_ct = away_runs_ct), 1,0) AS tie
--           FROM games
--           WHERE year_id < 2013
--         ) g1
--       GROUP BY team_id, year_id
--     ) ev
--   ON ev.team_id = IF(t.team_id = "LAA", "ANA", t.team_id) AND ev.year_id = t.year_id
--   WHERE (ABS(t.W - ev.wins) + ABS(t.L - ev.loss) + ABS(t.G - ev.G) + ABS(t.Ghome - ev.Ghome) > 0)
--   ORDER BY year_id DESC, diff DESC
--   ;
  

