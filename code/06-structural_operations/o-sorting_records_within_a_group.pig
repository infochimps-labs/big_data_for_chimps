IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Sorting Records within a Group

-- list the top four players for each team-season, in decreasing
-- order by plate appearances.
--
players_PA = FOREACH bat_seasons GENERATE team_id, year_id, player_id, name_first, name_last, PA;
team_playerslist_by_PA = FOREACH (GROUP players_PA BY (team_id, year_id)) {
  players_o_1 = ORDER players_PA BY PA DESC, player_id;
  players_o = LIMIT players_o_1 4;
  GENERATE group.team_id, group.year_id,
    players_o.(player_id, name_first, name_last, PA) AS players_o;
};

team_playerslist_by_PA_2 = FOREACH team_playerslist_by_PA {
  -- will not have same order, even though contents will be identical
  disordered    = DISTINCT players_o;
  -- this ORDER BY does _not_ come for free, though it's not terribly costly
  alt_order     = ORDER players_o BY player_id;
  -- these are all iterative and so will share the same order of descending PA
  still_ordered = FILTER players_o BY PA > 10;
  pa_only       = players_o.PA;
  pretty        = FOREACH players_o GENERATE
    CONCAT((chararray)PA, ':', name_first, ' ', name_last);
  GENERATE team_id, year_id,
    disordered, alt_order,
    still_ordered, pa_only, BagToString(pretty, '|');
};

-- Notice the lines 'Global sort: false // Secondary sort: true' in the explain output
EXPLAIN team_playerslist_by_PA_2;
STORE_TABLE(team_playerslist_by_PA_2, 'team_playerslist_by_PA_2');


-- The lines 'Global sort: false // Secondary sort: true' in the explain output
-- indicate that pig is indeed relying on the free secondary sort, rather than
-- quicksorting the bag itself in the reducer. Lastly: in current versions of
-- Pig this does _not_ extend gracefully to `COGROUP` -- you only get one free
-- application of `ORDER BY`. Here's the dump of an `EXPLAIN` statement for a
-- `COGROUP` with a sort on each bag:
--
-- cogroup_tnstaafl = FOREACH (COGROUP in_a by client_ip, in_b BY client_ip) {
--   ordered_by_hadoop = ORDER in_a BY ts;
--   ordered_painfully = ORDER in_b BY qk;
--   GENERATE ordered_by_hadoop, ordered_painfully;
-- };
-- EXPLAIN cogroup_tnstaafl;
