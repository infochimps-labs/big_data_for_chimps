
-- ===========================================================================
--
-- Fixes for 2012 Baseball Databank
--

SELECT NOW() AS starting_datetime, "Correct a few inconsistencies";

ALTER TABLE `master`
  CHANGE `lahmanID`      `lahman_id`           INT(11)      NOT NULL,
  CHANGE `playerID`      `player_id`           VARCHAR(10)  DEFAULT NULL,
  CHANGE `managerID`     `manager_id`          VARCHAR(10)  DEFAULT NULL,
  CHANGE `hofID`         `hof_id`              VARCHAR(10)  DEFAULT NULL,
  CHANGE `birthYear`     `birth_year`          INT(11)      DEFAULT NULL,
  CHANGE `birthMonth`    `birth_month`         INT(11)      DEFAULT NULL,
  CHANGE `birthDay`      `birth_day`           INT(11)      DEFAULT NULL,
  CHANGE `birthCountry`  `birth_country`       VARCHAR(50)  DEFAULT NULL,
  CHANGE `birthState`    `birth_state`         VARCHAR(2)   DEFAULT NULL,
  CHANGE `birthCity`     `birth_city`          VARCHAR(50)  DEFAULT NULL,
  CHANGE `deathYear`     `death_year`          INT(11)      DEFAULT NULL,
  CHANGE `deathMonth`    `death_month`         INT(11)      DEFAULT NULL,
  CHANGE `deathDay`      `death_day`           INT(11)      DEFAULT NULL,
  CHANGE `deathCountry`  `death_country`       VARCHAR(50)  DEFAULT NULL,
  CHANGE `deathState`    `death_state`         VARCHAR(2)   DEFAULT NULL,
  CHANGE `deathCity`     `death_city`          VARCHAR(50)  DEFAULT NULL,
  CHANGE `nameFirst`     `name_first`          VARCHAR(50)  DEFAULT NULL,
  CHANGE `nameLast`      `name_last`           VARCHAR(50)  DEFAULT NULL,
  CHANGE `nameNote`      `name_note`           VARCHAR(255) DEFAULT NULL,
  CHANGE `nameGiven`     `name_given`          VARCHAR(255) DEFAULT NULL,
  CHANGE `nameNick`      `name_nick`           VARCHAR(255) DEFAULT NULL,
  CHANGE `debut`         `first_game`          VARCHAR(10)  DEFAULT NULL,
  CHANGE `finalGame`     `final_game`          VARCHAR(10)  DEFAULT NULL,
  CHANGE `lahman40ID`    `lahman40_id`         VARCHAR(9)   DEFAULT NULL,
  CHANGE `lahman45ID`    `lahman45_id`         VARCHAR(9)   DEFAULT NULL,
  CHANGE `retroID`       `retro_id`            VARCHAR(9)   DEFAULT NULL,
  CHANGE `holtzID`       `holtz_id`            VARCHAR(9)   DEFAULT NULL,
  CHANGE `bbrefID`       `bbref_id`            VARCHAR(9)   DEFAULT NULL
  ;

ALTER TABLE `batting`
  RENAME TO `bat_stints`,
  CHANGE `playerID` `player_id`                VARCHAR(9)   NOT NULL,
  CHANGE `yearID`   `year_id`                  INT(11)      NOT NULL,
  CHANGE `stint`    `stint_id`                 INT(11)      NOT NULL,
  CHANGE `teamID`   `team_id`                  VARCHAR(3)   DEFAULT NULL,
  CHANGE `lgID`     `lg_id`                    VARCHAR(2)   DEFAULT NULL,
  CHANGE `2B`       `h2B`                      INT(11)      DEFAULT NULL,
  CHANGE `3B`       `h3B`                      INT(11)      DEFAULT NULL
  ;

ALTER TABLE `battingpost`
  RENAME TO `bat_posts`,
  CHANGE `yearID`     `year_id`                INT(11)      NOT NULL,
  CHANGE `round`      `round_id`               VARCHAR(10)  NOT NULL,
  CHANGE `playerID`   `player_id`              VARCHAR(9)   NOT NULL,
  CHANGE `teamID`     `team_id`                VARCHAR(3)   DEFAULT NULL,
  CHANGE `lgID`       `lg_id`                  VARCHAR(2)   DEFAULT NULL,
  CHANGE `2B`         `h2B`                    INT(11)      DEFAULT NULL,
  CHANGE `3B`         `h3B`                    INT(11)      DEFAULT NULL
  ;

