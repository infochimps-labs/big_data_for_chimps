IMPORT 'common_macros.pig';
%DEFAULT rawd    '/data/rawd';
%DEFAULT out_dir '/data/out/baseball';

-- tc_cities = LOAD '$rawd/geo/census/us_city_pops.tsv' AS (city:chararray, state:chararray, pop_2011:int);
-- 
-- parks = load_parks();
-- parks  = FILTER parks BY n_games > 50;
-- bb_cities = FOREACH parks GENERATE park_id, city;
-- 
-- combined = COGROUP tc_cities BY city, bb_cities BY city;
-- 
-- tc_or_bb    = FOREACH combined GENERATE group AS city;
-- tc_and_bb   = FOREACH (FILTER combined BY (NOT IsEmpty(tc_cities)) AND (NOT IsEmpty(bb_cities))) GENERATE group AS city;
-- tc_minus_bb = FOREACH (FILTER combined BY (IsEmpty(bb_cities)))                                  GENERATE group AS city;
-- bb_minus_tc = FOREACH (FILTER combined BY (IsEmpty(tc_cities)))                                  GENERATE group AS city;
-- tc_xor_bb   = FOREACH (FILTER combined BY (IsEmpty(tc_cities)) OR (IsEmpty(bb_cities)))          GENERATE group AS city;
-- 
-- DUMP tc_and_bb;
-- DUMP tc_minus_bb;
-- DUMP bb_minus_tc;

bats = load_bat_seasons();
bats = FILTER bats BY
  (G >= 80 OR PA >= 300)
  -- (G >= 30 OR PA >= 100)
  -- AND year_id >= 2010 AND team_id == 'BOS'
  ;

y1      = FOREACH bats GENERATE player_id, team_id, year_id, G, PA;
y2      = FOREACH bats GENERATE player_id, team_id, year_id, G, PA;
rosters = FOREACH (COGROUP y1 BY (team_id, year_id), y2 BY (team_id, year_id-1)) GENERATE
    group.team_id AS team_id, group.year_id AS year_id, 
    y1.player_id AS pl1, y2.player_id AS pl2
      ;

-- DUMP rosters;

rosters = FILTER rosters BY NOT (IsEmpty(pl1) OR IsEmpty(pl2));
roster_changes_y2y = FOREACH rosters {
  
  -- Distinct Union: the players in each two-year span (given year or the next). SetUnion accepts two or more bags:
  either_year   = SetUnion(pl1, pl2);
  
  -- the other set operations require sorted inputs. Keep in mind that an ORDER BY within the nested block of a FOREACH (GROUP BY) is efficient, as it makes use of the secondary sort Hadoop provides.
  opl1 = ORDER pl1 BY player_id;
  opl2 = ORDER pl2 BY player_id;
  
  -- Intersect: for each team-year, the players that stayed for the next year (given year and the next). Requires sorted input. With 
  both_years    = SetIntersect(opl1, opl2);
    
  -- Difference: for each team-year, the players that did not stay for next year (A minus B). Requires sorted input. With multiple bags of input, the result is everything that is in the first but not in any other set.
  y1_left  = SetDifference(opl1, opl2);
  y2_came  = SetDifference(opl2, opl1);

  -- Symmetric Difference: for each team-year, the players that did not stay for next year (A minus B) plus (B minus A)
  non_both       = SetUnion(SetDifference(opl1,opl2), SetDifference(opl2,opl1));
  -- TODO is there nothing better?
  
  -- Set Equality: for each team-year, were the players the same?
  -- is_unchanged =
  -- if a has no dupes then the elements of a == elements of b if and only if (size(a intersect b) == size(a) == size(b));
  -- if a has no dupes then the elements of a == elements of b if and only if (size(a minus b) = 0 AND (size(a) == size(b)))
  
  GENERATE
    year_id, team_id,
    SIZE(pl1)                     AS n_pl1,
    SIZE(pl2)                     AS n_pl2,
    SIZE(either_year)             AS n_union,
    SIZE(both_years)              AS n_intersect,
    SIZE(y1_left)                 AS n_left,
    SIZE(y2_came)                 AS n_came,
    SIZE(non_both)                AS n_xor,
    -- either_year,
    -- both_years,
    y1_left,
    y2_came,
    -- non_both,
    (SIZE(non_both) == 0 ? 1 : 0) AS is_equal
    ;
  };

roster_changes_y2y = ORDER roster_changes_y2y BY n_xor DESC, n_left DESC, n_came DESC, year_id ASC;
DUMP roster_changes_y2y;
