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

-- QEM: needs prose (perhaps able to draw from prose file)

--
-- We have to generate two table copies since Pig doesn't allow a pure self-join
-- (it screws up its ability to analyze the 'logical plan' of
-- operations). That's OK, we didn't want all those stupid fields anyway.
p1 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;
p2 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;

-- -- This won't work:
-- wont_work = JOIN bat_seasons BY (team_id, year_id), bat_seasons BY (team_id, year_id);
-- "ERROR ... Pig does not accept same alias as input for JOIN operation : bat_seasons"

--
-- Now we can join the 
--

teammate_pairs = FOREACH (JOIN
    p1 BY (team_id, year_id),
    p2 by (team_id, year_id)
  ) GENERATE
    p1::player_id AS pl1,
    p2::player_id AS pl2;
teammate_pairs = FILTER teammate_pairs BY NOT (pl1 == pl2);

--
-- Consulting the 155878
-- 

teammates = FOREACH (GROUP teammate_pairs BY pl1) {
  mates = DISTINCT teammate_pairs.pl2;
  GENERATE group AS player_id,
    COUNT_STAR(mates) AS n_mates,
    BagToString(mates,';') AS mates;
  };
teammates = ORDER teammates BY n_mates ASC;

-- STORE_TABLE(teammates, 'teammates');
-- teammates = LOAD_RESULT('teammates');

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- SQL Equivalent:
--
-- SELECT DISTINCT b1.player_id, b2.player_id
--   FROM bat_season b1, bat_season b2
--   WHERE b1.team_id = b2.team_id          -- same team
--     AND b1.year_id = b2.year_id          -- same season
--     AND b1.player_id != b2.player_id     -- reject self-teammates
--   GROUP BY b1.player_id
--   ;

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
-- STORE_TABLE(teammates_summary, 'teammates_summary');
-- cat $out_dir/teammates_summary/part-m-00000;
-- -- --
-- -- -- n_players       16151   n_seasons       77939   n_pairs 2292658 n_teammates     1520460
-- -- --
-- 
-- EXPLAIN teammates_summary;

-- The 78,000 player seasons we joined onto the team-parks-years table In
-- contrast, a similar JOIN expression turned 78,000 seasons into 2,292,658
-- player-player pairs, an expansion of nearly thirty times. (Which is  you'd expect given 


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
