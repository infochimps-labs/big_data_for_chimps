IMPORT 'common_macros.pig';

bats = load_bats();

player_seasons = GROUP bats BY playerID;

--
-- Produce for each stat the running total by season, and the next season's value
-- 
running_seasons = FOREACH player_seasons {
  seasons = ORDER bats BY yearID;
  GENERATE
    group AS playerID,
    FLATTEN(Stitch(
      seasons.yearID,
      seasons.G,  Over(seasons.G,  'SUM(int)'), Over(seasons.G,  'lead', 0, 1, 1, -1), 
      seasons.H,  Over(seasons.H,  'SUM(int)'), Over(seasons.H,  'lead', 0, 1, 1, -1), 
      seasons.HR, Over(seasons.HR, 'SUM(int)'), Over(seasons.HR, 'lead', 0, 1, 1, -1)
      ))
    AS (yearID, G, next_G, cume_G, H, next_H, cume_H, HR, next_HR, cume_HR);
};

rmf                         /data/out/baseball/running_seasons;
STORE running_seasons INTO '/data/out/baseball/running_seasons';
