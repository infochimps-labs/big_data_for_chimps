IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Sorting Records within a Group

-- This operation is straightforward enough and so useful we've been applying it
-- all this chapter, but it's time to be properly introduced and clarify a
-- couple points.
--
-- Sort records within a group using ORDER BY within a nested FOREACH. Here's a
-- snippet to list the top four players for each team-season, in decreasing
-- order by plate appearances.
--
players_PA = FOREACH bat_seasons GENERATE team_id, year_id, player_id, name_first, name_last, PA;
team_playerslist_by_PA = FOREACH (GROUP players_PA BY (team_id, year_id)) {
  players_o_1 = ORDER players_PA BY PA DESC, player_id;
  players_o = LIMIT players_o_1 4;
  GENERATE group.team_id, group.year_id,
    players_o.(player_id, name_first, name_last, PA) AS players_o;
};
--
-- Ordering a group in the nested block immediately following a structural
-- operation does not require extra operations, since Pig is able to simply
-- specify those fields as secondary sort keys. Basically, as long as it happens
-- first in the reduce operation it's free (though if you're nervous, look for
-- the line "Secondary sort: true" in the output of EXPLAIN). Messing with a bag
-- before the `ORDER..BY` causes Pig to instead sort it in-memory using
-- quicksort, but will not cause another map-reduce job. That's good news unless
-- some bags are so huge they challenge available RAM or CPU, which won't be
-- subtle.
--
-- If you depend on having a certain sorting, specify it explicitly, even when
-- you notice that a `GROUP..BY` or some other operation seems to leave it in
-- that desired order. It gives a valuable signal to anyone reading your code,
-- and a necessary defense against some future optimization deranging that order
-- footnote:[That's not too hypothetical: there are cases where you could more
-- efficiently group by binning the items directly in a Map rather than sorting]
--
-- Once sorted, the bag's order is preserved by projections, by most functions
-- that iterate over a bag, and by the nested pipeline operations FILTER,
-- FOREACH, and LIMIT. The return values of nested structural operations CROSS,
-- ORDER..BY and DISTINCT do not follow the same order as their input; neither
-- do structural functions such as CountEach (in-bag histogram) or the set
-- operations (REF) described at the end of the chapter. (Note that though their
-- outputs are dis-arranged these of course don't mess with the order of their
-- inputs: everything in Pig is immutable once created.)
--
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
