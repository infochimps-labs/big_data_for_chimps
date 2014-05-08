-- ===========================================================================
--
-- Season Batting Table
--

SELECT NOW() AS starting_datetime, "Find season batting stats", COUNT(*) AS n_bat from bat_stints;

DROP TABLE IF EXISTS `bat_seasons`;
CREATE TABLE `bat_seasons` (
  `lahman_id`    INT(11)                NOT NULL,
  `player_id`    CHAR(9)                CHARACTER SET ASCII NOT NULL,
  `bbref_id`     CHAR(9)                CHARACTER SET ASCII NOT NULL,
  `retro_id`     CHAR(8)                CHARACTER SET ASCII DEFAULT NULL,
  --
  `name_common`  varchar(100)           default NULL,  -- 5
  `name_first`   varchar(50)            default NULL,
  `name_last`    varchar(50) NOT NULL   default '',
  `age`          SMALLINT(2) UNSIGNED   DEFAULT NULL,
  --
  `year_id`      SMALLINT(3) UNSIGNED   DEFAULT NULL,
  `team_id`      CHAR(3)                DEFAULT NULL,  -- 10
  `lg_id`        CHAR(2)                DEFAULT NULL,
  `team_ids`     VARCHAR(27)            NOT NULL,
  `lg_ids`       VARCHAR(18)            NOT NULL,
  `stintGs`      VARCHAR(18)            NOT NULL,
  `n_stints`     SMALLINT(3) UNSIGNED   DEFAULT NULL,  -- 15
  --
  `G`            INT(5) UNSIGNED        DEFAULT NULL,
  `G_batting`    INT(5) UNSIGNED        DEFAULT NULL,
  `is_allstar`      BOOLEAN                DEFAULT NULL,
  --
  `PA`           INT(5) UNSIGNED        DEFAULT NULL,
  `AB`           INT(5) UNSIGNED        DEFAULT NULL,
  `R`            INT(5) UNSIGNED        DEFAULT NULL,
  `H`            INT(5) UNSIGNED        DEFAULT NULL,
  `h2B`          INT(5) UNSIGNED        DEFAULT NULL,
  `h3B`          INT(5) UNSIGNED        DEFAULT NULL,
  `HR`           INT(5) UNSIGNED        DEFAULT NULL,
  `RBI`          INT(5) UNSIGNED        DEFAULT NULL,
  `SB`           INT(5) UNSIGNED        DEFAULT NULL,
  `CS`           INT(5) UNSIGNED        DEFAULT NULL,
  `BB`           INT(5) UNSIGNED        DEFAULT NULL,
  `SO`           INT(5) UNSIGNED        DEFAULT NULL,
  `IBB`          INT(5) UNSIGNED        DEFAULT NULL,
  `HBP`          INT(5) UNSIGNED        DEFAULT NULL,
  `SH`           INT(5) UNSIGNED        DEFAULT NULL,
  `SF`           INT(5) UNSIGNED        DEFAULT NULL,
  `GIDP`        INT(5) UNSIGNED        DEFAULT NULL,
  -- defensive   interference while batting.
  -- Discrepancies between Baseball Reference our component stats from Baseball Databank mean that you can't trust this number very much
  `CIB`          INT(5)                 DEFAULT NULL,
  --
  `BAVG`         FLOAT                  DEFAULT NULL,
  `TB`           FLOAT                  DEFAULT NULL,
  `SLG`          FLOAT                  DEFAULT NULL,
  `OBP`          FLOAT                  DEFAULT NULL,
  `OPS`          FLOAT                  DEFAULT NULL,
  `ISO`          FLOAT                  DEFAULT NULL,
  --
  `is_pitcher`   BOOLEAN                DEFAULT NULL,
  `RAA`          FLOAT                  DEFAULT NULL,
  `RAA_off`      FLOAT                  DEFAULT NULL,
  `RAA_def`      FLOAT                  DEFAULT NULL,
  `RAR`          FLOAT                  DEFAULT NULL,
  `WAA`          FLOAT                  DEFAULT NULL,
  `WAA_off`      FLOAT                  DEFAULT NULL,
  `WAA_def`      FLOAT                  DEFAULT NULL,
  `WAR`          FLOAT                  DEFAULT NULL,
  `WAR_off`      FLOAT                  DEFAULT NULL,
  `WAR_def`      FLOAT                  DEFAULT NULL,
  --
  PRIMARY KEY             (`lahman_id`, `year_id`),
  UNIQUE KEY  `player`    (`player_id`, `year_id`),
  UNIQUE KEY  `bbref`     (`bbref_id`,  `year_id`),
  KEY         `retro`     (`retro_id`,  `bbref_id`, `year_id`),
  KEY         `year_id`    (`year_id`)
  ) ENGINE=INNODB DEFAULT CHARSET=utf8
;

