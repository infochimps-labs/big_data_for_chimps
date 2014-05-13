-- ===========================================================================
--
-- Career Batting Table
--

SELECT NOW() AS starting_datetime, "Find career batting stats";

DROP TABLE IF EXISTS `bat_career`;
CREATE TABLE `bat_career` (
  `lahman_id`    int(11)                DEFAULT NULL,
  `player_id`    varchar(10)            CHARACTER SET ascii DEFAULT NULL,
  `bbref_id`     varchar(9)             CHARACTER SET ascii DEFAULT NULL,
  `retro_id`     varchar(9)             CHARACTER SET ascii DEFAULT NULL,
  --
  `name_common`  varchar(100)         DEFAULT NULL,
  `name_first`   varchar(50)          DEFAULT NULL,
  `name_last`    varchar(50)          NOT NULL   DEFAULT '',
  `height`       INT(3)              DEFAULT NULL,
  `weight`       INT(3)              DEFAULT NULL,
  --
  `years`        smallint(3) unsigned DEFAULT NULL,
  `beg_year`     int(4)               DEFAULT NULL,
  `end_year`     int(4)               DEFAULT NULL,
  `hof_year`     smallint(4)          DEFAULT NULL,
  `votedBy`      varchar(64)          DEFAULT NULL,
  --
  `G`            int(5) unsigned      DEFAULT NULL,
  `G_batting`    int(5) unsigned      DEFAULT NULL,
  `Y_allstar`    int(5) unsigned      DEFAULT NULL,
  --
  `PA`           int(5) unsigned      DEFAULT NULL,
  `AB`           int(5) unsigned      DEFAULT NULL,
  `R`            int(5) unsigned      DEFAULT NULL,
  `H`            int(5) unsigned      DEFAULT NULL,
  `h2B`          int(5) unsigned      DEFAULT NULL,
  `h3B`          int(5) unsigned      DEFAULT NULL,
  `HR`           int(5) unsigned      DEFAULT NULL,
  `RBI`          int(5) unsigned      DEFAULT NULL,
  `SB`           int(5) unsigned      DEFAULT NULL,
  `CS`           int(5) unsigned      DEFAULT NULL,
  `BB`           int(5) unsigned      DEFAULT NULL,
  `SO`           int(5) unsigned      DEFAULT NULL,
  `IBB`          int(5) unsigned      DEFAULT NULL,
  `HBP`          int(5) unsigned      DEFAULT NULL,
  `SH`           int(5) unsigned      DEFAULT NULL,
  `SF`           int(5) unsigned      DEFAULT NULL,
  `GIDP`         int(5) unsigned      DEFAULT NULL,
  `CIB`          int(5)               DEFAULT NULL, -- catcher's interference while batting
  --
  `BAVG`         float                DEFAULT NULL,
  `TB`           float                DEFAULT NULL,
  `SLG`          float                DEFAULT NULL,
  `OBP`          float                DEFAULT NULL,
  `OPS`          float                DEFAULT NULL,
  `ISO`          float                DEFAULT NULL,
  --
  `is_pitcher`   BOOLEAN              DEFAULT NULL,
  `RAA`          float                DEFAULT NULL,
  `RAA_off`      float                DEFAULT NULL,
  `RAA_def`      float                DEFAULT NULL,
  `RAR`          float                DEFAULT NULL,
  `WAA`          float                DEFAULT NULL,
  `WAA_off`      float                DEFAULT NULL,
  `WAA_def`      float                DEFAULT NULL,
  `WAR`          float                DEFAULT NULL,
  `WAR_off`      float                DEFAULT NULL,
  `WAR_def`      float                DEFAULT NULL,
  --
  PRIMARY KEY             (`lahman_id`),
  UNIQUE KEY `player_id`   (`player_id`),
  UNIQUE KEY `bbref_id`    (`bbref_id`),
  UNIQUE KEY `retro_id`    (`retro_id`,`bbref_id`)
  ) ENGINE=InnoDB                     DEFAULT CHARSET=utf8
