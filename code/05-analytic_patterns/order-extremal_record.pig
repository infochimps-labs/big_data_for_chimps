IMPORT 'common_macros.pig'; %DEFAULT out_dir '/data/out/baseball'; 

-- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/ExtremalTupleByNthField.html
DEFINE biggestBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');

bats = load_bat_seasons();

player_seasons = GROUP bats BY player_id;

best_stats = FOREACH player_seasons GENERATE
  group AS player_id,
  biggestBag(bats.(H,   year_id, team_id)),
  biggestBag(bats.(HR,  year_id, team_id)),
  biggestBag(bats.(OBP, year_id, team_id)),
  biggestBag(bats.(SLG, year_id, team_id)),
  biggestBag(bats.(OPS, year_id, team_id))
  ;

DESCRIBE best_stats;

DUMP best_stats;

--  FirstTupleFromBag datafu.pig.bags.FirstTupleFromBag();

best_stats2 = FOREACH player_seasons {
  by_HR = ORDER bats BY HR DESC;
  GENERATE player_id, 
  };