INSERT INTO `bat_seasons`
  (
    lahman_id, player_id, bbref_id, retro_id, name_first, name_last, name_common,
    year_id, team_ids, lg_ids, stintGs, n_stints,
    G, G_batting,
    is_allstar,
    AB, R, H, h2B, h3B, HR, RBI,
    SB, CS, BB, SO, IBB, HBP,
    SH, SF, GIDP)

  SELECT
    lahman_id, peep.player_id, peep.bbref_id, peep.retro_id, peep.name_first, peep.name_last, peep.name_common,
    bat.year_id,
    GROUP_CONCAT(bat.team_id) AS team_ids, GROUP_CONCAT(bat.lg_id) AS lg_ids,
    GROUP_CONCAT(bat.G) AS stintGs, COUNT(*) AS n_stints,
    SUM(bat.G) AS G, IFNULL(SUM(bat.G_batting),0) AS G_batting,
    IF(ast.player_id IS NOT NULL, TRUE, FALSE) AS is_allstar,
    SUM(AB) AS AB, SUM(R)  AS R,  SUM(H)  AS H,  SUM(h2B) AS h2B, SUM(h3B)  AS h3B,  SUM(HR)  AS HR,  SUM(RBI) AS RBI,
    SUM(SB) AS SB, SUM(CS) AS CS, SUM(BB) AS BB, SUM(SO) AS SO, SUM(IBB) AS IBB, SUM(HBP) AS HBP,
    SUM(SH) AS SH, SUM(SF) AS SF, SUM(GIDP) AS GIDP
  --
  FROM `bat_stints` bat
  JOIN `people` peep
    ON bat.`player_id` = peep.`player_id`
  LEFT JOIN (SELECT DISTINCT player_id, year_id FROM allstars) ast
    ON (bat.`player_id` = ast.`player_id` AND bat.`year_id` = ast.`year_id`)
  GROUP BY player_id, year_id
  ;

--
-- Copy over WAR settings from baseball_reference tables
--
UPDATE `bat_seasons`,
  (SELECT bbref_id, year_id, age, COUNT(*) as n_stints,
    MAX(is_pitcher) AS is_pitcher,
    SUM(PA) AS PA,
    SUM(runs_above_avg) AS RAA, SUM(runs_above_avg_off) AS RAA_off, SUM(runs_above_avg_def) AS RAA_def,
    SUM(runs_above_rep) AS RAR,
    SUM(WAA) AS WAA, SUM(WAA_off) AS WAA_off, SUM(WAA_def) AS WAA_def,
    SUM(WAR) AS WAR, SUM(WAR_off) AS WAR_off, SUM(WAR_def) AS WAR_def
    FROM `bat_war` GROUP BY bbref_id, year_id) wart
  SET
       `bat_seasons`.`age`        = wart.`age`,
       `bat_seasons`.`n_stints`   = wart.`n_stints`,
       `bat_seasons`.`PA`        = wart.`PA`,
       `bat_seasons`.`RAA`       = wart.`RAA`,
       `bat_seasons`.`RAA_off`   = wart.`RAA_off`,
       `bat_seasons`.`RAA_def`   = wart.`RAA_def`,
       `bat_seasons`.`RAR`       = wart.`RAR`,
       `bat_seasons`.`WAA`       = wart.`WAA`,
       `bat_seasons`.`WAA_off`   = wart.`WAA_off`,
       `bat_seasons`.`WAA_def`   = wart.`WAA_def`,
       `bat_seasons`.`WAR`       = wart.`WAR`,
       `bat_seasons`.`WAR_off`   = wart.`WAR_off`,
       `bat_seasons`.`WAR_def`   = wart.`WAR_def`,
       `bat_seasons`.`is_pitcher` = wart.`is_pitcher`
 WHERE (`bat_seasons`.`bbref_id`  = wart.`bbref_id`)
   AND (`bat_seasons`.`year_id`   = wart.`year_id`)
 ;

CREATE TEMPORARY TABLE bat_team (player_id CHAR(9), year_id CHAR(4), team_id CHAR(3), lg_id CHAR(3), PRIMARY KEY (`player_id`, `year_id`));
INSERT INTO bat_team (player_id, year_id, team_id, lg_id)
  SELECT bat.player_id, bat.year_id, bat.team_id, bat.lg_id
    FROM bat_stints bat   
    INNER JOIN (SELECT player_id, year_id, MAX(G) AS Gmax FROM bat_stints bat GROUP BY player_id, year_id) batmax
    ON bat.player_id = batmax.player_id AND bat.year_id = batmax.year_id AND bat.G = batmax.Gmax
    GROUP BY player_id, year_id
  ;
UPDATE bat_seasons bats, bat_team
  SET
    bats.team_id = bat_team.team_id,
    bats.lg_id   = bat_team.lg_id
  WHERE bats.player_id = bat_team.player_id AND bats.year_id = bat_team.year_id
  ;
 
--
-- Calculate derived statistics -- batting average and so forth
--
UPDATE bat_seasons SET
  BAVG  = IF(AB>0,  (H / AB), 0),
  TB    = IF(PA>0,  (H + h2B + 2 * h3B + 3 * HR), 0),
  SLG   = IF(AB>0, ((H + h2B + 2 * h3B + 3 * HR) / AB), 0),
  OBP   = IF(PA>0, ((H + BB + IFNULL(HBP,0))   / PA), 0),
  CIB   = IF(PA>0,  (PA - (AB + BB + IFNULL(HBP,0) + IFNULL(SH,0) + IFNULL(SF,0))), 0)
  ;
UPDATE bat_seasons SET
  OPS   =          (SLG + OBP),
  ISO   = IF(AB>0, ((TB - H) / AB), 0)
  ;