;

REPLACE INTO bat_career
  (lahman_id, player_id, bbref_id, retro_id,
    name_common, name_first, name_last, height, weight,
    years, beg_year, end_year,
    hof_year, votedBy,
    G, G_batting, Y_allstar,
    AB, R, H, h2B, h3B, HR, RBI,
    SB, CS, BB, SO, IBB, HBP,
    SH, SF, GIDP)

  SELECT
    lahman_id, bat.player_id, bbref_id, retro_id,
    peep.name_common, name_first, name_last, height, weight,
    COUNT(DISTINCT bat.year_id) AS years, MIN(bat.year_id) AS beg_year,  MAX(bat.year_id) AS end_year,
    hof.year_id AS hof_year, votedBy,
    SUM(bat.G) AS G,  IFNULL(SUM(bat.G_batting),0) AS G_batting, IFNULL(ast.Y_allstar,0) AS Y_allstar,
    SUM(AB)    AS AB, SUM(R)  AS R,  SUM(H)  AS H,  SUM(h2B) AS h2B, SUM(h3B)  AS h3B,  SUM(HR)  AS HR,  SUM(RBI) AS RBI,
    SUM(SB)    AS SB, SUM(CS) AS CS, SUM(BB) AS BB, SUM(SO) AS SO, SUM(IBB) AS IBB, SUM(HBP) AS HBP,
    SUM(SH)    AS SH, SUM(SF) AS SF, SUM(GIDP) AS  GIDP
  --
  FROM bat_stints bat
  JOIN `people` peep
    ON bat.`player_id` = peep.`player_id`
  LEFT JOIN (
    SELECT player_id, count(DISTINCT year_id) AS Y_allstar FROM allstars ast
      GROUP BY player_id ) ast
    ON bat.`player_id` = ast.`player_id`
  LEFT JOIN `halloffame` hof
    ON (peep.`hof_id` = hof.`hof_id`) AND (inducted = 'Y') AND (hof.category = 'Player')
  GROUP BY player_id
;

--
-- Copy over WAR settings from baseball_reference tables
--
UPDATE `bat_career`,
  (SELECT bbref_id, MAX(is_pitcher) AS is_pitcher,
    SUM(PA) AS PA,
    SUM(runs_above_avg) AS RAA, SUM(runs_above_avg_off) AS RAA_off, SUM(runs_above_avg_def) AS RAA_def,
    SUM(runs_above_rep) AS RAR,
    SUM(WAA) AS WAA, SUM(WAA_off) AS WAA_off, SUM(WAA_def) AS WAA_def,
    SUM(WAR) AS WAR, SUM(WAR_off) AS WAR_off, SUM(WAR_def) AS WAR_def
    FROM `bat_war` GROUP BY bbref_id) wart
  SET
       `bat_career`.`PA`        = wart.`PA`,
       `bat_career`.`RAA`       = wart.`RAA`,
       `bat_career`.`RAA_off`   = wart.`RAA_off`,
       `bat_career`.`RAA_def`   = wart.`RAA_def`,
       `bat_career`.`RAR`       = wart.`RAR`,
       `bat_career`.`WAA`       = wart.`WAA`,
       `bat_career`.`WAA_off`   = wart.`WAA_off`,
       `bat_career`.`WAA_def`   = wart.`WAA_def`,
       `bat_career`.`WAR`       = wart.`WAR`,
       `bat_career`.`WAR_off`   = wart.`WAR_off`,
       `bat_career`.`WAR_def`   = wart.`WAR_def`,
       `bat_career`.`is_pitcher` = wart.`is_pitcher`
 WHERE `bat_career`.`bbref_id`   = wart.`bbref_id`
 ;

