%declare dsfp_dir         '/Users/flip/ics/data_science_fun_pack';
register    '$dsfp_dir/pig/pig/contrib/piggybank/java/piggybank.jar';

-- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/ExtremalTupleByNthField.html
DEFINE biggestBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');

bats    = LOAD '/tmp/simple_bats.tsv'    AS (
  playerID:chararray, yearID:int, teamID:chararray,
  G:int,     PA:int,    AB:int,    H:int,  BB:int, HBP:int,
  h1B:int,   h2B:int,   h3B:int,   HR:int, TB:int,
  OBP:float, SLG:float, ISO:float, OPS:float
  );

player_seasons = GROUP bats BY playerID;

best_stats = FOREACH player_seasons GENERATE
  group AS playerID,
  biggestBag(bats.(H,   yearID, teamID)),
  biggestBag(bats.(HR,  yearID, teamID)),
  biggestBag(bats.(OBP, yearID, teamID)),
  biggestBag(bats.(SLG, yearID, teamID)),
  biggestBag(bats.(OPS, yearID, teamID))
  ;

DESCRIBE best_stats;

DUMP best_stats;

best_stats2 = FOREACH player_seasons {
  by_HR = ORDER bats BY HR DESC;
  GENERATE playerID, 
  };
