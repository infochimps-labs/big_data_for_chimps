IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams  = load_park_teams();

-- ***************************************************************************
--
-- === Cumulative Sums and Other Iterative Functions on Groups
--

-- * Rank
-- *

-- * Lead
-- * Lag

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Generating a Running Total (Cumulative Sum / Cumulative Difference)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Generating a Running Product


player_seasons = GROUP bats BY player_id;


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Iterating Lead/Lag Values in an Ordered Bag


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

STORE_TABLE(running_seasons, 'running_seasons');