ALTER TABLE `pitching`
  RENAME TO `pit_stints`,
  CHANGE `playerID`  `player_id`               VARCHAR(9)   NOT NULL,
  CHANGE `yearID`    `year_id`                 INT(11)      NOT NULL,
  CHANGE `stint`     `stint_id`                INT(11)      NOT NULL,
  CHANGE `teamID`    `team_id`                 VARCHAR(3)   DEFAULT NULL,
  CHANGE `lgID`      `lg_id`                   VARCHAR(2)   DEFAULT NULL
  ;

ALTER TABLE `pitchingpost`
  RENAME TO `pit_posts`,
  CHANGE `playerID`   `player_id`              VARCHAR(9)   NOT NULL,
  CHANGE `yearID`     `year_id`                INT(11)      NOT NULL,
  CHANGE `round`      `round_id`               VARCHAR(10)  NOT NULL,
  CHANGE `teamID`     `team_id`                VARCHAR(3)   DEFAULT NULL,
  CHANGE `lgID`       `lg_id`                  VARCHAR(2)   DEFAULT NULL
;

ALTER TABLE `fielding`
  RENAME TO `fld_stints`,
  CHANGE `playerID`   `player_id`              VARCHAR(9)   NOT NULL,
  CHANGE `yearID`     `year_id`                INT(11)      NOT NULL,
  CHANGE `stint`      `stint_id`               INT(11)      NOT NULL,
  CHANGE `teamID`     `team_id`                VARCHAR(3)   DEFAULT NULL,
  CHANGE `lgID`       `lg_id`                  VARCHAR(2)   DEFAULT NULL
  ;

ALTER TABLE `fieldingpost`
  RENAME TO `fld_posts`,
  CHANGE `playerID`   `player_id`              VARCHAR(9)   NOT NULL,
  CHANGE `yearID`     `year_id`                INT(11)      NOT NULL,
  CHANGE `teamID`     `team_id`                VARCHAR(3)   DEFAULT NULL,
  CHANGE `lgID`       `lg_id`                  VARCHAR(2)   DEFAULT NULL,
  CHANGE `round`      `round_id`               VARCHAR(10)  NOT NULL
  ;

ALTER TABLE `managers`
  CHANGE `managerID`  `manager_id`             VARCHAR(10)  DEFAULT NULL,
  CHANGE `yearID`     `year_id`                INT(11)      NOT NULL,
  CHANGE `teamID`     `team_id`                VARCHAR(3)   NOT NULL,
  CHANGE `lgID`       `lg_id`                  VARCHAR(2)   DEFAULT NULL,
  CHANGE `Rank`       `W_rank`                 INT(11)      DEFAULT NULL
  ;

ALTER TABLE `salaries`
  CHANGE `yearID`     `year_id`                INT(11)      NOT NULL,
  CHANGE `teamID`     `team_id`                VARCHAR(3)   NOT NULL,
  CHANGE `lgID`       `lg_id`                  VARCHAR(2)   NOT NULL,
  CHANGE `playerID`   `player_id`              VARCHAR(9)   NOT NULL
  ;

ALTER TABLE `allstarfull`
  RENAME TO `allstars`,
  CHANGE `playerID`     `player_id`            VARCHAR(9)   NOT NULL,
  CHANGE `yearID`       `year_id`              INT(11)      NOT NULL,
  CHANGE `gameNum`      `game_seq`             INT(11)      NOT NULL,
  CHANGE `gameID`       `game_id`              VARCHAR(12)  DEFAULT NULL,
  CHANGE `teamID`       `team_id`              VARCHAR(3)   DEFAULT NULL,
  CHANGE `lgID`         `lg_id`                VARCHAR(2)   DEFAULT NULL,
  CHANGE `startingPos`  `pos_starting`         INT(11)      DEFAULT NULL
  ;

ALTER TABLE `appearances`
  CHANGE `yearID`     `year_id`                INT(11)      NOT NULL,
  CHANGE `teamID`     `team_id`                VARCHAR(3)   NOT NULL,
  CHANGE `lgID`       `lg_id`                  VARCHAR(2)   DEFAULT NULL,
  CHANGE `playerID`   `player_id`              VARCHAR(9)   NOT NULL
  ;

