-- ===========================================================================
--
-- Dump (slightly) simplified records for Big Data for Chimps sample code
--
-- ===========================================================================

-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Dumping player team and park statistics into /data/rawd/sports/baseball/retrosheet/\*.tsv: should take only a second or so';

SELECT * FROM `lahman`.`allstars`        ORDER BY year_id, player_id  INTO OUTFILE '/data/rawd/sports/baseball/allstars.tsv';
SELECT * FROM `lahman`.`bat_seasons`     ORDER BY player_id, year_id  INTO OUTFILE '/data/rawd/sports/baseball/bat_seasons-full.tsv';
SELECT * FROM `lahman`.`teams`           ORDER BY team_id, year_id    INTO OUTFILE '/data/rawd/sports/baseball/teams.tsv';
SELECT * FROM `lahman`.`park_team_years` ORDER BY year_id, park_id    INTO OUTFILE '/data/rawd/sports/baseball/park_team_years.tsv';
SELECT * FROM `lahman`.`parks`           ORDER BY park_id             INTO OUTFILE '/data/rawd/sports/baseball/parks.tsv';
SELECT * FROM `lahman`.`franchises`      ORDER BY franch_id           INTO OUTFILE '/data/rawd/sports/baseball/franchises.tsv';

SELECT * FROM `lahman`.`numbers`   WHERE num <= 1000000 ORDER BY num INTO OUTFILE '/data/rawd/stats/numbers/numbers-1M.tsv';
SELECT * FROM `lahman`.`numbers`   WHERE num <= 100000  ORDER BY num INTO OUTFILE '/data/rawd/stats/numbers/numbers-100k.tsv';
SELECT * FROM `lahman`.`numbers`   WHERE num <= 10000   ORDER BY num INTO OUTFILE '/data/rawd/stats/numbers/numbers-10k.tsv';
SELECT num FROM `lahman`.`numbers` LIMIT 1                           INTO OUTFILE '/data/rawd/stats/numbers/one.tsv';


SELECT  park_id, park_name, beg_date, end_date, is_active, n_games, lng, lat, city, `state`, `country`
  FROM `lahman`.`parks`
  ORDER BY park_id
  INTO OUTFILE '/data/rawd/sports/baseball/parks.tsv';

SELECT
  `player_id`,
   `birth_year`, `birth_month`, `birth_day`, `birth_city`, `birth_state`, `birth_country`, 
   `death_year`, `death_month`, `death_day`, `death_city`, `death_state`, `death_country`, 
   `name_first`, `name_last`, `name_given`,
   `height`, `weight`, `bats`, `throws`,
   `first_game`, `final_game`, `college`,
   `retro_id`, `bbref_id`
  FROM `lahman`.`people` WHERE player_id IS NOT NULL
  ORDER BY IF(player_id IS NULL, 1, 0), player_id, retro_id, lahman_id
  INTO OUTFILE '/data/rawd/sports/baseball/people.tsv';

-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Dumping simplified batting stats into /data/rawd/sports/baseball/retrosheet/bats_lite.tsv: should take a second or so';

-- baseball ref vs us
-- us:  age G  PA  AB HBP SH BB H  1B 2B 3B HR R  RBI    OBP SLG
-- bbr: age G  PA  AB     R     H     2B 3B HR    RBI BB OBP SLG HBP SH

SELECT
    player_id, name_first, name_last,
    year_id, team_id, lg_id,
    age, G, PA, AB,
    @HBP := IFNULL(HBP, 0)       AS HBP,
    @SH  := IFNULL(SH,  0)       AS SH,
    BB, H,
    @h1B := (H - h2B - h3B - HR) AS h1B,
    h2B, h3B, HR,
    R, RBI
    -- , @OBP := (H + BB + @HBP)/PA   AS OBP,
    -- @SLG := ((@h1B + 2*h2B + 3*h3B + 4*HR)/AB)  AS SLG
  FROM `lahman`.`bat_seasons`
  WHERE PA > 0 AND AB > 0
  ORDER BY player_id, year_id
  INTO OUTFILE '/data/rawd/sports/baseball/bat_seasons.tsv'
  ;

-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Dumping simplified games into /data/rawd/sports/baseball/retrosheet/games_lite.tsv: should take a second or so';

SELECT game_id, year_id, away_team_id, home_team_id, away_runs_ct, home_runs_ct
  FROM retrosheet.games
  ORDER BY game_id
  INTO OUTFILE '/data/rawd/sports/baseball/games_lite.tsv'
  ;


-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Dumping full game logs into /data/rawd/sports/baseball/retrosheet/games_lite.tsv: should take several seconds';

SELECT  *
  FROM `retrosheet`.`games`
  ORDER BY year_id, game_id
  INTO OUTFILE '/data/rawd/sports/baseball/games.tsv';
  

-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Dumping simplified events into /data/rawd/sports/baseball/retrosheet/events_lite.tsv: should take about a minute';

SELECT *
  FROM `retrosheet`.`events_lite`
  ORDER BY year_id DESC, game_id ASC, event_seq ASC
  INTO OUTFILE '/data/rawd/sports/baseball/events_lite.tsv'
  ;

-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Dumping Hall of Fame';

