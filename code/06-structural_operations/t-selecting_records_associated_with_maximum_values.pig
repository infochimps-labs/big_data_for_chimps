IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
bat_seasons = load_bat_seasons();

-- -- You may need to disable partial aggregation in current versions of Pig.
-- SET pig.exec.mapPartAgg  false
-- Disabling multiquery just so we judge jobs independently
SET opt.multiquery          false
SET pig.exec.mapPartAgg.minReduction  8
;

DEFINE LastEventInBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('2', 'max');

-- === Selecting Records Associated with Maximum Values

-- As we learned at the start of the chapter, you can retrieve the maximum and
-- minimum values for a field using the `MAX(bag)` and `MIN(bag)` functions
-- respectively. These have no memory overhead to speak of and are efficient for
-- both bags within groups and for a full table with `GROUP..ALL`. (By the way:
-- from here out we're just going to talk about maxima -- unless we say
-- otherwise everything applies for minimums by substituting the word 'minimum'
-- or reversing the sort order as appropriate.)
--
-- But if you want to retrieve the record associated with a maximum value (this
-- section), or retrieve multiple values (the followin section), you will need a
-- different approach.

-- ==== Selecting a Single Maximal Record Within a Group, Ignoring Ties

-- events = LOAD '$data_dir/sports/baseball/events_evid' AS (
--   game_id:chararray, event_seq:int,
--   event_id: chararray, -- extra field we made for demonstration purposes
--   year_id:int,
--   game_date:chararray, game_seq:int, away_team_id:chararray,
--   home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int,
--   away_score:int, home_score:int, event_desc:chararray, event_cd:int,
--   hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int,
--   run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int,
--   bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray,
--   bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
--   );
events = load_events();

-- events_most_runs = LIMIT (ORDER events BY ev_runs_ct DESC) 40;
--

events_most_runs_g = FOREACH (GROUP events ALL)
  GENERATE FLATTEN(TOP(40, 16, events));

-- Final event of the game footnote:[For the purposes of a good demonstration,
-- we're ignoring the fact that the table actually has a boolean flag identifying
-- that event]
--
events_final_event_top = FOREACH (GROUP events BY game_id)
  GENERATE FLATTEN(TOP(1, 1, events));

events_final_event_lastinbag = FOREACH (GROUP events BY game_id)
  GENERATE FLATTEN(LastEventInBag(events));

events_final_event_orderlimit = FOREACH (GROUP events BY game_id) {
  events_o = ORDER events BY event_seq DESC;
  events_last = LIMIT events_o 1;
  GENERATE FLATTEN(events_last);
  };

events_final_event_orderfirst = FOREACH (GROUP events BY game_id) {
  events_o = ORDER events BY event_seq DESC;
  GENERATE FLATTEN(FirstTupleFromBag(events_o, ('')));
  };


--
-- If you'll pardon a nonsensical question,
--
nonsense_final_event = FOREACH (GROUP events BY event_desc)
  GENERATE FLATTEN(LastEventInBag(events));

-- For example, we may want to identify the team each player spent the most
-- games with. Right from the start you have to decide how to handle ties. In
-- this case, you're probably looking for a _single_ primary team; the cases
-- where a player had exactly the same number of games for two teams is not
-- worth the hassle of turning a single-valued field into a collection.
--
-- That decision simplifies our

-- -- -- How we made the events_evid table:
-- events = load_events();
-- events_evid = FOREACH events GENERATE game_id, event_seq, SPRINTF('%s-%03d', game_id, event_seq) AS event_id, year_id..;
-- STORE events_evid INTO '$data_dir/sports/baseball/events_evid';

-- ORDER BY on a full table: N
--

-- Consulting the jobtracker console for the events_final_event_1 job shows
-- combine input records: 124205; combine output records: 124169 That's a pretty
-- poor showing. We know something pig doesn't: since all the events for a game
-- are adjacent in the file, the maximal record chosen by each mapper is almost
-- certainly the overall maximal record for that group.
--
-- Running it again with `SET pig.exec.nocombiner true` improved
-- the run time dramatically.
--
-- In contrast, if we

-- events = load_events();
-- events_evid = FOREACH events GENERATE game_id, event_seq, SPRINTF('%s-%03d', game_id, event_seq) AS event_id, year_id..;
-- team_season_final_event = FOREACH (GROUP events BY (home_team_id, year_id))
--   GENERATE FLATTEN(TOP(1, 2, events));