ALTER TABLE `teams`
  CHANGE `yearID`          `year_id`           INT(11)      NOT NULL,
  CHANGE `lgID`            `lg_id`             VARCHAR(2)   NOT NULL,
  CHANGE `teamID`          `team_id`           VARCHAR(3)   NOT NULL,
  CHANGE `franchID`        `franch_id`         VARCHAR(3)   DEFAULT NULL,
  CHANGE `divID`           `div_id`            VARCHAR(1)   DEFAULT NULL,
  CHANGE `Rank`            `W_rank`            INT(11)      DEFAULT NULL,
  CHANGE `Ghome`           `G_home`            INT(11)      DEFAULT NULL,
  CHANGE `DivWin`          `W_div`             VARCHAR(1)   DEFAULT NULL,
  CHANGE `WCWin`           `W_wc`              VARCHAR(1)   DEFAULT NULL,
  CHANGE `LgWin`           `W_lg`              VARCHAR(1)   DEFAULT NULL,
  CHANGE `WSWin`           `W_ws`              VARCHAR(1)   DEFAULT NULL,
  CHANGE `2B`              `h2B`               INT(11)      DEFAULT NULL,
  CHANGE `3B`              `h3B`               INT(11)      DEFAULT NULL,
  CHANGE `name`            `team_name`         VARCHAR(50)  DEFAULT NULL,
  CHANGE `park`            `park_name`         VARCHAR(255) DEFAULT NULL,
  CHANGE `teamIDBR`        `team_id_BR`        VARCHAR(3)   DEFAULT NULL,
  CHANGE `teamIDlahman45`  `team_id_lahman45`  VARCHAR(3)   DEFAULT NULL,
  CHANGE `teamIDretro`     `team_id_retro`     VARCHAR(3)   DEFAULT NULL
  ;

ALTER TABLE `teamshalf` 
  CHANGE `yearID`          `year_id`           INT(11)      NOT NULL,
  CHANGE `lgID`            `lg_id`             VARCHAR(2)   NOT NULL,
  CHANGE `teamID`          `team_id`           VARCHAR(3)   NOT NULL,
  CHANGE `Half`            `half_id`           VARCHAR(1)   DEFAULT NULL,
  CHANGE `divID`           `div_id`            VARCHAR(1)   DEFAULT NULL,
  CHANGE `Rank`            `W_rank`            INT(11)      DEFAULT NULL,
  CHANGE `DivWin`          `W_div`             VARCHAR(1)   DEFAULT NULL
  ;

ALTER TABLE `teamsfranchises`
  RENAME TO  `franchises`,
  CHANGE `franchID`   `franch_id`              VARCHAR(3)   NOT NULL,
  CHANGE `franchName` `franch_name`            VARCHAR(50)  DEFAULT NULL,
  CHANGE `active`     `is_active`              VARCHAR(2)   DEFAULT NULL,
  CHANGE `NAassoc`    `is_NAassoc`             VARCHAR(3)   DEFAULT NULL
  ;


ALTER TABLE `awardsplayers`
  CHANGE `playerID`  `player_id`               VARCHAR(9)   NOT NULL,
  CHANGE `awardID`   `award_id`                VARCHAR(25)  NOT NULL,
  CHANGE `yearID`    `year_id`                 INT(11)      NOT NULL,
  CHANGE `lgID`      `lg_id`                   VARCHAR(2)   NOT NULL
  ;

ALTER TABLE `awardsshareplayers`
  CHANGE `awardID`    `award_id`               VARCHAR(25)  NOT NULL,
  CHANGE `yearID`     `year_id`                INT(11)      NOT NULL,
  CHANGE `lgID`       `lg_id`                  VARCHAR(2)   NOT NULL,
  CHANGE `playerID`   `player_id`              VARCHAR(9)   NOT NULL,
  CHANGE `pointsWon`  `points_won`             DOUBLE       DEFAULT NULL,
  CHANGE `pointsMax`  `points_max`             INT          DEFAULT NULL,
  CHANGE `votesFirst` `votes_first`            DOUBLE       DEFAULT NULL,
  ;

