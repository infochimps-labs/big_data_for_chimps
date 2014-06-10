IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();


-- ***************************************************************************
--
-- === Set Operations
--
-- * Distinct Union;
-- * Set Intersection
-- * Set Difference
-- * Set Equality
-- * Symmetric Set Difference

-- ==== Constructing a Sequence of Sets

bat_seasons = FILTER bat_seasons BY ( 
  player_id != 'piercan01' AND player_id != 'scottmi01' AND player_id != 'hallge01' AND player_id != 'heifefr01' AND player_id != 'mannija01');


-- Self-Join requires we make new aliases using a dummy projection
y1 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;
y2 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;

-- Put each team of players in context with the next year's team of players
year_to_year_players = COGROUP
  y1 BY (team_id, year_id),
  y2 BY (team_id, year_id-1)
  ;
-- Project away the grouped-on fields
rosters = FOREACH year_to_year_players GENERATE
  group.team_id AS team_id,
  group.year_id AS year_id,
  y1.player_id  AS pl1,
  y2.player_id  AS pl2
  ;
-- Reject the first and last years of existence
rosters = FILTER rosters BY NOT (IsEmpty(pl1) OR IsEmpty(pl2));

-- ==== Set operations within group

--
-- `rosters` is now a table with two key columns -- team and year -- and two
-- bags representing the set of players from that year and the set of players
-- from the following year.
--
-- We can
--

roster_changes_y2y = FOREACH rosters {

  -- Distinct Union: the players in each two-year span (given year or the next). SetUnion accepts two or more bags:
  either_year  = SetUnion(pl1, pl2);

  -- the other set operations require sorted inputs. Keep in mind that an ORDER BY within the nested block of a FOREACH (GROUP BY) is efficient, as it makes use of the secondary sort Hadoop provides.
  pl1_o = ORDER pl1 BY player_id;
  pl2_o = ORDER pl2 BY player_id;

  -- Intersect (A intersect B): for each team-year, the players that stayed for the next year (given year and the next). Requires sorted input. With
  stayed      = SetIntersect(pl1_o, pl2_o);

  -- Difference (A minus B): for each team-year, the players that did not stay for next year (A minus B). Requires sorted input. With multiple bags of input, the result is everything that is in the first but not in any other set.
  y1_departed = SetDifference(pl1_o, pl2_o);
  y2_arrived  = SetDifference(pl2_o, pl1_o);

  -- Symmetric Difference: for each team-year, the players that did not stay for next year.
  -- Find this using either (A minus B) union (B minus A) or ((A union B) minus
  -- (A intersect B))
  non_stayed  = SetUnion(y1_departed, y2_arrived);

  -- Set Equality: for each team-year, were the players the same?  There's no
  -- direct function for set equality, but you can repurpose any of the set
  -- operations to serve.
  --
  -- If A and B each have no duplicate records, then A and B are equal if and only if
  --
  -- * `size(A) == size(B) AND size(A union B) == size(A)`
  -- * `size(A) == size(B) AND size(A intersect B) == size(A)`
  -- * `size(A) == size(B) AND size(A minus B) == 0`
  -- * `size(symmetric difference(A,B)) == 0`
  --
  -- If you're already calculating one of the functions, use the test that
  -- reuses its result. Otherwise, prefer the A minus B test if most rows will
  -- have equal sets, and the A intersect B test if most will not.
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
  is_equal_via_minus     = ( ((n_pl1 == n_pl2) AND (n_y1_minus_y2 == 0))     ? 1 : 0);
  is_equal_via_xor       = ( (n_xor == 0) ? 1 : 0);

  world_makes_sense = AssertUDF( ((
    is_equal_via_union == is_equal_via_intersect AND
    is_equal_via_union == is_equal_via_minus     AND
    is_equal_via_union == is_equal_via_xor       AND
    (n_union           == n_intersect + n_xor)   AND
    (n_xor             == n_y1_minus_y2 + n_y2_minus_y1)
    ) ? 1 : 0) );

  
  GENERATE
    year_id, team_id,
    n_pl1         AS n_pl1,
    n_pl2         AS n_pl2,
    n_union       AS n_union,
    n_intersect   AS n_intersect,
    n_y1_minus_y2 AS n_y1_minus_y2,
    n_y2_minus_y1 AS n_y2_minus_y1,
    n_xor         AS n_xor,
    --
    -- either_year   AS either_year,
    -- stayed        AS stayed,
    -- y1_departed   AS y1_departed,
    -- y2_arrived    AS y2_arrived,
    non_stayed    AS non_stayed,
    n_union - n_intersect AS n_xor_2,
    is_equal_via_xor AS is_equal,
    world_makes_sense
    ;
};

--
-- ==== Exercise
--
-- Implement a set equality UDF and submit it as an open-source contribution to
-- the DataFu project. This should check immediately that the two sets have the
-- same size, and them proceed to 

roster_changes_y2y = ORDER roster_changes_y2y BY
  is_equal ASC, world_makes_sense DESC,
  n_xor DESC, n_intersect DESC, n_union DESC, year_id, team_id;
DUMP roster_changes_y2y;
