IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
people            = load_people();
teams             = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Joining a Table with Itself (self-join)
--

SELECT DISTINCT b1.player_id, b2.player_id
  FROM bat_season b1, bat_season b2
  WHERE b1.team_id = b2.team_id          -- same team
    AND b1.year_id = b2.year_id          -- same season
    AND b1.player_id != b2.player_id     -- reject self-teammates
  GROUP BY b1.player_id
  ;

pty1 = foreach bat_season GENERATE team_id, player_id, year_id;
pty2 = foreach bat_season GENERATE team_id, player_id, year_id;

teammates = FOREACH (
    JOIN pty1 BY (team_id, year_id), 
    JOIN pty1 BY (team_id, year_id)        
