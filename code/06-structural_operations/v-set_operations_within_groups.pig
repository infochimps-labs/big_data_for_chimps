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
--
-- Other applications of the procedure we follow here would include analyzing
-- how the top-10 products on a website change over time, or identifying sensors
-- that report values over threshold in N consecutive hours (by using an N-way
-- COGROUP).
--

-- ==== Constructing a Sequence of Sets

-- To construct a sequence of sets, perform a self-cogroup that collects the
-- elements from each sequence key into one bag and the elements from the next
-- key into another bag. Here, we group together the roster of players for a
-- team's season (that is, players with a particular `team_id` and `year_id`)
-- together with the roster of players from the following season (players with
-- the same `team_id` and the subsequent `year_id`).

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

-- ==== Set operations within group

-- The content of `rosters` is a table with two key columns: team and year; and
-- two bags: the set of players from that year and the set of players from the
-- following year.
--
-- Applying the set operations lets us describe the evolution of the team from
-- year to year:
--

roster_changes_y2y = FOREACH rosters {

  -- The Distinct Union (A union B, which we'll find using the DataFu `SetUnion`
  -- UDF) describes players on the roster in either year of our two-year span.
  --
  either_year  = SetUnion(pl1, pl2);

  --
  -- All the DataFu set operations here tolerate inputs containing duplicates,
  -- and all of them return bags that contain no duplicates. They also each
  -- accept two or more bags, enabling you to track sequences longer than two
  -- adjacent elements.
  --
  -- As opposed to SetUnion, the other set operations require sorted
  -- inputs. That's not as big a deal as if we were operating on a full table,
  -- since a nested ORDER BY makes use of Hadoop's secondary sort. As long as
  -- the input and output bags fit efficiently in memory, these operations are
  -- efficient.
  pl1_o = ORDER pl1 BY player_id;
  pl2_o = ORDER pl2 BY player_id;

  -- The Set Intersection (A intersect B, which we'll find using the DataFu
  -- SetIntersect UDF) describes the players that played in the first year and
  -- also stayed to play in the second year.
  stayed      = SetIntersect(pl1_o, pl2_o);

  -- The Set Difference (A minus B, using the SetDifference UDF) contains the
  -- elements in the first bag that are not present in the remaining bags.  The
  -- first line therefore describes players that did _not_ stay for the next
  -- year, and the second describes players that newly arrived in the next year.
  y1_departed = SetDifference(pl1_o, pl2_o);
  y2_arrived  = SetDifference(pl2_o, pl1_o);

  -- The Symmetric Difference contains all elements that are in one set or the
  -- other but not both.  You can find this using either `(A minus B) union (B
  -- minus A)` -- players who either departed after the first year or newly
  -- arrived in the next year -- or `((A union B) minus (A intersect B))` --
  -- players who were present in either season but not both seasons.
  non_stayed  = SetUnion(y1_departed, y2_arrived);

  -- Set Equality indicates whether the elements of each set are identical --
  -- here, it selects seasons where the core set of players remained the
  -- same. There's no direct function for set equality, but you can repurpose
  -- any of the set operations to serve.
  --
  -- If A and B each have no duplicate records, then A and B are equal if and only if
  --
  -- * `size(A) == size(B) AND size(A union B) == size(A)`
  -- * `size(A) == size(B) AND size(A intersect B) == size(A)`
  -- * `size(A) == size(B) AND size(A minus B) == 0`
  -- * `size(symmetric difference(A,B)) == 0`
  --
  -- For multiple sets of distinct elements, `A, B, C...` are equal if and only
  -- if all the sets and their intersection have the same size:
  -- `size(intersect(A,B,C,...)) == size(A) == size(B) == size(C) == ...`
  --
  -- If you're already calculating one of the functions, use the test that
  -- reuses its result. Otherwise, prefer the A minus B test if most rows will
  -- have equal sets, and the A intersect B test if most will not or if there
  -- are multiple sets.
  --

  n_pl1         = SIZE(pl1);
  n_pl2         = SIZE(pl2);
  n_union       = SIZE(either_year);
  n_intersect   = SIZE(stayed);
  n_y1_minus_y2 = SIZE(y1_departed);
  n_y2_minus_y1 = SIZE(y2_arrived);
  n_xor         = SIZE(non_stayed);
  is_equal_via_union     = ( ((n_pl1 == n_pl2) AND (n_union       == n_pl1)) ? 1 : 0);
  is_equal_via_intersect = ( ((n_pl1 == n_pl2) AND (n_intersect   == n_pl1)) ? 1 : 0);
  is_equal_via_minus     = ( ((n_pl1 == n_pl2) AND (n_y1_minus_y2 == 0L))    ? 1 : 0);
  is_equal_via_xor       = ( (n_xor == 0L) ? 1 : 0);

  -- -- (omit from book)
  -- -- For your amusement, some invariants that hold for any sets
  -- world_makes_sense = AssertUDF( ((
  --   is_equal_via_union == is_equal_via_intersect AND
  --   is_equal_via_union == is_equal_via_minus     AND
  --   is_equal_via_union == is_equal_via_xor       AND
  --   (n_union           == n_intersect + n_xor)   AND
  --   (n_union           == n_pl1 + n_pl2 - n_intersect) AND
  --   (n_xor             == n_y1_minus_y2 + n_y2_minus_y1)
  --   ) ? 1 : 0) );

  GENERATE
    year_id, team_id,
    n_pl1            AS n_pl1,
    n_pl2            AS n_pl2,
    --
    n_union          AS n_union,
    n_intersect      AS n_intersect,
    n_y1_minus_y2    AS n_y1_minus_y2,
    n_y2_minus_y1    AS n_y2_minus_y1,
    n_xor            AS n_xor,
    --
    either_year      AS either_year,
    stayed           AS stayed,
    y1_departed      AS y1_departed,
    y2_arrived       AS y2_arrived,
    non_stayed       AS non_stayed,
    --
    is_equal_via_xor AS is_equal
    ;
};

roster_changes_y2y = ORDER roster_changes_y2y BY is_equal ASC, team_id, year_id;
STORE_TABLE(roster_changes_y2y, 'roster_changes_y2y');

--
-- ==== Exercises
--
-- * Implement a set equality UDF and submit it as an open-source contribution to
--   the DataFu project. Suggestions:
--
--   - Modify the datafu.pig.sets.SetIntersect UDF to return boolean false
--   - It should return immediately on finding an element that does not lie
--     within the intersection.
--   - Set the contract to require that each input bag is distinct (contains no
--     duplicate elements). This will let you quickly reject as not equal any
--     bags of different size.
--
-- * Modify the set operations UDFs to meet the accumulator interface (see
--   chapter on Advanced Pig for details)
--
-- * Using the waxy.org web logs dataset, identify how the top 10 pages by
--   visits change over time.
--
-- * Identify possibly abusive visitors in the waxy.org web logs:
--   - Calculate the amount of data transferred to each IP address in each
--     six-hour period
--   - Select heavy downloaders using either the z-score or percentile ranking
--     of their data volume, as described in the "identifying outliers" section.
--   - Use the procedure in the "set operations within groups" section to find
--     IP addresses that exceed your heavy-downloader threshold for four
--     consecutive six-hour blocks.
--   This sequence of actions is particularly useful for analysis of security or
--   sensor logs, where you are looking for things that are over threshold for
--   extended durations but not enough to trigger alarms.