DROP TEMPORARY TABLE IF EXISTS hof_dump;
CREATE TEMPORARY TABLE hof_dump (
  SELECT
    hof.player_id,
    MAX(IF(hof.inducted = "Y",
      CASE hof.voted_by
          WHEN 'BBWAA' THEN 'BBWAA' WHEN 'Special Election' THEN 'Special' WHEN 'Veterans' THEN 'vc' WHEN 'Nominating Vote' THEN 'nv' WHEN 'Centennial' THEN 'ce'
          WHEN 'Final Ballot' THEN 'fb' WHEN 'Negro League' THEN 'nl' WHEN 'Old Timers' THEN 'ot' WHEN 'Run Off' THEN 'ro' ELSE hof.voted_by END, ''))
                                                            AS inducted_by,
    MAX(IF(hof.inducted = "Y", 1, 0))                       AS is_inducted,
    MAX(IF(year_id = 2014 AND (votes/ballots >= 0.05) AND (hof.inducted != "Y"), 1, 0)) AS is_pending,
    MAX(IF(voted_by='BBWAA',ROUND(100*votes/ballots),NULL)) AS max_pct,
    SUM(IF(voted_by='BBWAA',1,0))                           AS n_ballots,
    0                                                       AS hof_score,
    MIN(year_id)                                            AS year_eligible,
    MAX(IF(hof.inducted = "Y", year_id, ''))                AS year_inducted,
    -- batc.G, batc.PA, batc.WAR, batc.WAR_off, batc.H, batc.HR, batc.OBP, batc.SLG, batc.OPS, batc.Y_allstar,
    -- IF(MAX(hof.inducted)='Y', COUNT(*), -MAX(votes/ballots)) AS wt
    IFNULL(GROUP_CONCAT(IF(voted_by='BBWAA', ROUND(100*votes/ballots),NULL) ORDER BY year_id ASC SEPARATOR '|'),'') AS pcts
  FROM   halloffame  hof
  JOIN   comb_career batc ON (batc.player_id = hof.player_id)
  WHERE (hof.category = 'Player')
    AND (IFNULL(WAR_pit,0) < IFNULL(WAR_off,0))
  GROUP BY player_id
  ORDER BY is_pending DESC, WAR DESC, is_inducted DESC
);
ALTER TABLE hof_dump ADD UNIQUE KEY `player` (`player_id`);

UPDATE hof_dump
 SET hof_score = CASE
      WHEN (inducted_by = 'Special') THEN 1150                       -- 1150:      comparable to a first-ballot with 90% approval (~ Frank Robinson)
      WHEN (inducted_by = 'BBWAA')
       AND (n_ballots = 1)           THEN 250 + 10*max_pct           -- 1000-1200: only first-ballot can exceed 1000
      WHEN (inducted_by = 'BBWAA')   THEN 1000 - 50*(n_ballots-1)    --  300- 900: players inducted by writers range from 300 (Sam Rice) to 950 (second ballot)
      WHEN (inducted_by = 'ot')      THEN  300                       --  300:      old-timers committee inductees
      WHEN (inducted_by = 'vc')      THEN  150 + 2*IFNULL(max_pct,0) --  150- 300: veterans committee inductees
      WHEN (is_inducted = 1)         THEN  150                       --  150:      all other inductees
      WHEN (is_pending AND max_pct > 15) THEN 3 * max_pct            --   45-220:  anyone currently eligible and not yet in; apart from Gil Hodges, no player has crossed 50% vote share and failed to receive induction
      ELSE  max_pct END
 ;
-- SELECT ROUND((WAR-30)/4) AS WARbin, hof_score, n_ballots, max_pct, name_first, name_last, beg_year, end_year, hof_dump.* FROM hof_dump JOIN comb_career batc ON (batc.player_id = hof_dump.player_id) ORDER BY hof_score DESC, WAR DESC, beg_year, hof_score DESC, year_inducted;

SELECT * FROM hof_dump
  ORDER BY hof_score DESC
  INTO OUTFILE '/DATA/rawd/sports/baseball/hof_bat.tsv';

-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Dumping Awards';

SELECT aws.award_id, aws.year_id, aws.lg_id, aws.player_id,
    IF(awd.player_id IS NOT NULL, 1, 0)            AS is_winner,
    ROUND(100*points_won/points_max, 1)            AS vote_pct,
    ROUND(100*IFNULL(votes_first,0)/awg.vf_tot, 1) AS firstpl_pct,
    -- points_won, votes_first, points_max,
    n_firstv                                       AS n_firstv,
    IF(awd.tie = 'Y', 1, 0)                        AS tie
    -- IFNULL(awd.notes, '')                       AS notes
  FROM       awardsshareplayers aws
  LEFT JOIN  awardsplayers      awd
    ON (aws.lg_id = awd.lg_id) AND (aws.year_id = awd.year_id) AND (aws.award_id = awd.award_id) AND (aws.player_id = awd.player_id)
  LEFT JOIN  (SELECT award_id, year_id, lg_id, player_id, SUM(IFNULL(votes_first,0)) AS vf_tot, SUM(IF(votes_first > 0, 1, 0)) AS n_firstv
      FROM awardsshareplayers GROUP BY award_id, year_id, lg_id) awg
    ON (aws.lg_id = awg.lg_id) AND (aws.year_id = awg.year_id) AND (aws.award_id = awg.award_id)
  ORDER BY award_id, year_id DESC, lg_id, is_winner DESC, vote_pct DESC
  INTO  OUTFILE '/data/rawd/sports/baseball/awards.tsv'
  ;

-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Done dumping tables';
