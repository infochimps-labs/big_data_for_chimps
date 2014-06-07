IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

games = load_games();

-- ***************************************************************************
--
-- === Computing a Won-Loss Record
--

--
-- Using a COGROUP:
--

home_games = FOREACH games GENERATE
  home_team_id AS team_id, year_id,
  (home_runs_ct > away_runs_ct ? 1 : 0) AS win,
  (home_runs_ct < away_runs_ct ? 1 : 0) AS loss
  ;
-- (BAL,2004,1,0)
-- (BAL,2004,0,1)

away_games = FOREACH games GENERATE
  away_team_id AS team_id, year_id,
  (home_runs_ct > away_runs_ct ? 0 : 1) AS win,
  (home_runs_ct < away_runs_ct ? 0 : 1) AS loss
  ;
-- (BOS,2004,0,1)
-- (BOS,2004,1,0)

--
-- === Don't do this:
--
-- all_games = UNION home_games, away_games;
-- team_games = GROUP all_games BY team_id;
--

-- 
-- === Instead, use a COGROUP.
--

team_games = COGROUP
  home_games BY (team_id, year_id),
  away_games BY (team_id, year_id);

-- ((BOS,2004),  {(BOS,2004,1,0),(BOS,2004,1,0),...}, {(BOS,2004,0,1),(BOS,2004,1,0),...})

team_yr_win_loss_v1 = FOREACH team_games {
  wins   = SUM(home_games.win)    + SUM(away_games.win);
  losses = SUM(home_games.loss)   + SUM(away_games.loss);
  G      = COUNT_STAR(home_games) + COUNT_STAR(away_games);
  G_home = COUNT_STAR(home_games);
  ties   = G - (wins + losses);
  GENERATE group.team_id, group.year_id, G, G_home, wins, losses, ties;
  };
--- (BOS,2004,162,81,98,64,0)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Generate both halves with a FLATTEN
--

--
-- Use the summable trick:
--

game_wls = FOREACH games {
  home_win   = (home_runs_ct > away_runs_ct ? 1 : 0);
  home_loss  = (home_runs_ct < away_runs_ct ? 1 : 0);
  summables  = {
    (home_team_id, home_win,  home_loss, 1),
    (away_team_id, home_loss, home_win,  0)   };
  
  GENERATE
    year_id, FLATTEN(summables) AS (team_id:chararray, win:int, loss:int, is_home:int);
};
-- (2004,BAL,1,0,1)
-- (2004,BOS,0,1,0)
-- (2004,BAL,0,1,1)
-- (2004,BOS,1,0,0)

team_yr_win_loss_v2 = FOREACH (GROUP game_wls BY (team_id, year_id)) {
  wins   = SUM(game_wls.win);
  losses = SUM(game_wls.loss);
  G_home = SUM(game_wls.is_home);
  G      = COUNT_STAR(game_wls);
  ties   = G - (wins + losses);
  GENERATE group.team_id, group.year_id, G, G_home, wins, losses, ties;
};
--- (BOS,2004,162,81,98,64,0)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(team_yr_win_loss_v1, 'team_yr_win_loss_v1');
STORE_TABLE(team_yr_win_loss_v2, 'team_yr_win_loss_v2');