DROP TABLE IF EXISTS `halloffame`;
CREATE TABLE `halloffame` (
  `player_id` VARCHAR(10)   NOT NULL,
  `hof_id`    VARCHAR(10)   NOT NULL,
  `year_id`   INT(11)       NOT NULL,
  `voted_by`  VARCHAR(64)   DEFAULT NULL,
  `ballots`   INT(11)       DEFAULT NULL,
  `needed`    INT(11)       DEFAULT NULL,
  `votes`     INT(11)       DEFAULT NULL,
  `inducted`  VARCHAR(1)    DEFAULT NULL,
  `category`  VARCHAR(20)   DEFAULT NULL,
  `note`      VARCHAR(20)   DEFAULT NULL,
  PRIMARY KEY    (`player_id`,`year_id`,`voted_by`),
  KEY  `player`  (`player_id),
  KEY  `year`    (`year_id`, `category`, `voted_by`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

LOAD DATA INFILE '/data/rawd/sports/baseball/baseball_databank/csv/HallOfFame.csv'
  REPLACE INTO TABLE `halloffame` FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '' LINES TERMINATED BY '\r\n'
  IGNORE 1 ROWS
  (player_id, year_id,voted_by,ballots,needed,votes,inducted,category,note)
  ;
UPDATE `halloffame` hof, `master` peep
  SET hof.hof_id = peep.hof_id
  WHERE hof.player_id = peep.player_id
  ;
UPDATE `halloffame`    SET `player_id` = 'glavito02' WHERE `player_id` = 'glavito01'  AND `year_id` = 2014 AND `voted_by` = 'BBWAA';


-- correct a couple errors in the 2012 Baseball Databank (the 'January 9, 3:00 pm' release)
-- need to do this first as the unique indexes fail otherwise

UPDATE `master`        SET `player_id` = 'baezjo01'  WHERE `lahman_id` = 460   AND `player_id` = 'baezda01';
UPDATE `master`        SET `bbref_id`  = 'snydech03' WHERE `lahman_id` = 19419 AND `player_id` = 'snydech03';
UPDATE `master`        SET `bbref_id`  = 'gilgahu01' WHERE `lahman_id` = 19417 AND `player_id` = 'gilgahu01';
UPDATE `AwardsPlayers` SET `player_id` = 'braunry02' WHERE `player_id` = 'braunry01' AND `award_id` = 'Silver Slugger' AND year_id = 2012 AND `lg_id` = 'NL';
UPDATE `AwardsPlayers` SET `player_id` = 'brechha01' WHERE `player_id` = 'Brecheen'  AND `award_id` = 'Baseball Magazine All-Star';

UPDATE awardsshareplayers 
  SET  award_id = (CASE award_id WHEN 'MVP' THEN 'MVP' WHEN 'Cy Young' THEN 'CyY' WHEN 'Rookie of the Year' THEN 'ROY' ELSE award_id END)
  WHERE (award_id IN ('MVP', 'Cy Young', 'Rookie of the Year'))
  ;
UPDATE awardsplayers 
  SET  award_id = (CASE award_id WHEN 'Most Valuable Player' THEN 'MVP' WHEN 'Cy Young Award' THEN 'CyY' WHEN 'Rookie of the Year' THEN 'ROY' ELSE award_id END)
  WHERE (award_id IN ('Most Valuable Player', 'Cy Young Award', 'Rookie of the Year'))
  ;

-- Old players, validated by hand
UPDATE `master`        SET `bbref_id`  = 'sulliwi01' WHERE `lahman_id` = 19416 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mckenpa01' WHERE `lahman_id` = 19415 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mckenfr01' WHERE `lahman_id` = 19414 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'ruppeja99' WHERE `lahman_id` = 19420 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'defrato99' WHERE `lahman_id` = 19413 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'crossjo01' WHERE `lahman_id` = 19418 AND `bbref_id` IS NULL;

-- Validated by hand, as no direct name match
UPDATE `master`        SET `bbref_id`  = 'harriwi10' WHERE `lahman_id` = 19359 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'griffaj01' WHERE `lahman_id` = 19308 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'polloaj01' WHERE `lahman_id` = 19233 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'ramosaj01' WHERE `lahman_id` = 19391 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'rosenbj01' WHERE `lahman_id` = 19300 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'fickch01'  WHERE `lahman_id` = 19279 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mitchdj01' WHERE `lahman_id` = 19248 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'hoovejj01' WHERE `lahman_id` = 19242 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'hoeslj01'  WHERE `lahman_id` = 19409 AND `bbref_id` IS NULL;

-- Validated by matching: (first+last name in bdb = common name in WAR; debut was 2012; WAR table year was 2012)
UPDATE `master`        SET `bbref_id`  = 'cespeyo01' WHERE `lahman_id` = 19207 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'galvifr01' WHERE `lahman_id` = 19208 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'pastoty01' WHERE `lahman_id` = 19209 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'aokino01'  WHERE `lahman_id` = 19210 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'gonzama01' WHERE `lahman_id` = 19211 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'komater01' WHERE `lahman_id` = 19212 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'komater01' WHERE `lahman_id` = 19212 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'vogtst01'  WHERE `lahman_id` = 19213 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'cruzrh01'  WHERE `lahman_id` = 19214 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'flahery01' WHERE `lahman_id` = 19215 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'haguema01' WHERE `lahman_id` = 19216 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'kawasmu01' WHERE `lahman_id` = 19217 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'luetglu01' WHERE `lahman_id` = 19218 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'nieuwki01' WHERE `lahman_id` = 19219 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'oteroda01' WHERE `lahman_id` = 19220 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'jonesna01' WHERE `lahman_id` = 19221 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'phelpda01' WHERE `lahman_id` = 19222 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'rossro01'  WHERE `lahman_id` = 19223 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'castile01' WHERE `lahman_id` = 19224 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'darviyu01' WHERE `lahman_id` = 19225 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'ramirer02' WHERE `lahman_id` = 19226 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'chenwe02'  WHERE `lahman_id` = 19227 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'smylydr01' WHERE `lahman_id` = 19228 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'carpeda02' WHERE `lahman_id` = 19229 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'linch01'   WHERE `lahman_id` = 19230 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'wielajo01' WHERE `lahman_id` = 19231 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'crawfev01' WHERE `lahman_id` = 19232 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'iwakuhi01' WHERE `lahman_id` = 19234 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'figuepe01' WHERE `lahman_id` = 19235 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'hutchdr01' WHERE `lahman_id` = 19236 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'peralwi01' WHERE `lahman_id` = 19237 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'weberth01' WHERE `lahman_id` = 19238 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'hefneje01' WHERE `lahman_id` = 19239 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'valdejo02' WHERE `lahman_id` = 19240 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'lutzza01'  WHERE `lahman_id` = 19241 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'harpebr03' WHERE `lahman_id` = 19243 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'moorety01' WHERE `lahman_id` = 19244 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'putkolu01' WHERE `lahman_id` = 19245 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'corbipa01' WHERE `lahman_id` = 19246 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'jennida01' WHERE `lahman_id` = 19247 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'middlwi01' WHERE `lahman_id` = 19249 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'exposlu01' WHERE `lahman_id` = 19250 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mikolmi01' WHERE `lahman_id` = 19251 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'faluir01'  WHERE `lahman_id` = 19252 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'cardead01' WHERE `lahman_id` = 19253 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'doziebr01' WHERE `lahman_id` = 19254 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'pomerst01' WHERE `lahman_id` = 19255 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'quintjo01' WHERE `lahman_id` = 19256 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'friedch01' WHERE `lahman_id` = 19257 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'vanslsc01' WHERE `lahman_id` = 19258 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mattike01' WHERE `lahman_id` = 19259 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'averyxa01' WHERE `lahman_id` = 19260 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'costami01' WHERE `lahman_id` = 19261 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'culbech01' WHERE `lahman_id` = 19262 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'gomezma01' WHERE `lahman_id` = 19263 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'leonsa01'  WHERE `lahman_id` = 19264 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'diekmja01' WHERE `lahman_id` = 19265 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'herreel01' WHERE `lahman_id` = 19266 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'gomesya01' WHERE `lahman_id` = 19267 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'parkebl01' WHERE `lahman_id` = 19268 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'carsoro01' WHERE `lahman_id` = 19269 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'lallibl01' WHERE `lahman_id` = 19270 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'adamsma01' WHERE `lahman_id` = 19271 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'hernago01' WHERE `lahman_id` = 19272 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'hernago01' WHERE `lahman_id` = 19272 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'solando01' WHERE `lahman_id` = 19273 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'calhoko01' WHERE `lahman_id` = 19274 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'berryqu01' WHERE `lahman_id` = 19275 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'smithwi04' WHERE `lahman_id` = 19276 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'devrico01' WHERE `lahman_id` = 19277 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'diazju02'  WHERE `lahman_id` = 19278 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'gonzami03' WHERE `lahman_id` = 19280 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mercejo03' WHERE `lahman_id` = 19281 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'solanjh01' WHERE `lahman_id` = 19282 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'barnesc01' WHERE `lahman_id` = 19283 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'casteal01' WHERE `lahman_id` = 19284 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'crosbca01' WHERE `lahman_id` = 19285 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'freemsa01' WHERE `lahman_id` = 19286 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'grandya01' WHERE `lahman_id` = 19287 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'pryorst01' WHERE `lahman_id` = 19288 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'simmoan01' WHERE `lahman_id` = 19289 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'ramirel02' WHERE `lahman_id` = 19290 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'doolise01' WHERE `lahman_id` = 19291 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'holadbr01' WHERE `lahman_id` = 19292 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'danksjo02' WHERE `lahman_id` = 19293 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'negrokr01' WHERE `lahman_id` = 19294 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'schepta01' WHERE `lahman_id` = 19295 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'tollesh01' WHERE `lahman_id` = 19296 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'ortegjo01' WHERE `lahman_id` = 19297 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'robincl01' WHERE `lahman_id` = 19298 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'perezhe01' WHERE `lahman_id` = 19299 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'boxbebr01' WHERE `lahman_id` = 19301 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'kellyjo05' WHERE `lahman_id` = 19302 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'grimmju01' WHERE `lahman_id` = 19303 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'keuchda01' WHERE `lahman_id` = 19304 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'thornty01' WHERE `lahman_id` = 19305 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'archech01' WHERE `lahman_id` = 19306 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'norride01' WHERE `lahman_id` = 19307 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'roberty01' WHERE `lahman_id` = 19309 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'vinceni01' WHERE `lahman_id` = 19310 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'cabreed01' WHERE `lahman_id` = 19311 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'perezma02' WHERE `lahman_id` = 19312 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'bauertr01' WHERE `lahman_id` = 19313 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'septile01' WHERE `lahman_id` = 19314 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'warread01' WHERE `lahman_id` = 19315 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'brownba01' WHERE `lahman_id` = 19316 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'downsda02' WHERE `lahman_id` = 19317 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'omogrbr01' WHERE `lahman_id` = 19318 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'dysonsa01' WHERE `lahman_id` = 19319 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mahonjo01' WHERE `lahman_id` = 19320 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'biancje01' WHERE `lahman_id` = 19321 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'edginjo01' WHERE `lahman_id` = 19322 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'rutlejo01' WHERE `lahman_id` = 19323 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'avilalu01' WHERE `lahman_id` = 19324 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'loupaa01'  WHERE `lahman_id` = 19325 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'socolmi01' WHERE `lahman_id` = 19326 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'socolmi01' WHERE `lahman_id` = 19326 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'johnsst02' WHERE `lahman_id` = 19327 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'fifest01'  WHERE `lahman_id` = 19328 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'gosean01'  WHERE `lahman_id` = 19329 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'verdury01' WHERE `lahman_id` = 19330 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'hernape02' WHERE `lahman_id` = 19331 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'rosentr01' WHERE `lahman_id` = 19332 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'allenco01' WHERE `lahman_id` = 19333 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'wheelry01' WHERE `lahman_id` = 19334 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'belivje01' WHERE `lahman_id` = 19335 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'walljo02'  WHERE `lahman_id` = 19336 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'segurje01' WHERE `lahman_id` = 19337 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'segurje01' WHERE `lahman_id` = 19337 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'harvema01' WHERE `lahman_id` = 19338 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'hendeji01' WHERE `lahman_id` = 19339 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'martest01' WHERE `lahman_id` = 19340 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'sierrmo01' WHERE `lahman_id` = 19341 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'cabreal03' WHERE `lahman_id` = 19342 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'oltmi01'   WHERE `lahman_id` = 19343 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'rodried04' WHERE `lahman_id` = 19344 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'cappsca01' WHERE `lahman_id` = 19345 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'storemi01' WHERE `lahman_id` = 19346 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'straida01' WHERE `lahman_id` = 19347 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'burnsco01' WHERE `lahman_id` = 19348 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'hechaad01' WHERE `lahman_id` = 19349 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mcbrima02' WHERE `lahman_id` = 19350 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'jacksbr01' WHERE `lahman_id` = 19351 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'vittejo01' WHERE `lahman_id` = 19352 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'barnebr02' WHERE `lahman_id` = 19353 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'jenkich01' WHERE `lahman_id` = 19354 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'raleybr01' WHERE `lahman_id` = 19355 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'machama01' WHERE `lahman_id` = 19356 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'elmorja01' WHERE `lahman_id` = 19357 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'jacksry02' WHERE `lahman_id` = 19358 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'brantro01' WHERE `lahman_id` = 19360 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'layneto01' WHERE `lahman_id` = 19361 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'geltzst01' WHERE `lahman_id` = 19362 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'redmoto01' WHERE `lahman_id` = 19363 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mcpheky01' WHERE `lahman_id` = 19364 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'wilsoju10' WHERE `lahman_id` = 19365 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'rusinch01' WHERE `lahman_id` = 19366 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'skaggty01' WHERE `lahman_id` = 19367 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'wernean01' WHERE `lahman_id` = 19368 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'aumonph01' WHERE `lahman_id` = 19369 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mchugco01' WHERE `lahman_id` = 19370 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'peguefr01' WHERE `lahman_id` = 19371 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'kellyca01' WHERE `lahman_id` = 19372 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'cloydty01' WHERE `lahman_id` = 19373 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'lerudst01' WHERE `lahman_id` = 19374 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'garciav01' WHERE `lahman_id` = 19375 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'heathde01' WHERE `lahman_id` = 19376 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'holtbr01'  WHERE `lahman_id` = 19377 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'loughda01' WHERE `lahman_id` = 19378 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'perezeu01' WHERE `lahman_id` = 19379 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'maronni01' WHERE `lahman_id` = 19380 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'nealth01'  WHERE `lahman_id` = 19381 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'profaju01' WHERE `lahman_id` = 19382 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'rodrihe04' WHERE `lahman_id` = 19383 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'machije01' WHERE `lahman_id` = 19384 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'phippde01' WHERE `lahman_id` = 19385 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'chapmja02' WHERE `lahman_id` = 19386 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'eatonad02' WHERE `lahman_id` = 19387 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'familje01' WHERE `lahman_id` = 19388 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'garcich02' WHERE `lahman_id` = 19389 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'jimenlu01' WHERE `lahman_id` = 19390 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'gregodi01' WHERE `lahman_id` = 19392 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'koehlto01' WHERE `lahman_id` = 19393 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'millesh01' WHERE `lahman_id` = 19394 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'villape01' WHERE `lahman_id` = 19395 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'grahaty01' WHERE `lahman_id` = 19396 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'triunca01' WHERE `lahman_id` = 19397 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'cingrto01' WHERE `lahman_id` = 19398 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'rodrist02' WHERE `lahman_id` = 19399 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'scahiro01' WHERE `lahman_id` = 19400 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'morribr01' WHERE `lahman_id` = 19401 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'rufda01'   WHERE `lahman_id` = 19402 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'herrmch01' WHERE `lahman_id` = 19403 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'solisal01' WHERE `lahman_id` = 19404 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'fontwi01'  WHERE `lahman_id` = 19405 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'mesame01'  WHERE `lahman_id` = 19406 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'bundydy01' WHERE `lahman_id` = 19407 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'odorija01' WHERE `lahman_id` = 19408 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'tayloan01' WHERE `lahman_id` = 19410 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'ortegra01' WHERE `lahman_id` = 19411 AND `bbref_id` IS NULL;
UPDATE `master`        SET `bbref_id`  = 'brummty01' WHERE `lahman_id` = 19412 AND `bbref_id` IS NULL;

UPDATE `master`        SET `hof_id`    = 'kleskry01h' WHERE `player_id` = 'kleskry01' AND name_last = 'Klesko' AND hof_id = 'kleskry01';

-- confirmed against MLB stats
UPDATE `bat_stints`       SET `AB` = 21 WHERE player_id = "phillan01" AND year_id = 2008 AND stint_id = 1 AND team_id = "CIN";

DELETE FROM `master` WHERE name_first = 'nameFirst';

-- SELECT (CONCAT(peep.`nameFirst`, ' ', peep.`nameLast`) = bw.`nameCommon`) AS name_match,
--   peep.`lahman_id`, peep.`player_id`, bw.`bbref_id`, peep.`bbref_id`, bw.`lahman_id`, bw.year_id,
--   peep.`nameFirst`, peep.`nameLast`, bw.`nameCommon`
--   FROM people peep
--   LEFT JOIN `bat_stints_war` bw ON (peep.`player_id` = bw.`bbref_id`)
--   WHERE (peep.`bbref_id` IS NULL)
--   ORDER BY name_match ASC
--   ;

-- ===========================================================================
--
-- Restore Indices for 2012 Baseball Databank
--

SELECT NOW() AS starting_datetime, "Beg adding indexes to tables", n_ma, n_bat, n_pit, n_tms, n_app
  from
    (SELECT COUNT(*) AS n_ma  FROM master)      ma,
    (SELECT COUNT(*) AS n_bat FROM bat_stints)  bat,
    (SELECT COUNT(*) AS n_pit FROM pit_stints)  pit,
    (SELECT COUNT(*) AS n_tms FROM teams)       tms,
    (SELECT COUNT(*) AS n_app FROM appearances) app
  ;

ALTER TABLE `master`
  ADD UNIQUE KEY `player`  (`player_id`),
  ADD UNIQUE KEY `bbref`   (`bbref_id`),
  ADD UNIQUE KEY `retro`   (`retro_id`,`bbref_id`),
  ADD UNIQUE KEY `manager` (`manager_id`),
  ADD UNIQUE KEY `hof`     (`hof_id`)
  ;
ALTER TABLE teams
  ADD UNIQUE KEY `team`     (`team_id`,`year_id`,`lg_id`),
  ADD KEY        `franch`   (`franch_id`)
  ;
ALTER TABLE teamshalf
  ADD UNIQUE KEY `team`     (`team_id`,`year_id`,`lg_id`, `half_id`)
  ;
ALTER TABLE bat_stints
  ADD KEY        `team`     (`team_id`,  `year_id`,`lg_id`,`stint_id`)
  ;
ALTER TABLE pit_stints
  ADD KEY        `team`     (`team_id`,  `year_id`,`lg_id`,`stint_id`)
  ;
ALTER TABLE fld_stints
  ADD KEY        `team`     (`team_id`,  `year_id`,`lg_id`,`stint_id`)
  ;
ALTER TABLE bat_posts
  ADD UNIQUE KEY `player`   (`player_id`,`year_id`,`round_id`),
  ADD KEY        `team`     (`team_id`,  `year_id`,`round_id`),
  ADD KEY        `round`    (`year_id`,  `round_id`,`lg_id`)
  ;
ALTER TABLE pit_posts
  ADD UNIQUE KEY `player`   (`player_id`,`year_id`,`round_id`),
  ADD KEY        `team`     (`team_id`,  `year_id`,`round_id`),
  ADD KEY        `round`    (`year_id`,  `round_id`,`lg_id`)
  ;
ALTER TABLE fld_posts
  ADD UNIQUE KEY `player`   (`player_id`,`year_id`,`round_id`,`POS`),
  ADD KEY        `team`     (`team_id`,  `year_id`,`round_id`),
  ADD KEY        `round`    (`year_id`,  `round_id`,`lg_id`)
  ;
ALTER TABLE managers
  ADD UNIQUE KEY `manager`  (`manager_id`,`year_id`,`team_id`,`inseason`),
  ADD KEY        `team`     (`team_id`,`year_id`,`lg_id`)
  ;
ALTER TABLE salaries
  ADD UNIQUE KEY `player`   (`player_id`,`year_id`,`team_id`, `lg_id`)
  ;
ALTER TABLE appearances
  ADD UNIQUE KEY `player`   (`player_id`,`year_id`,`team_id`),
  ADD KEY        `team`     (`team_id`,`year_id`,`lg_id`)
  ;


SELECT NOW() AS starting_datetime, "End adding indexes to tables", n_ma, n_bat, n_pit, n_tms, n_app
  from
    (SELECT COUNT(*) AS n_ma  FROM master)      ma,
    (SELECT COUNT(*) AS n_bat FROM bat_stints)  bat,
    (SELECT COUNT(*) AS n_pit FROM pit_stints)  pit,
    (SELECT COUNT(*) AS n_tms FROM teams)       tms,
    (SELECT COUNT(*) AS n_app FROM appearances) app
  ;
