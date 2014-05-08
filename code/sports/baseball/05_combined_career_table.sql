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
  `name_common`  varchar(100)          default NULL,
  `name_first`   varchar(50)           default NULL,
  `name_last`    varchar(50)  NOT NULL default '',
  `name_given`   varchar(255)          default NULL,
  `name_nick`    varchar(255)          default NULL,
  --
  `years`       smallint(3) unsigned  default NULL,
  `beg_year`     int(4)                default NULL,
  `end_year`     int(4)                default NULL,
  `hof_year`     smallint(4)           default NULL,
  `votedBy`     varchar(64)           default NULL,
  --
  `G`           int(5) unsigned       default NULL,
  `G_batting`   int(5) unsigned       default NULL,
  `G_pitching`  int(5) unsigned       default NULL,
  `Y_allstar`   int(5) unsigned       default NULL,
  `is_pitcher`   BOOLEAN               default NULL,
  --
  `PA`          int(5) unsigned       default NULL,
  `AB`          int(5) unsigned       default NULL,
  `R`           int(5) unsigned       default NULL,
  `H`           int(5) unsigned       default NULL,
  `h2B`          int(5) unsigned       default NULL,
  `h3B`          int(5) unsigned       default NULL,
  `HR`          int(5) unsigned       default NULL,
  `RBI`         int(5) unsigned       default NULL,
  `SB`          int(5) unsigned       default NULL,
  `CS`          int(5) unsigned       default NULL,
  `BB`          int(5) unsigned       default NULL,
  `SO`          int(5) unsigned       default NULL,
  `IBB`         int(5) unsigned       default NULL,
  `HBP`         int(5) unsigned       default NULL,
  `SH`          int(5) unsigned       default NULL,
  `SF`          int(5) unsigned       default NULL,
  `GIDP`        int(5) unsigned       default NULL,
  `CIB`         int(5)                default NULL,
  --
  `BAVG`        float                 default NULL,
  `TB`          float                 default NULL,
  `SLG`         float                 default NULL,
  `OBP`         float                 default NULL,
  `OPS`         float                 default NULL,
  `ISO`         float                 default NULL,
  --
  `W`           smallint(2)  unsigned default NULL,
  `L`           smallint(2)  unsigned default NULL,
  `GS`          smallint(3)  unsigned default NULL,
  `GF`          smallint(3)  unsigned default NULL,
  `CG`          smallint(3)  unsigned default NULL,
  `SHO`         smallint(3)  unsigned default NULL,
  `SV`          smallint(3)  unsigned default NULL,
  `IPouts`      int(5)       unsigned default NULL,
  `IP`          int(5)       unsigned default NULL,
  --
  `HA`          smallint(3)  unsigned default NULL,
  `RA`          smallint(3)  unsigned default NULL,
  `ER`          smallint(3)  unsigned default NULL,
  `HRA`         smallint(3)  unsigned default NULL,
  `BBA`         smallint(3)  unsigned default NULL,
  `SOA`         smallint(3)  unsigned default NULL,
  `IBBA`        smallint(3)  unsigned default NULL,
  `WP`          smallint(3)  unsigned default NULL,
  `HBPA`        smallint(3)  unsigned default NULL,
  `BK`          smallint(3)  unsigned default NULL,
  `BFP`         smallint(6)  unsigned default NULL,
  --
  `ERA`         float        unsigned default NULL,
  `WHIP`        float                 default NULL,
  `BAOpp`       float        unsigned default NULL,
  `H_9`         float                 default NULL,
  `HR_9`        float                 default NULL,
  `BB_9`        float                 default NULL,
  `SO_9`        float                 default NULL,
  `SO_BB`       float                 default NULL,
  --
  `RAA`         float                 default NULL,
  `RAA_off`     float                 default NULL,
  `RAA_def`     float                 default NULL,
  `RAA_pit`     float                 default NULL,
  `RAR`         float                 default NULL,
  `RAR_pit`     float                 default NULL,
  `WAA`         float                 default NULL,
  `WAA_off`     float                 default NULL,
  `WAA_def`     float                 default NULL,
  `WAA_pit`     float                 default NULL,
  `WAR`         float                 default NULL,
  `WAR_off`     float                 default NULL,
  `WAR_def`     float                 default NULL,
  `WAR_pit`     float                 default NULL,
  --
  `birth_year`   int(4)                default NULL,
  `birth_month`  int(2)                default NULL,
  `birth_Day`    int(2)                default NULL,
  `birth_Country` varchar(50)          default NULL,
  `birth_State`  char(2)               default NULL,
  `birth_City`   varchar(50)           default NULL,
  `death_year`   int(4)                default NULL,
  `death_month`  int(2)                default NULL,
  `death_Day`    int(2)                default NULL,
  `death_Country` varchar(50)          default NULL,
  `death_State`  char(2)               default NULL,
  `death_City`   varchar(50)           default NULL,
  `weight`      int(3)                default NULL,
  `height`      double(4,1)           default NULL,
  `bats`        enum('L','R','B')     default NULL,
  `throws`      enum('L','R','B')     default NULL,
  `college`     varchar(50)           default NULL,
  --
  `first_game`       varchar(10)           DEFAULT NULL,
  `final_game`   varchar(10)           DEFAULT NULL,
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
    weight, height, bats, throws, college,
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
    weight, height, bats, throws, college,
    first_game, final_game

  --
  FROM      `people`     peep
  LEFT JOIN `bat_career` bat   ON peep.`lahman_id` = bat.`lahman_id`
  LEFT JOIN `pit_career` pit   ON peep.`lahman_id` = pit.`lahman_id`
;
