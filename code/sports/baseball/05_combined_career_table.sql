-- ===========================================================================
--
-- Combined Career Table
--

SELECT NOW() AS starting_datetime, "Find combined career stats";

DROP TABLE IF EXISTS `comb_career`;
CREATE TABLE `comb_career` (
  `lahman_id`    int(11)               DEFAULT NULL,
  `player_id`    varchar(10)           CHARACTER SET ascii DEFAULT NULL,
  `bbref_id`     varchar(9)            CHARACTER SET ascii DEFAULT NULL,
  `retro_id`     varchar(9)            CHARACTER SET ascii DEFAULT NULL,
  --
  `name_common`  varchar(100)         DEFAULT NULL,
  `name_first`   varchar(50)          DEFAULT NULL,
  `name_last`    varchar(50)          NOT NULL DEFAULT '',
  `name_given`   varchar(255)         DEFAULT NULL,
  `name_nick`    varchar(255)         DEFAULT NULL,
  --
  `years`       smallint(3) unsigned  DEFAULT NULL,
  `beg_year`     int(4)               DEFAULT NULL,
  `end_year`     int(4)               DEFAULT NULL,
  `hof_year`     smallint(4)          DEFAULT NULL,
  `votedBy`     varchar(64)           DEFAULT NULL,
  --
  `G`           int(5) unsigned       DEFAULT NULL,
  `G_batting`   int(5) unsigned       DEFAULT NULL,
  `G_pitching`  int(5) unsigned       DEFAULT NULL,
  `Y_allstar`   int(5) unsigned       DEFAULT NULL,
  `is_pitcher`   BOOLEAN              DEFAULT NULL,
  --
  `PA`          int(5) unsigned       DEFAULT NULL,
  `AB`          int(5) unsigned       DEFAULT NULL,
  `R`           int(5) unsigned       DEFAULT NULL,
  `H`           int(5) unsigned       DEFAULT NULL,
  `h2B`          int(5) unsigned      DEFAULT NULL,
  `h3B`          int(5) unsigned      DEFAULT NULL,
  `HR`          int(5) unsigned       DEFAULT NULL,
  `RBI`         int(5) unsigned       DEFAULT NULL,
  `SB`          int(5) unsigned       DEFAULT NULL,
  `CS`          int(5) unsigned       DEFAULT NULL,
  `BB`          int(5) unsigned       DEFAULT NULL,
  `SO`          int(5) unsigned       DEFAULT NULL,
  `IBB`         int(5) unsigned       DEFAULT NULL,
  `HBP`         int(5) unsigned       DEFAULT NULL,
  `SH`          int(5) unsigned       DEFAULT NULL,
  `SF`          int(5) unsigned       DEFAULT NULL,
  `GIDP`        int(5) unsigned       DEFAULT NULL,
  `CIB`         int(5)                DEFAULT NULL,
  --
  `BAVG`        float                 DEFAULT NULL,
  `TB`          float                 DEFAULT NULL,
  `SLG`         float                 DEFAULT NULL,
  `OBP`         float                 DEFAULT NULL,
  `OPS`         float                 DEFAULT NULL,
  `ISO`         float                 DEFAULT NULL,
  --
  `W`           smallint(2)  unsigned DEFAULT NULL,
  `L`           smallint(2)  unsigned DEFAULT NULL,
  `GS`          smallint(3)  unsigned DEFAULT NULL,
  `GF`          smallint(3)  unsigned DEFAULT NULL,
  `CG`          smallint(3)  unsigned DEFAULT NULL,
  `SHO`         smallint(3)  unsigned DEFAULT NULL,
  `SV`          smallint(3)  unsigned DEFAULT NULL,
  `IPouts`      int(5)       unsigned DEFAULT NULL,
  `IP`          int(5)       unsigned DEFAULT NULL,
  --
  `HA`          smallint(3)  unsigned DEFAULT NULL,
  `RA`          smallint(3)  unsigned DEFAULT NULL,
  `ER`          smallint(3)  unsigned DEFAULT NULL,
  `HRA`         smallint(3)  unsigned DEFAULT NULL,
  `BBA`         smallint(3)  unsigned DEFAULT NULL,
  `SOA`         smallint(3)  unsigned DEFAULT NULL,
  `IBBA`        smallint(3)  unsigned DEFAULT NULL,
  `WP`          smallint(3)  unsigned DEFAULT NULL,
  `HBPA`        smallint(3)  unsigned DEFAULT NULL,
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
  `RAA_off`     float                 DEFAULT NULL,
  `RAA_def`     float                 DEFAULT NULL,
  `RAA_pit`     float                 DEFAULT NULL,
  `RAR`         float                 DEFAULT NULL,
  `RAR_pit`     float                 DEFAULT NULL,
  `WAA`         float                 DEFAULT NULL,
  `WAA_off`     float                 DEFAULT NULL,
  `WAA_def`     float                 DEFAULT NULL,
  `WAA_pit`     float                 DEFAULT NULL,
  `WAR`         float                 DEFAULT NULL,
  `WAR_off`     float                 DEFAULT NULL,
  `WAR_def`     float                 DEFAULT NULL,
  `WAR_pit`     float                 DEFAULT NULL,
  --
  `birth_year`   int(4)               DEFAULT NULL,
  `birth_month`  int(2)               DEFAULT NULL,
  `birth_Day`    int(2)               DEFAULT NULL,
  `birth_Country` varchar(50)         DEFAULT NULL,
  `birth_State`  char(2)              DEFAULT NULL,
  `birth_City`   varchar(50)          DEFAULT NULL,
  `death_year`   int(4)               DEFAULT NULL,
  `death_month`  int(2)               DEFAULT NULL,
  `death_Day`    int(2)               DEFAULT NULL,
  `death_Country` varchar(50)         DEFAULT NULL,
  `death_State`  char(2)              DEFAULT NULL,
  `death_City`   varchar(50)          DEFAULT NULL,
  `height`       INT(3)              DEFAULT NULL,
  `weight`       int(3)               DEFAULT NULL,
  `bats`         enum('L','R','B')    DEFAULT NULL,
  `throws`       enum('L','R','B')    DEFAULT NULL,
  `college`      varchar(50)          DEFAULT NULL,
  --
  `first_game`       varchar(10)      DEFAULT NULL,
  `final_game`   varchar(10)          DEFAULT NULL,
  --
  PRIMARY KEY      (`lahman_id`),
  UNIQUE KEY `player_id`   (`player_id`),
  UNIQUE KEY `bbref_id`    (`bbref_id`),
  UNIQUE KEY `retro_id`    (`retro_id`,`bbref_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8
;

REPLACE INTO comb_career
  (lahman_id, player_id, bbref_id, retro_id,
    name_common, name_first, name_last, name_given, name_nick, 
    --
    years, beg_year, end_year, hof_year, votedBy,
    G, G_batting, `G_pitching`, Y_allstar, `is_pitcher`,
    --
    PA, AB, R, H, h2B, h3B,
    HR, RBI, SB, CS, BB, SO,
    IBB, HBP, SH, SF, GIDP, CIB,
    `BAVG`, `TB`, `SLG`, OBP, OPS, ISO,
    --
    `W`, `L`, `GS`, `GF`,
    `CG`, `SHO`, `SV`, `IPouts`, `IP`,
    --
    `HA`, `RA`, `ER`, `HRA`, `BBA`, `SOA`,
    `IBBA`, `WP`, `HBPA`, `BK`, `BFP`,
    --
    `ERA`, `WHIP`, `H_9`, `HR_9`, `BB_9`, `SO_9`, `SO_BB`,
    --
    RAA, RAA_off, RAA_def, RAA_pit, RAR, RAR_pit,
    WAA, WAA_off, WAA_def, WAA_pit,
    WAR, WAR_off, WAR_def, WAR_pit,
    --
    birth_year, birth_month, birth_Day, birth_Country, birth_State, birth_City,
    death_year, death_month, death_Day, death_Country, death_State, death_City,
    height, weight, bats, throws, college,
    first_game, final_game)

  SELECT
    peep.lahman_id,   peep.player_id,  peep.bbref_id,  peep.retro_id,
    peep.name_common, peep.name_first, peep.name_last, peep.name_given, peep.name_nick, 
    --
    bat.years, bat.beg_year, bat.end_year, bat.hof_year, bat.votedBy,
    bat.G, bat.G_batting, pit.`G` AS `G_pitching`, bat.Y_allstar, bat.is_pitcher,
    --
    bat.`PA`, bat.`AB`, bat.`R`, bat.`H`, bat.`h2B`, bat.`h3B`,
    bat.`HR`, bat.`RBI`, bat.`SB`, bat.`CS`, bat.`BB`, bat.`SO`,
    bat.`IBB`, bat.`HBP`, bat.`SH`, bat.`SF`, bat.`GIDP`, bat.`CIB`,
    bat.`BAVG` AS BAVG, bat.`TB`, bat.`SLG`, bat.`OBP`, bat.`OPS`, bat.`ISO`,
    --
    pit.`W`, pit.`L`, pit.`GS`, pit.`GF`,
    pit.`CG`, pit.`SHO`, pit.`SV`, pit.`IPouts`, pit.`IP`,
    --
    pit.`H`   AS `HA`, pit.`R` AS `RA`, pit.`ER`, pit.HR AS `HRA`, pit.BB AS `BBA`, pit.SO AS `SOA`,
    pit.`IBB` AS `IBBA`, pit.`WP`, pit.`HBP` AS HBPA, pit.`BK`, pit.`BFP`,
    --
    pit.`ERA`, pit.`WHIP`, pit.`H_9`, pit.`HR_9`, pit.`BB_9`, pit.`SO_9`, pit.`SO_BB`,
    --
    bat.RAA, bat.RAA_off, bat.RAA_def, pit.RAA AS RAA_pit, bat.RAR AS RAR, pit.RAR AS RAR_pit,
    bat.WAA, bat.WAA_off, bat.WAA_def, pit.WAA AS WAA_pit,
    bat.WAR, bat.WAR_off, bat.WAR_def, pit.WAR AS WAR_pit,
    --
    birth_year, birth_month, birth_day, birth_country, birth_state, birth_city,
    death_year, death_month, death_day, death_country, death_state, death_city,
    peep.height, peep.weight, bats, throws, college,
    first_game, final_game

  --
  FROM      `people`     peep
  LEFT JOIN `bat_career` bat   ON peep.`lahman_id` = bat.`lahman_id`
  LEFT JOIN `pit_career` pit   ON peep.`lahman_id` = pit.`lahman_id`
;
