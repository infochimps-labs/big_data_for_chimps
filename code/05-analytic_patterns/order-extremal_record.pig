IMPORT 'common_macros.pig'; %DEFAULT out_dir '/data/out/baseball'; 

-- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/ExtremalTupleByNthField.html
DEFINE biggestBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');

pl_yr_stats = load_bat_seasons();

pl_best = FOREACH (GROUP pl_yr_stats BY player_id) GENERATE
  group AS player_id,
  biggestBag(pl_yr_stats.(H,   year_id, team_id)),
  biggestBag(pl_yr_stats.(HR,  year_id, team_id)),
  biggestBag(pl_yr_stats.(OBP, year_id, team_id)),
  biggestBag(pl_yr_stats.(SLG, year_id, team_id)),
  biggestBag(pl_yr_stats.(OPS, year_id, team_id))
  ;

DESCRIBE pl_best;

rmf                 $out_dir/pl_best;
STORE pl_best INTO '$out_dir/pl_best';
