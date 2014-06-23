IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons       = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Treating the Union of Several Tables as a Single Table
--

games_a = FOREACH games GENERATE
  year_id, home_team_id AS team,
  home_runs_ct AS runs_for, away_runs_ct AS runs_against, 1 AS is_home:int;

games_b = FOREACH games GENERATE
  away_team_id AS team,     year_id,
  away_runs_ct AS runs_for, home_runs_ct AS runs_against, 0 AS is_home:int;

team_scores = UNION games_a, games_b;

DESCRIBE team_scores;
--   team_scores: {team: chararray,year_id: int,runs_for: int,runs_against: int,is_home: int}

-- bat_career = LOAD '/data/rawd/baseball/sports/bat_career AS (...);
-- pit_career = LOAD '/data/rawd/baseball/sports/pit_career AS (...);
bat_names = FOREACH bat_career GENERATE player_id, nameFirst, nameLast;
pit_names = FOREACH pit_career GENERATE player_id, nameFirst, nameLast;
names_in_both = UNION bat_names, pit_names;
player_names = DISTINCT names_in_both;


-- 
