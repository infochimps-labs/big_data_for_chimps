IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
bat_seasons = load_bat_seasons();

-- === Selecting Records Associated with Maximum Values

--   -- For each season by a player, select the team they played the most games for.
--   -- In SQL, this is fairly clumsy (involving a self-join and then elimination of
--   -- ties) In Pig, we can ORDER BY within a foreach and then pluck the first
--   -- element of the bag.
-- 
-- SELECT bat.player_id, bat.year_id, bat.team_id, MAX(batmax.Gmax), MAX(batmax.stints), MAX(team_ids), MAX(Gs)
--   FROM       batting bat
--   INNER JOIN (SELECT player_id, year_id, COUNT(*) AS stints, MAX(G) AS Gmax, GROUP_CONCAT(team_id) AS team_ids, GROUP_CONCAT(G) AS Gs FROM batting bat GROUP BY player_id, year_id) batmax
--   ON bat.player_id = batmax.player_id AND bat.year_id = batmax.year_id AND bat.G = batmax.Gmax
--   GROUP BY player_id, year_id
--   -- WHERE stints > 1
--   ;
-- 
--   -- About 7% of seasons have more than one stint; only about 2% of seasons have
--   -- more than one stint and more than a half-season's worth of games
-- SELECT COUNT(*), SUM(mt1stint), SUM(mt1stint)/COUNT(*) FROM (SELECT player_id, year_id, IF(COUNT(*) > 1 AND SUM(G) > 77, 1, 0) AS mt1stint FROM batting GROUP BY player_id, year_id) bat

-- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/ExtremalTupleByNthField.html
DEFINE biggestBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');

pl_best = FOREACH (GROUP bat_seasons BY player_id) GENERATE
  group AS player_id,
  biggestBag(bat_seasons.(H,   year_id, team_id)),
  biggestBag(bat_seasons.(HR,  year_id, team_id)),
  biggestBag(bat_seasons.(OBP, year_id, team_id)),
  biggestBag(bat_seasons.(SLG, year_id, team_id)),
  biggestBag(bat_seasons.(OPS, year_id, team_id))
  ;

DESCRIBE pl_best;

rmf                 $out_dir/pl_best;
STORE pl_best INTO '$out_dir/pl_best';
