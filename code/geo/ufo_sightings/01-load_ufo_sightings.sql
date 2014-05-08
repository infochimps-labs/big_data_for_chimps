
USE `ufo_sightings`;

--
-- Notes:
--
-- some field names modified to match baseball_databank ones: year_id vs year__id, etc.
-- note that players are identified with "retro_id" in the people table, not player_id
--

DROP TABLE IF EXISTS `sightings`;
CREATE TABLE         `sightings` (
    `id`                INTEGER NOT NULL AUTO_INCREMENT,
    `sighted_at`        DATE,
    `reported_at`       DATE,
    `location_str`      VARCHAR(100),
    `shape`             VARCHAR(10),
    `duration_str`      VARCHAR(100),
    `description`       TEXT(30000),
    `lng`               FLOAT,
    `lat`               FLOAT,
    `city`              VARCHAR(100),
    `county`            VARCHAR(100),
    `state`             VARCHAR(100),
    `country`           VARCHAR(100),
    `duration`          VARCHAR(100),
  PRIMARY KEY `ix_id`        (`id`),
  KEY         `ix_lng_lat`   (`lat`, `lng`),
  KEY         `ix_loc`       (`country`, `state`, `city`),
  KEY         `ix_st`        (`state`, `city`),
  KEY         `ix_shape`     (`shape`),
  KEY         `ix_sighted`   (`sighted_at`)
  ) ENGINE=MyISAM DEFAULT CHARSET=ASCII
  ;

LOAD DATA INFILE '/Users/flip/ics/core/wukong/data/geo/ufo_sightings/ufo_sightings.tsv'
  INTO TABLE `sightings`
  FIELDS TERMINATED BY '\t' ESCAPED BY ''
  (`sighted_at` , `reported_at` , `location_str` , `shape` , `duration_str` , `description` , `lng` , `lat` , `city` , `county` , `state` , `country` , `duration`)
  ;