team_season_final_event = FOREACH (GROUP events BY (home_team_id, year_id)) {
  evs = FOREACH events GENERATE (game_id, event_seq) AS ev_id, *;
  GENERATE FLATTEN(TOP(1, 0, evs));
};

-- SET pig.cachedbag.memusage       0.10
-- SET pig.spill.size.threshold       20100100
-- SET pig.spill.gc.activation.size 9100100100
-- -- ;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- SELECT bat.player_id, bat.year_id, bat.team_id, MAX(batmax.Gmax), MAX(batmax.stints), MAX(team_ids), MAX(Gs)
--   FROM       batting bat
--   INNER JOIN (SELECT player_id, year_id, COUNT(*) AS stints, MAX(G) AS Gmax, GROUP_CONCAT(team_id) AS team_ids, GROUP_CONCAT(G) AS Gs FROM batting bat GROUP BY player_id, year_id) batmax
--   ON bat.player_id = batmax.player_id AND bat.year_id = batmax.year_id AND bat.G = batmax.Gmax
--   GROUP BY player_id, year_id
--   -- WHERE stints > 1
--   ;
--
-- -- About 7% of seasons have more than one stint; only about 2% of seasons have
-- -- more than one stint and more than a half-season's worth of games
-- SELECT COUNT(*), SUM(mt1stint), SUM(mt1stint)/COUNT(*) FROM (SELECT player_id, year_id, IF(COUNT(*) > 1 AND SUM(G) > 77, 1, 0) AS mt1stint FROM batting GROUP BY player_id, year_id) bat
--
-- --
-- -- Earlier in the chapter we annotated each player's season by whether they were
-- -- the league leader in Home Runs (HR):
--
-- bats_with_max_hr = FOREACH (GROUP bat_seasons BY year_id) GENERATE
--   MAX(bat_seasons.HR) as max_HR,
--   FLATTEN(bat_seasons);
--
-- -- Find the desired result:
-- bats_with_l_cg = FOREACH bats_with_max_hr GENERATE
--   player_id.., (HR == max_HR ? 1 : 0);
-- bats_with_l_cg = ORDER bats_with_l_cg BY player_id, year_id;
--
--
-- -- We can also do this using a join:
--
-- -- Find the max_HR for each season
-- HR_by_year     = FOREACH bat_seasons GENERATE year_id, HR;
-- max_HR_by_year = FOREACH (GROUP HR_by_year BY year_id) GENERATE
--   group AS year_id, MAX(HR_by_year.HR) AS max_HR;
--
-- -- Join it with the original table to put records in full-season context:
-- bats_with_max_hr_jn = JOIN
--   bat_seasons    BY year_id, -- large table comes *first* in a replicated join
--   max_HR_by_year BY year_id  USING 'replicated';
-- -- Find the desired result:
-- bats_with_l_jn = FOREACH bats_with_max_hr_jn GENERATE
--   player_id..RBI, (HR == max_HR ? 1 : 0);
--
-- -- The COGROUP version has only one reduce step, but it requires sending the
-- -- full contents of the table to the reducer: its cost is two full-table scans
-- -- and one full-table group+sort. The JOIN version first requires effectively
-- -- that same group step, but with only the group key and the field of interest
-- -- sent to the reducer. It then requires a JOIN step to bring the records into
-- -- context, and a final pass to use it. If we can use a replicated join, the
-- -- cost is a full-table scan and a fractional group+sort for preparing the list,
-- -- plus two full-table scans for the replicated join. If we can't use a
-- -- replicated join, the cogroup version is undoubtedly superior.
-- --
-- -- So if a replicated join is possible, and the projected table is much smaller
-- -- than the original, go with the join version. However, if you are going to
-- -- decorate with multiple aggregations, or if the projected table is large, use
-- -- the GROUP/DECORATE/FLATTEN pattern.


-- STORE_TABLE(bats_with_l_cg, 'bats_with_l_cg');
-- STORE_TABLE(bats_with_l_jn, 'bats_with_l_jn');


-- STORE_TABLE(events_most_runs,              'events_most_runs');
-- STORE_TABLE(events_most_runs_g,            'events_most_runs_g');
-- STORE_TABLE(events_final_event_top,        'events_final_event_top');
-- STORE_TABLE(events_final_event_lastinbag,  'events_final_event_lastinbag');
-- STORE_TABLE(events_final_event_orderlimit, 'events_final_event_orderlimit');
-- STORE_TABLE(events_final_event_orderfirst, 'events_final_event_orderfirst');
-- STORE_TABLE(nonsense_final_event,             'nonsense_final_event');
-- STORE_TABLE(team_season_final_event,       'team_season_final_event');
