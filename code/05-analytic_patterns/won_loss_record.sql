--
-- ==== Generate a won-loss record
--


SELECT teamID, yearID, SUM(win) AS wins, SUM(loss) AS loss, SUM(tie) AS ties,
    SUM(home_team) AS Ghome, COUNT(*) AS G
  FROM (
    SELECT home_teamID AS teamID, yearID,
        1 AS home_team,
        IF (home_runs_ct > away_runs_ct, 1,0) AS win,
        IF (home_runs_ct < away_runs_ct, 1,0) AS loss,
        IF (home_runs_ct = away_runs_ct, 1,0) AS tie
      FROM retrosheet.games
      WHERE yearID < 2013
    UNION ALL
    SELECT away_teamID AS teamID, yearID,
        0 AS home_team,
        IF (home_runs_ct < away_runs_ct, 1,0) AS win,
        IF (home_runs_ct > away_runs_ct, 1,0) AS loss,
        IF (home_runs_ct = away_runs_ct, 1,0) AS tie
      FROM retrosheet.games
      WHERE yearID < 2013
    ) g1
  GROUP BY teamID, yearID
  ;


-- SELECT t.teamID, ev.teamID, t.yearID, ev.yearID,
--     t.W, ev.wins,
--     t.L, ev.loss,
--     t.G - (t.W + t.L)  AS bdb_ties, ev.ties AS rs_ties,
--     t.G, ev.G, t.Ghome AS bdb_Ghome, ev.Ghome AS rs_Ghome,
--     ABS(t.W - ev.wins) + ABS(t.L - ev.loss) + ABS(t.G - ev.G) + ABS(t.Ghome - ev.Ghome) AS diff
--   FROM      lahman.teams t
--   RIGHT JOIN (
--     SELECT teamID, yearID, SUM(win) AS wins, SUM(loss) AS loss, SUM(tie) AS ties,
--         SUM(home_team) AS Ghome, COUNT(*) AS G
--       FROM (
--         SELECT home_teamID AS teamID, yearID,
--             1 AS home_team,
--             IF ((forfeit_info = "" AND home_runs_ct > away_runs_ct) OR forfeit_info = "H", 1,0) AS win,
--             IF ((forfeit_info = "" AND home_runs_ct < away_runs_ct) OR forfeit_info = "V", 1,0) AS loss,
--             IF ((forfeit_info = "" AND home_runs_ct = away_runs_ct), 1,0) AS tie
--           FROM games
--           WHERE yearID < 2013
--         UNION ALL
--         SELECT away_teamID AS teamID, yearID,
--             0 AS home_team,
--             IF ((forfeit_info = "" AND home_runs_ct < away_runs_ct) OR forfeit_info = "V", 1,0) AS win,
--             IF ((forfeit_info = "" AND home_runs_ct > away_runs_ct) OR forfeit_info = "H", 1,0) AS loss,
--             IF ((forfeit_info = "" AND home_runs_ct = away_runs_ct), 1,0) AS tie
--           FROM games
--           WHERE yearID < 2013
--         ) g1
--       GROUP BY teamID, yearID
--     ) ev
--   ON ev.teamID = IF(t.teamID = "LAA", "ANA", t.teamID) AND ev.yearID = t.yearID
--   WHERE (ABS(t.W - ev.wins) + ABS(t.L - ev.loss) + ABS(t.G - ev.G) + ABS(t.Ghome - ev.Ghome) > 0)
--   ORDER BY yearID DESC, diff DESC
--   ;
  

