IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

peeps       = load_people();
games             = load_games();

-- ***************************************************************************
--
-- === Projecting Chosen Columns from a Table by Name
--

game_scores = FOREACH games GENERATE
  away_team_id, home_team_id, home_runs_ct, away_runs_ct;

-- ***************************************************************************
--
-- ==== Using a FOREACH to select, rename and reorder fields @win_loss_union
--

games_a = FOREACH games GENERATE
  home_team_id AS team,     year_id, 
  home_runs_ct AS runs_for, away_runs_ct AS runs_against, 1 AS is_home:int;
games_b = FOREACH games GENERATE
  away_team_id AS team,     year_id,
  away_runs_ct AS runs_for, home_runs_ct AS runs_against, 0 AS is_home:int;

team_scores = UNION games_a, games_b;

DESCRIBE team_scores;
-- team_scores: {team: chararray,year_id: int,runs_for: int,runs_against: int,is_home: int}


team_season_runs = FOREACH (GROUP team_scores BY team_id) GENERATE
  group AS team_id, SUM(runs_for) AS R, SUM(runs_against) AS RA;

STORE_TABLE(game_scores, 'game_scores');
STORE_TABLE(team_scores, 'team_scores');