--
-- Calculate derived statistics -- batting average and so forth
--
UPDATE bat_career SET
  BAVG  = IF(AB>0,  (H / AB), 0),
  TB    = IF(PA>0,  (H + h2B + 2 * h3B + 3 * HR), 0),
  SLG   = IF(AB>0, ((H + h2B + 2 * h3B + 3 * HR) / AB), 0),
  OBP   = IF(PA>0, ((H + BB + IFNULL(HBP,0))   / PA), 0),
  CIB   = IF(PA>0,  (PA - (AB + BB + IFNULL(HBP,0) + IFNULL(SH,0) + IFNULL(SF,0))), 0)
  ;
UPDATE bat_career SET
  OPS   =          (SLG + OBP),
  ISO   = IF(AB>0, ((TB - H) / AB), 0)
  ;


-- ===========================================================================
--
-- Career Pitching Table
--

SELECT NOW() AS starting_datetime, "Find career pitching stats";

DROP TABLE IF EXISTS `pit_career`;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pit_career` (
  `lahman_id`    int(11)                DEFAULT NULL,
  `player_id`    varchar(10)            CHARACTER SET ascii DEFAULT NULL,
  `bbref_id`     varchar(9)             CHARACTER SET ascii DEFAULT NULL,
  `retro_id`     varchar(9)             CHARACTER SET ascii DEFAULT NULL,
  --
  `name_common`  varchar(100)         DEFAULT NULL,
  `name_first`   varchar(50)          DEFAULT NULL,
  `name_last`    varchar(50)          NOT NULL   DEFAULT '',
  `height`       INT(3)               DEFAULT NULL,
  `weight`       INT(3)               DEFAULT NULL,
  --
  `years`       smallint(3)  unsigned DEFAULT NULL,
  `beg_year`     int(4)               DEFAULT NULL,
  `end_year`     int(4)               DEFAULT NULL,
  `hof_year`     smallint(4)          DEFAULT NULL,
  `votedBy`     varchar(64)           DEFAULT NULL,
  --
  `W`           smallint(2)  unsigned DEFAULT NULL,
  `L`           smallint(2)  unsigned DEFAULT NULL,
  `G`           smallint(3)  unsigned DEFAULT NULL,
  `GS`          smallint(3)  unsigned DEFAULT NULL,
  `GF`          smallint(3)  unsigned DEFAULT NULL,
  `CG`          smallint(3)  unsigned DEFAULT NULL,
  `SHO`         smallint(3)  unsigned DEFAULT NULL,
  `SV`          smallint(3)  unsigned DEFAULT NULL,
  `IPouts`      int(5)       unsigned DEFAULT NULL,
  `IP`          int(5)       unsigned DEFAULT NULL,
  `Y_allstar`   int(5)       unsigned DEFAULT NULL,
  --
  `H`           smallint(3)  unsigned DEFAULT NULL,
  `R`           smallint(3)  unsigned DEFAULT NULL,
  `ER`          smallint(3)  unsigned DEFAULT NULL,
  `HR`          smallint(3)  unsigned DEFAULT NULL,
  `BB`          smallint(3)  unsigned DEFAULT NULL,
  `SO`          smallint(3)  unsigned DEFAULT NULL,
  `IBB`         smallint(3)  unsigned DEFAULT NULL,
  `WP`          smallint(3)  unsigned DEFAULT NULL,
  `HBP`         smallint(3)  unsigned DEFAULT NULL,
  `BK`          smallint(3)  unsigned DEFAULT NULL,
  `BFP`         smallint(6)  unsigned DEFAULT NULL,
  --
  `ERA`         float        unsigned DEFAULT NULL,
  `WHIP`        float                 DEFAULT NULL,
  `BAOpp`       float        unsigned DEFAULT NULL,
  `H_9`         float                 DEFAULT NULL,
  `HR_9`        float                 DEFAULT NULL,
  `BB_9`        float                 DEFAULT NULL,
  `SO_9`        float                 DEFAULT NULL,
  `SO_BB`       float                 DEFAULT NULL,
  --
  `RAA`         float                 DEFAULT NULL,
  `RAR`         float                 DEFAULT NULL,
  `WAA`         float                 DEFAULT NULL,
  `WAR`         float                 DEFAULT NULL,
  --
  PRIMARY KEY             (`lahman_id`),
  UNIQUE KEY `player_id`   (`player_id`),
  UNIQUE KEY `bbref_id`    (`bbref_id`),
  UNIQUE KEY `retro_id`    (`retro_id`,`bbref_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1
