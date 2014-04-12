
games = LOAD '/tmp/games_2004.tsv' AS (
  away_teamID:chararray, home_teamID:chararray, gameID:chararray, yearID:int,
  home_runs_ct:int, away_runs_ct:int);

--
-- Use the summable trick:
--

home_games = FOREACH games GENERATE
  home_teamID AS teamID, yearID,
  (home_runs_ct > away_runs_ct ? 1 : 0) AS win,
  (home_runs_ct < away_runs_ct ? 1 : 0) AS loss
  ;
-- (BOS,2004,1,0)
-- (BOS,2004,1,0)

away_games = FOREACH games GENERATE
  away_teamID AS teamID, yearID,
  (home_runs_ct > away_runs_ct ? 0 : 1) AS win,
  (home_runs_ct < away_runs_ct ? 0 : 1) AS loss
  ;
-- (BOS,2004,0,1)
-- (BOS,2004,1,0)

--
-- === Don't do this:
--
-- all_games = UNION home_games, away_games;
-- team_games = GROUP all_games BY teamID;
--

-- 
-- === Instead, use a COGROUP.
--

team_games = COGROUP home_games BY (teamID, yearID), away_games BY (teamID, yearID);

-- ((BOS,2004),  {(BOS,2004,1,0),(BOS,2004,1,0),...}, {(BOS,2004,0,1),(BOS,2004,1,0),...})

winloss_record = FOREACH team_games {
  wins   = SUM(home_games.win)    + SUM(away_games.win);
  losses = SUM(home_games.loss)   + SUM(away_games.loss);
  G      = COUNT_STAR(home_games) + COUNT_STAR(away_games);
  G_home = COUNT_STAR(home_games);
  ties   = G - (wins + losses);
  GENERATE group.teamID, group.yearID, G, G_home, wins, losses, ties;
  };
--- (BOS,2004,162,81,98,64,0)

rmf                        /data/out/baseball/won_loss_record;
STORE winloss_record INTO '/data/out/baseball/won_loss_record';

-- ***************************************************************************
-- ** Alternate approach, generating both halves with a FLATTEN
-- ***************************************************************************

--
-- Use the summable trick:
--

game_wls = FOREACH games {
  home_win   = (home_runs_ct > away_runs_ct ? 1 : 0);
  home_loss  = (home_runs_ct < away_runs_ct ? 1 : 0);
  summables  = {
    (home_teamID, home_win,  home_loss, 1),
    (away_teamID, home_loss, home_win,  0)   };
  
  GENERATE
    yearID, FLATTEN(summables) AS (teamID:chararray, win:int, loss:int, is_home:int);
  };
-- (2004,BAL,1,0,1)
-- (2004,BOS,0,1,0)
-- (2004,BAL,0,1,1)
-- (2004,BOS,1,0,0)

team_games2 = GROUP game_wls BY (teamID, yearID);

-- ((BOS,2004),  {(2004,BOS,1,0,1),(2004,BOS,0,1,0),(2004,BOS,1,0,0),...})

winloss_record2 = FOREACH team_games2 {
  wins   = SUM(game_wls.win);
  losses = SUM(game_wls.loss);
  G_home = SUM(game_wls.is_home);
  G      = COUNT_STAR(game_wls);
  ties   = G - (wins + losses);
  GENERATE group.teamID, group.yearID, G, G_home, wins, losses, ties;
  };
--- (BOS,2004,162,81,98,64,0)

rmf                         /data/out/baseball/won_loss_record2;
STORE winloss_record2 INTO '/data/out/baseball/won_loss_record2';

