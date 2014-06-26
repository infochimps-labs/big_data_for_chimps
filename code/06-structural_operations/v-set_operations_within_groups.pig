IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

sig_seasons = load_sig_seasons();

-- ***************************************************************************
--
-- === Set Operations
--
-- * Distinct Union;
-- * Set Intersection
-- * Set Difference
-- * Set Equality
-- * Symmetric Set Difference

-- To demonstrate set operations on grouped records, let's look at the
-- year-to-year churn of mainstay players footnote:[using our definition of a
-- significant season: post-1900 and 450 or more plate appearances] on each
-- team.

-- ==== Constructing a Sequence of Sets

-- Since it's a self-cogroup, we must do a dummy projection to make new aliases
-- (see the earlier section on self-join for details).
y1 = FOREACH sig_seasons GENERATE player_id, team_id, year_id;
y2 = FOREACH sig_seasons GENERATE player_id, team_id, year_id;

-- Put each team of players in context with the next year's team of players
year_to_year_players = COGROUP
  y1 BY (team_id, year_id),
  y2 BY (team_id, year_id-1)
  ;
-- Clear away the grouped-on fields
rosters = FOREACH year_to_year_players GENERATE
  group.team_id AS team_id,
  group.year_id AS year_id,
  y1.player_id  AS pl1,
  y2.player_id  AS pl2
  ;
-- The first and last years of existence don't have anything interesting to
-- compare, so reject them.
rosters = FILTER rosters BY (COUNT_STAR(pl1) == 0L OR COUNT_STAR(pl2) == 0L);

--
-- ==== Set operations within group
--
-- The content of `rosters` is a table with two key columns: team and year; and
-- two bags: the set of players from that year and the set of players from the
-- following year.
--
-- Describe the evolution of the team from year to year:
--
roster_changes_y2y = FOREACH rosters {
  -- Distinct Union
  either_year  = SetUnion(pl1, pl2);
  -- Symmetric Difference on whole tuple
  non_stayed_1 = DIFF(pl1, pl2);

  -- The other operations require sorted bags.
  pl1_o = ORDER pl1 BY player_id;
  pl2_o = ORDER pl2 BY player_id;

  -- Set Intersection
  stayed      = SetIntersect(pl1_o, pl2_o);
  -- Set Difference
  y1_departed = SetDifference(pl1_o, pl2_o);
  y2_arrived  = SetDifference(pl2_o, pl1_o);
  -- Symmetric Difference
  non_stayed  = DIFF(y1_departed, y2_arrived);
  -- Set Equality
  is_equal    = ((COUNT_STAR(non_stayed) == 0L) ? 1 : 0);

  GENERATE year_id, team_id,
    either_year, stayed, y1_departed, y2_arrived, non_stayed, is_equal;
};

-- roster_changes_y2y = FOREACH rosters {
--   either_year  = SetUnion(pl1, pl2);
--   non_stayed_1 = DIFF(pl1, pl2);
--   pl1_o = ORDER pl1 BY player_id;
--   pl2_o = ORDER pl2 BY player_id;
--   stayed      = SetIntersect(pl1_o, pl2_o);
--   y1_departed = SetDifference(pl1_o, pl2_o);
--   y2_arrived  = SetDifference(pl2_o, pl1_o);
--   non_stayed  = DIFF(y1_departed, y2_arrived);
--   is_equal    = ( (COUNT_STAR(non_stayed) == 0L) ? 1 : 0);
--   --
--   n_pl1         = COUNT_STAR(pl1);
--   n_pl2         = COUNT_STAR(pl2);
--   n_union       = COUNT_STAR(either_year);
--   n_intersect   = COUNT_STAR(stayed);
--   n_y1_minus_y2 = COUNT_STAR(y1_departed);
--   n_y2_minus_y1 = COUNT_STAR(y2_arrived);
--   n_xor         = COUNT_STAR(non_stayed);
--   is_equal_via_union     = ( ((n_pl1 == n_pl2) AND (n_union       == n_pl1)) ? 1 : 0);
--   is_equal_via_intersect = ( ((n_pl1 == n_pl2) AND (n_intersect   == n_pl1)) ? 1 : 0);
--   is_equal_via_minus     = ( ((n_pl1 == n_pl2) AND (n_y1_minus_y2 == 0L))    ? 1 : 0);
--   is_equal_via_xor       = ( (n_xor == 0L) ? 1 : 0);
--   -- For your amusement, some invariants that hold for any sets
--   world_makes_sense = AssertUDF( ((
--     is_equal_via_union == is_equal_via_intersect AND
--     is_equal_via_union == is_equal_via_minus     AND
--     is_equal_via_union == is_equal_via_xor       AND
--     (n_union           == n_intersect + n_xor)   AND
--     (n_union           == n_pl1 + n_pl2 - n_intersect) AND
--     (n_xor             == n_y1_minus_y2 + n_y2_minus_y1)
--     ) ? 1 : 0) );
--
--   GENERATE
--     year_id, team_id,
--     n_pl1            AS n_pl1,
--     n_pl2            AS n_pl2,
--     --
--     n_union          AS n_union,
--     n_intersect      AS n_intersect,
--     n_y1_minus_y2    AS n_y1_minus_y2,
--     n_y2_minus_y1    AS n_y2_minus_y1,
--     n_xor            AS n_xor,
--     --
--     either_year      AS either_year,
--     stayed           AS stayed,
--     y1_departed      AS y1_departed,
--     y2_arrived       AS y2_arrived,
--     non_stayed       AS non_stayed,
--     --
--     is_equal_via_xor AS is_equal
--     ;
-- };

roster_changes_y2y = ORDER roster_changes_y2y BY is_equal ASC, team_id, year_id;
STORE_TABLE(roster_changes_y2y, 'roster_changes_y2y');