;

REPLACE INTO pit_career
  (lahman_id, player_id, bbref_id, retro_id,
    name_Common, name_First, name_Last, height, weight,
    years, beg_year, end_year,
    hof_year, votedBy,
    `W`, `L`, `G`, `GS`, `GF`,
    `CG`, `SHO`, `SV`, `IPouts`, `IP`,
    `Y_allstar`,
    `H`, `R`, `ER`, `HR`, `BB`, `SO`,
    `IBB`, `WP`, `HBP`, `BK`, `BFP`
    )

  SELECT
    lahman_id, pit.player_id, bbref_id, retro_id,
    peep.name_Common, name_First, name_Last, height, weight,
    COUNT(DISTINCT pit.year_id) AS years, MIN(pit.year_id) AS beg_year,  MAX(pit.year_id) AS end_year,
    hof.year_id AS hof_year, votedBy,
    -- pit.stint, pit.team_id, pit.lg_id,
    SUM(pit.`W`)      AS `W`, SUM(pit.`L`) AS `L`, SUM(pit.`G`) AS `G`,
    SUM(pit.`GS`)     AS `GS`, SUM(pit.`GF`) AS `GF`, SUM(pit.`CG`) AS `CG`,
    SUM(pit.`SHO`)    AS `SHO`, SUM(pit.`SV`) AS `SV`,
    SUM(pit.`IPouts`) AS `IPouts`, SUM(pit.`IPouts`) / 3.0 AS `IP`,
    IFNULL(ast.Y_allstar,0) AS Y_allstar,
    SUM(pit.`H`)      AS `H`, SUM(pit.`R`) AS `R`, SUM(pit.`ER`) AS `ER`, SUM(pit.`HR`) AS `HR`,
    SUM(pit.`BB`)     AS `BB`, SUM(pit.`SO`) AS `SO`,
    SUM(pit.`IBB`)    AS `IBB`, SUM(pit.`WP`) AS `WP`, SUM(pit.`HBP`) AS `HBP`,
    SUM(pit.`BK`)     AS `BK`, SUM(pit.`BFP`) AS `BFP`
  --
  FROM pit_stints pit
  JOIN `people` peep
    ON pit.`player_id` = peep.`player_id`
  LEFT JOIN (
    SELECT player_id, count(DISTINCT year_id) AS Y_allstar FROM allstars ast
      GROUP BY player_id ) ast
    ON pit.`player_id` = ast.`player_id`
  LEFT JOIN `halloffame` hof
    ON (peep.`hof_id` = hof.`hof_id`) AND (inducted = 'Y') AND (hof.category = 'Player')
  GROUP BY player_id
;

--
-- Calculate derived statistics -- ERA and so forth
--
UPDATE pit_career SET
  WHIP  = ( (BB + H) / (IPouts / 3) ),
  ERA   = ( ER / IP ),
  H_9   = ( H  / (IPouts / 27) ),
  HR_9  = ( HR / (IPouts / 27) ),
  BB_9  = ( BB / (IPouts / 27) ),
  SO_9  = ( SO / (IPouts / 27) ),
  SO_BB = IF(BB>0, ( SO / BB ), 0)
  ;

--
-- Copy over WAR settings from baseball_reference tables
--
UPDATE `pit_career`,
  (SELECT bbref_id,
    SUM(WAA) AS WAA,
    SUM(WAR) AS WAR
    FROM `pit_war` GROUP BY bbref_id) wart
  SET  `pit_career`.`WAA`      = wart.`WAA`,
       `pit_career`.`WAR`      = wart.`WAR`
 WHERE `pit_career`.`bbref_id`  = wart.`bbref_id`
 ;
