IMPORT 'common_macros.pig';

-- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/ExtremalTupleByNthField.html
DEFINE biggestBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');

bats = load_bats();

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

--  FirstTupleFromBag datafu.pig.bags.FirstTupleFromBag();

best_stats2 = FOREACH player_seasons {
  by_HR = ORDER bats BY HR DESC;
  GENERATE playerID, 
  };
