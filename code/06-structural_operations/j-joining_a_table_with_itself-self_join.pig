IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
one_line    = load_one_line();

-- ***************************************************************************
--
-- === Joining a Table with Itself (self-join)
--

-- We have to generate two table copies -- Pig doesn't like a pure self-join
p1 = FOREACH bat_seasons GENERATE player_id, team_id, year_id, name_first, name_last;
p2 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;

teammate_pairs = FOREACH (JOIN p1 BY (team_id, year_id), p2 by (team_id, year_id)) GENERATE
  p1::player_id AS pl1,        p2::player_id AS pl2,
  p1::team_id   AS p1_team_id, p1::year_id   AS p1_year_id;
teammate_pairs = FILTER teammate_pairs BY NOT (pl1 == pl2);

teammates = FOREACH (GROUP teammate_pairs BY pl1) {
  years = DISTINCT teammate_pairs.p1_year_id;
  mates = DISTINCT teammate_pairs.pl2;
  teams = DISTINCT teammate_pairs.p1_team_id;
  GENERATE group AS player_id, 
    COUNT_STAR(mates) AS n_mates,    COUNT_STAR(years) AS n_seasons,
    MIN(years)        AS beg_year,   MAX(years)        AS end_year, 
    BagToString(teams,';') AS teams,
    BagToString(mates,';') AS mates;
  };

teammates = ORDER teammates BY n_mates DESC;

-- STORE_TABLE(teammates, 'teammates');


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

teammates = LOAD_RESULT('teammates');

tm_pair_stats  = FOREACH (GROUP teammate_pairs ALL) GENERATE
  COUNT_STAR(teammate_pairs) AS n_pairs;
teammate_stats = FOREACH (GROUP teammates      ALL) GENERATE
  COUNT_STAR(teammates)      AS n_players,
  SUM(teammates.n_mates)     AS n_teammates;

--
-- The one_line.tsv table is a nice trick for accumulating several scalar
-- projections.
--
summary = FOREACH one_line GENERATE
  'n_pairs',     (long)tm_pair_stats.n_pairs      AS n_pairs,
  'n_players',   (long)teammate_stats.n_players   AS n_players,
  'n_teammates', (long)teammate_stats.n_teammates AS n_teammates
  ;

STORE_TABLE(summary, 'summary');
cat $out_dir/summary;

