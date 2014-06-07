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


--
-- Earlier in the chapter we annotated each player's season by whether they were
-- the league leader in Home Runs (HR):

bats_with_max_hr = FOREACH (GROUP bat_seasons BY year_id) GENERATE
  MAX(bat_seasons.HR) as max_HR,
  FLATTEN(bat_seasons);

-- Find the desired result:
bats_with_l_cg = FOREACH bats_with_max_hr GENERATE
  player_id.., (HR == max_HR ? 1 : 0);
bats_with_l_cg = ORDER bats_with_l_cg BY player_id, year_id;

  
-- We can also do this using a join:

-- Find the max_HR for each season
HR_by_year     = FOREACH bat_seasons GENERATE year_id, HR;
max_HR_by_year = FOREACH (GROUP HR_by_year BY year_id) GENERATE
  group AS year_id, MAX(HR_by_year.HR) AS max_HR;

-- Join it with the original table to put records in full-season context:
bats_with_max_hr_jn = JOIN
  bat_seasons    BY year_id, -- large table comes *first* in a replicated join
  max_HR_by_year BY year_id  USING 'replicated';
-- Find the desired result:
bats_with_l_jn = FOREACH bats_with_max_hr_jn GENERATE
  player_id..RBI, (HR == max_HR ? 1 : 0);

-- The COGROUP version has only one reduce step, but it requires sending the
-- full contents of the table to the reducer: its cost is two full-table scans
-- and one full-table group+sort. The JOIN version first requires effectively
-- that same group step, but with only the group key and the field of interest
-- sent to the reducer. It then requires a JOIN step to bring the records into
-- context, and a final pass to use it. If we can use a replicated join, the
-- cost is a full-table scan and a fractional group+sort for preparing the list,
-- plus two full-table scans for the replicated join. If we can't use a
-- replicated join, the cogroup version is undoubtedly superior.
--
-- So if a replicated join is possible, and the projected table is much smaller
-- than the original, go with the join version. However, if you are going to
-- decorate with multiple aggregations, or if the projected table is large, use
-- the GROUP/DECORATE/FLATTEN pattern.

STORE_TABLE(bats_with_l_cg, 'bats_with_l_cg');
STORE_TABLE(bats_with_l_jn, 'bats_with_l_jn');
