IMPORT 'common_macros.pig'; %DEFAULT out_dir '/data/out/baseball'; 

bats = load_bat_seasons();

player_seasons = GROUP bats BY player_id;

--
-- Produce for each stat the running total by season, and the next season's value
-- 
running_seasons = FOREACH player_seasons {
  seasons = ORDER bats BY year_id;
  GENERATE
    group AS player_id,
    FLATTEN(Stitch(
      seasons.year_id,
      seasons.G,  Over(seasons.G,  'SUM(int)'), Over(seasons.G,  'lead', 0, 1, 1, -1), 
      seasons.H,  Over(seasons.H,  'SUM(int)'), Over(seasons.H,  'lead', 0, 1, 1, -1), 
      seasons.HR, Over(seasons.HR, 'SUM(int)'), Over(seasons.HR, 'lead', 0, 1, 1, -1)
      ))
    AS (year_id, G, next_G, cume_G, H, next_H, cume_H, HR, next_HR, cume_HR);
};

rmf                         $out_dir/running_seasons;
STORE running_seasons INTO '$out_dir/running_seasons';
