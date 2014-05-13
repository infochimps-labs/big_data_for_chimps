-- ===========================================================================
--
-- Batting WAR Table
--

SELECT NOW() AS starting_datetime, "Creating WAR tables and adding indexable ids: should take about 10 seconds on a macbook pro";

DROP TABLE IF EXISTS `bat_war`;
CREATE TABLE bat_war (
  `lahman_id`            int(11)              DEFAULT NULL,
  `player_id`            CHAR(9)              CHARACTER SET ascii DEFAULT NULL,
  `bbref_id`             CHAR(9)              CHARACTER SET ascii DEFAULT NULL,
  `retro_id`             CHAR(8)              CHARACTER SET ascii DEFAULT NULL,
  --
  `name_common`          varchar(100),
  `age`                 smallint(2) unsigned DEFAULT NULL,
  --
  `year_id`              smallint(4)          NOT NULL,
  `team_id`              char(3)              NOT NULL,
  `stint_id`               smallint(2) unsigned NOT NULL,
  `lg_id`                char(2)              NOT NULL,
  `PA`                  int(5)      unsigned default NULL,
  `G`                   int(5)      unsigned default NULL,
  `Inn`                 float                default NULL,
  `runs_bat`            float                default NULL,
  `runs_br`             float                default NULL,
  `runs_dp`             float                default NULL,
  `runs_field`          float                default NULL,
  `runs_infield`        float                default NULL,
  `runs_outfield`       float                default NULL,
  `runs_catcher`        float                default NULL,
  `runs_good_plays`     float                default NULL,
  `runs_defense`        float                default NULL,
  `runs_position`       float                default NULL,
  `runs_position_p`     float                default NULL,
  `runs_replacement`    float                default NULL,
  `runs_above_rep`      float                default NULL,
  `runs_above_avg`      float                default NULL,
  `runs_above_avg_off`  float                default NULL,
  `runs_above_avg_def`  float                default NULL,
  `WAA`                 float                default NULL,
  `WAA_off`             float                default NULL,
  `WAA_def`             float                default NULL,
  `WAR`                 float                default NULL,
  `WAR_off`             float                default NULL,
  `WAR_def`             float                default NULL,
  `WAR_rep`             float                default NULL,
  `salary`              int(10)              default NULL,
  `is_pitcher`           BOOLEAN              default NULL,
  `teamRpG`             float                default NULL,
  `oppRpG`              float                default NULL,
  `oppRpPA_rep`         float                default NULL,
  `oppRpG_rep`          float                default NULL,
  `pyth_exponent`       float                default NULL,
  `pyth_exponent_rep`   float                default NULL,
  `waa_win_perc`        float                default NULL,
  `waa_win_perc_off`    float                default NULL,
  `waa_win_perc_def`    float                default NULL,
  `waa_win_perc_rep`    float                default NULL,
  --
  PRIMARY KEY           (`bbref_id`, `year_id`, `stint_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1
;

-- Note: WAR is in order def, off in raw file; order off, def above
LOAD DATA INFILE '/Users/flip/ics/core/wukong/data/sports/baseball/baseball_reference/batting_war-20140402.csv' REPLACE
  INTO TABLE `bat_war`
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
  IGNORE 1 ROWS
  ( name_common,age,bbref_id,year_id,team_id,stint_id,lg_id,PA,G,Inn,
    runs_bat,runs_br,runs_dp,runs_field,runs_infield,runs_outfield,runs_catcher,runs_good_plays,
    runs_defense,runs_position,runs_position_p,
    runs_replacement,runs_above_rep,runs_above_avg,runs_above_avg_off,runs_above_avg_def,
    WAA,WAA_off,WAA_def,WAR,WAR_def,WAR_off,WAR_rep,
    salary, @is_pitcherYN,
    teamRpG,oppRpG,oppRpPA_rep,oppRpG_rep,pyth_exponent,pyth_exponent_rep,
    waa_win_perc,waa_win_perc_off,waa_win_perc_def,waa_win_perc_rep)
  SET is_pitcher = IF(@is_pitcherYN = "Y", TRUE, FALSE)
;
SELECT NOW() AS starting_datetime, "Finished import batting WAR", COUNT(*) AS n_bat FROM bat_war;
--
UPDATE `bat_war`, `people`
   SET `bat_war`.`player_id` = `people`.`player_id`,
       `bat_war`.`retro_id`  = `people`.`retro_id`,
       `bat_war`.`lahman_id` = `people`.`lahman_id`
 WHERE `bat_war`.`bbref_id`  = `people`.`bbref_id` ;
--
ALTER TABLE `bat_war`
  ADD UNIQUE KEY `lahman`   (`lahman_id`,`year_id`, `stint_id`),
  ADD UNIQUE KEY `player`   (`player_id`,`year_id`, `stint_id`),
  ADD KEY        `retro`    (`retro_id`,`bbref_id`, `year_id`, `stint_id`),
  ADD KEY        `season`   (`year_id`),
  ADD KEY        `team`     (`team_id`,  `year_id`, `lg_id`, `stint_id`)
  ;
SELECT NOW() AS starting_datetime, "Finished fixing batting WAR", COUNT(*) AS n_bat FROM bat_war;

-- ===========================================================================
--
-- Pitching WAR
--
--

DROP TABLE IF EXISTS `pit_war`;
CREATE TABLE pit_war (
  `lahman_id`            int(11)              DEFAULT NULL,
  `player_id`            CHAR(9)              CHARACTER SET ascii DEFAULT NULL,
  `bbref_id`             CHAR(9)              CHARACTER SET ascii DEFAULT NULL,
  `retro_id`             CHAR(8)              CHARACTER SET ascii DEFAULT NULL,
  --
  `name_common`          varchar(100),
  `age`                 smallint(2) unsigned DEFAULT NULL,
  --
  `year_id`              smallint(4) NOT NULL default '0',
  `team_id`              char(3)     NOT NULL default '',
  `stint_id`               smallint(2) unsigned NOT NULL default '0',
  `lg_id`                char(2)     NOT NULL default '',
  --
  `G`                   int(5)      unsigned default NULL,
  `GS`                  int(5)      unsigned default NULL,
  `IPouts`              float                default NULL,
  `IPouts_start`        float                default NULL,
  `IPouts_relief`       float                default NULL,
  `RA`                  float                default NULL,
  `xRA`                 float                default NULL,
  `xRA_sprp_adj`        float                default NULL,
  `xRA_def_pitcher`     float                default NULL,
  `PPF`                 float                default NULL,
  `PPF_custom`          float                default NULL,
  `xRA_final`           float                default NULL,
  `BIP`                 float                default NULL,
  `BIP_perc`            float                default NULL,
  `RS_def_total`        float                default NULL,
  `runs_above_avg`      float                default NULL,
  `runs_above_avg_adj`  float                default NULL,
  `runs_above_rep`      float                default NULL,
  `RpO_replacement`     float                default NULL,
  `GR_leverage_idx_avg` float                default NULL,
  `WAR`                 float                default NULL,
  `salary`              float                default NULL,
  `teamRpG`             float                default NULL,
  `oppRpG`              float                default NULL,
  `pyth_exponent`       float                default NULL,
  `waa_win_perc`        float                default NULL,
  `WAA`                 float                default NULL,
  `WAA_adj`             float                default NULL,
  `oppRpG_rep`          float                default NULL,
  `pyth_exponent_rep`   float                default NULL,
  `waa_win_perc_rep`    float                default NULL,
  `WAR_rep`             float                default NULL,
  --
  PRIMARY KEY           (`bbref_id`, `year_id`, `stint_id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=latin1
;

LOAD DATA INFILE '/Users/flip/ics/core/wukong/data/sports/baseball/baseball_reference/pitching_war-20140402.csv' REPLACE
  INTO TABLE `pit_war`
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY ''
  IGNORE 1 ROWS
  ( name_common,age,bbref_id,year_id,team_id,stint_id,lg_id,
    G,GS,IPouts,IPouts_start,IPouts_relief,
    RA,xRA,xRA_sprp_adj,xRA_def_pitcher,PPF,PPF_custom,xRA_final,
    BIP,BIP_perc,RS_def_total,
    runs_above_avg,runs_above_avg_adj,runs_above_rep,RpO_replacement,GR_leverage_idx_avg,
    WAR,salary,
    teamRpG,oppRpG,pyth_exponent,waa_win_perc,WAA,WAA_adj,oppRpG_rep,
    pyth_exponent_rep,waa_win_perc_rep,WAR_rep )
;
SELECT NOW() AS starting_datetime, "Finished import pitching WAR", COUNT(*) as n_pit FROM pit_war;
--
UPDATE `pit_war`,`people`
   SET `pit_war`.`player_id` = `people`.`player_id`,
       `pit_war`.`retro_id`  = `people`.`retro_id`,
       `pit_war`.`lahman_id` = `people`.`lahman_id`
 WHERE `pit_war`.`bbref_id`  = `people`.`bbref_id`
 ;
--
ALTER TABLE `pit_war`
  ADD UNIQUE KEY `lahman`   (`lahman_id`,`year_id`, `stint_id`),
  ADD UNIQUE KEY `player`   (`player_id`,`year_id`, `stint_id`),
  ADD KEY        `retro`    (`retro_id`,`bbref_id`, `year_id`, `stint_id`),
  ADD KEY        `season`   (`year_id`),
  ADD KEY        `team`     (`team_id`,  `year_id`, `lg_id`, `stint_id`)
  ;
SELECT NOW() AS starting_datetime, "Finished fixing pitching WAR", COUNT(*) as n_pit FROM pit_war;

-- ===========================================================================
--
-- Pull the common name field from the war tables into the people table
--

UPDATE `pit_war`, `people`
   SET `people`.`name_common` = `pit_war`.`name_common`
 WHERE `pit_war`.`bbref_id` = `people`.`bbref_id`
 ;
UPDATE `bat_war`, `people`
   SET `people`.`name_common` = `bat_war`.`name_common`
 WHERE `bat_war`.`bbref_id`    = `people`.`bbref_id`
 ;
