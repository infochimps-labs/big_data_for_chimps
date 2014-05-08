-- ===========================================================================
--
-- People Table
--

SELECT NOW() AS starting_datetime, "people: ids from all sources";

DROP TABLE IF EXISTS `people`;
CREATE TABLE `people` (
  `lahman_id`     INT(11)      DEFAULT NULL,
  `player_id`     char(9)      CHARACTER SET ascii DEFAULT NULL,
  `bbref_id`      char(9)      CHARACTER SET ascii DEFAULT NULL,
  `retro_id`      char(8)      CHARACTER SET ascii DEFAULT NULL,
  --
  `name_common`   VARCHAR(100) DEFAULT NULL,
  --
  `birth_year`    INT(11)      DEFAULT NULL,
  `birth_month`   INT(11)      DEFAULT NULL,
  `birth_day`     INT(11)      DEFAULT NULL,
  `birth_country` VARCHAR(50)  DEFAULT NULL,
  `birth_state`   VARCHAR(2)   DEFAULT NULL,
  `birth_city`    VARCHAR(50)  DEFAULT NULL,
  `death_year`    INT(11)      DEFAULT NULL,
  `death_month`   INT(11)      DEFAULT NULL,
  `death_day`     INT(11)      DEFAULT NULL,
  `death_country` VARCHAR(50)  DEFAULT NULL,
  `death_state`   VARCHAR(2)   DEFAULT NULL,
  `death_city`    VARCHAR(50)  DEFAULT NULL,
  `name_first`    VARCHAR(50)  DEFAULT NULL,
  `name_last`     VARCHAR(50)  DEFAULT NULL,
  `name_note`     VARCHAR(255) DEFAULT NULL,
  `name_given`    VARCHAR(255) DEFAULT NULL,
  `name_nick`     VARCHAR(255) DEFAULT NULL,
  --
  `weight`        INT(11)      DEFAULT NULL,
  `height`        FLOAT        DEFAULT NULL,
  `bats`          VARCHAR(1)   DEFAULT NULL,
  `throws`        VARCHAR(1)   DEFAULT NULL,
  `first_game`    DATE         DEFAULT NULL,
  `final_game`    DATE         DEFAULT NULL,
  `college`       VARCHAR(50)  DEFAULT NULL,
  --
  `manager_id`    CHAR(10)     CHARACTER SET ascii DEFAULT NULL,
  `hof_id`        CHAR(10)     CHARACTER SET ascii DEFAULT NULL,

  PRIMARY KEY (`lahman_id`),
  UNIQUE KEY `bbref_id`   (`bbref_id`),
  UNIQUE KEY `player_id`  (`player_id`),
  UNIQUE KEY `retro_id`   (`retro_id`,`bbref_id`),
  UNIQUE KEY `manager_id` (`manager_id`),
  UNIQUE KEY `hof_id`     (`hof_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8
;

REPLACE INTO `people`
  (      `player_id`, `retro_id`, `lahman_id`, `bbref_id`, `birth_year`, `birth_month`, `birth_day`, `birth_country`, `birth_state`, `birth_city`, `death_year`, `death_month`, `death_day`, `death_country`, `death_state`, `death_city`, `name_first`, `name_last`, `name_note`, `name_given`, `name_nick`, `weight`, `height`, `bats`, `throws`,
         `first_game`, `final_game`, `college`, `manager_id`, `hof_id`)
  SELECT `player_id`, `retro_id`, `lahman_id`, `bbref_id`, `birth_year`, `birth_month`, `birth_day`, `birth_country`, `birth_state`, `birth_city`, `death_year`, `death_month`, `death_day`, `death_country`, `death_state`, `death_city`, `name_first`, `name_last`, `name_note`, `name_given`, `name_nick`, `weight`, `height`, `bats`, `throws`,
    STR_TO_DATE(`first_game`, '%m/%d/%Y'), 
    STR_TO_DATE(`final_game`,  '%m/%d/%Y'), `college`, `manager_id`, `hof_id`
  FROM `master`
;
