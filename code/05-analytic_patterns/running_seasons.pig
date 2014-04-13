%declare dsfp_dir         '/Users/flip/ics/data_science_fun_pack';
register    '$dsfp_dir/pig/pig/contrib/piggybank/java/piggybank.jar';

DEFINE Stitch org.apache.pig.piggybank.evaluation.Stitch();
DEFINE Over   org.apache.pig.piggybank.evaluation.Over();

bats    = LOAD '/tmp/simple_bats.tsv'    AS (
  playerID:chararray, yearID:int, teamID:chararray,
  G:int,     PA:int,    AB:int,    H:int,     BB:int,
  h1B:int,   h2B:int,   h3B:int,   HR:int,    TB:int,
  OBP:float, SLG:float, ISO:float, OPS:float
  );

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
