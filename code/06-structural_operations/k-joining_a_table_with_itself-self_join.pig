IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
IMPORT 'summarizer_bot_9000.pig';

SET pig.auto.local.enabled true
  ;

bat_seasons = load_bat_seasons();
one_line    = load_one_line();

-- ***************************************************************************
--
-- === Joining a Table with Itself (self-join)
--

-- Joining a table with itself is very common when you are analyzing relationships of elements within the table (when analyzing graphs or working with datasets represented as attribute-value lists it becomes predominant.) Our example here will be to identify all teammates pairs: players listed as having played for the same team in the same year. The only annoying part about doing a self-join in Pig is that you can't, at least not directly. Pig won't let you list the same table in multiple slots of a JOIN statement, and also won't let you just write something like `"mytable_dup = mytable;"` to assign a new alias footnote:[If it didn't cause such a surprisingly hairy set of internal complications, it would have long ago been fixed]. Instead you have to use a FOREACH or somesuch to create a duplicate representative. If you don't have any other excuse, use a project-star expression: `p2 = FOREACH p1 GENERATE *;`. In this case, we already need to do a projection; we feel the most readable choice is to repeat the statement twice.

-- -- Pig disallows self-joins so this won't work:
-- wont_work = JOIN bat_seasons BY (team_id, year_id), bat_seasons BY (team_id, year_id);
-- "ERROR ... Pig does not accept same alias as input for JOIN operation : bat_seasons"

-- That's OK, we didn't want all those stupid fields anyway; we'll just make two copies.
p1 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;
    p2 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;

--
-- Now we join the table copies to find all teammate pairs. We're going to say a
-- player isn't their their own teammate, and so we also reject the self-pairs.
--
teammate_pairs = FOREACH (JOIN
    p1 BY (team_id, year_id),
    p2 by (team_id, year_id)
  ) GENERATE
    p1::player_id AS pl1,
    p2::player_id AS pl2;
teammate_pairs = FILTER teammate_pairs BY NOT (pl1 == pl2);

-- The 78,000 player seasons we joined onto the team-parks-years table In
-- contrast, a similar JOIN expression turned 78,000 seasons into 2,292,658
-- player-player pairs, an expansion of nearly thirty times
--
teammates = FOREACH (GROUP teammate_pairs BY pl1) {
  mates = DISTINCT teammate_pairs.pl2;
  GENERATE group AS player_id,
    COUNT_STAR(mates) AS n_mates,
    BagToString(mates,';') AS mates;
  };
teammates = ORDER teammates BY n_mates ASC;

-- (A simplification was made) footnote:[(or, what started as a footnote but should probably become a sidebar or section in the timeseries chapter -- QEM advice please) Our bat_seasons table ignores mid-season trades and only lists a single team the player played the most games for, so in infrequent cases this will identify some teammate pairs that didn't actually overlap. There's no simple option that lets you join on players' intervals of service on a team: joins must be based on testing key equality, and we would need an "overlaps" test. In the time-series chapter you'll meet tools for handling such cases, but it's a big jump in complexity for a small number of renegades. You'd be better off handling it by first listing every stint on a team for each player in a season, with separate fields for the year and for the start/end dates. Doing the self-join on the season (just as we have here) would then give you every _possible_ teammate pair, with some fraction of false pairings. Lastly, use a FILTER to reject the cases where they don't overlap. Any time you're looking at a situation where 5% of records are causing 150% of complexity, look to see whether this approach of "handle the regular case, then fix up the edge cases" can apply.]

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Summary of results
--

stats_info    = FOREACH (GROUP p1 ALL) GENERATE
  COUNT_STAR(p1)             AS n_seasons;
tm_pair_info  = FOREACH (GROUP teammate_pairs ALL) GENERATE
  COUNT_STAR(teammate_pairs) AS n_mates_all;
teammate_info = FOREACH (GROUP teammates      ALL) GENERATE
  COUNT_STAR(teammates)      AS n_players,
  SUM(teammates.n_mates)     AS n_mates_dist;

roster_sizes  = FOREACH (GROUP p1 BY (team_id, year_id)) GENERATE COUNT_STAR(p1) AS n_players;

roster_info   = summarize_numeric(roster_sizes, 'n_players', 'ALL');

-- -- roster_info   = FOREACH (GROUP roster_sizes ALL) GENERATE
-- --   SUM(roster_sizes.n_players) AS n_players,
-- --   AVG(roster_sizes.n_players) AS roster_size_avg,
-- --   SQRT(VAR(roster_sizes.n_players)) AS roster_size_stdv,
-- --   MIN(roster_sizes.n_players) AS roster_size_min,
-- --   MAX(roster_sizes.n_players) AS roster_size_max;
--
-- --
-- -- The one_line.tsv table is a nice trick for accumulating several scalar
-- -- projections.
-- --
-- teammates_summary = FOREACH one_line GENERATE
--   -- 'n_players',   (long)teammate_info.n_players    AS n_players,
--   -- 'n_seasons',   (long)stats_info.n_seasons       AS n_seasons,
--   -- 'n_pairs',     (long)tm_pair_info.n_mates_all   AS n_mates_all,
--   -- 'n_teammates', (long)teammate_info.n_mates_dist AS n_mates_dist,
--   (long)roster_info.minval,
--   (long)roster_info.maxval,
--   (long)roster_info.avgval,
--   (long)roster_info.stddev
--   ;

-- teammate_pairs = FOREACH (JOIN
--     p1 BY (team_id, year_id),
--     p2 by (team_id, year_id)
--   ) GENERATE
--     p1::player_id AS pl1,        p2::player_id AS pl2,
--     p1::team_id   AS p1_team_id, p1::year_id   AS p1_year_id;
-- teammate_pairs = FILTER teammate_pairs BY NOT (pl1 == pl2);
--
-- teammates = FOREACH (GROUP teammate_pairs BY pl1) {
--   years = DISTINCT teammate_pairs.p1_year_id;
--   mates = DISTINCT teammate_pairs.pl2;
--   teams = DISTINCT teammate_pairs.p1_team_id;
--   GENERATE group AS player_id,
--     COUNT_STAR(mates) AS n_mates,    COUNT_STAR(years) AS n_seasons,
--     MIN(years)        AS beg_year,   MAX(years)        AS end_year,
--     BagToString(teams,';') AS teams,
--     BagToString(mates,';') AS mates;
--   };
--
-- teammates = ORDER teammates BY n_mates DESC;

-- STORE_TABLE(teammates, 'teammates');
-- teammates = LOAD_RESULT('teammates');
-- STORE_TABLE(teammates_summary, 'teammates_summary');
-- cat $out_dir/teammates_summary/part-m-00000;
-- -- --
-- -- -- n_players       16151   n_seasons       77939   n_pairs 2292658 n_teammates     1520460
-- -- --
--
-- EXPLAIN teammates_summary;
