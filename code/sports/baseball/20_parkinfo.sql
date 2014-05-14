-- tail -n+2 parkinfo.tsv | ruby -ne 'park_id,parkname,beg_date,end_date,is_active,n_games,lat,lng,allteams,allnames,streetaddr,extaddr,city,state,country,zip,tel,url,url_spanish,logofile,comments = $_.split("\t"); teams = allteams.split(/; /); teams.each{|team| m = /^(...) \((\d+)-(\d+|now)\)( \[alt\])?/.match(team) ; unless m then p team ; next ; end ; team_id, t_begYear, t_endYear, alt = m.captures.to_a; puts [park_id, team_id, t_begYear, t_endYear, alt.nil? ? 0 : 1, n_games].join("\t") }' | sort > park-team-seasons-b.tsv
-- cat parkinfo-all.xml |  ruby -e 'park_id, begYear, endYear = ["","",""]; $stdin.readlines[1..-2].each{|line| case when (line =~ %r{<park park_id="(.....)".*beg="([^"\-]+).*end="([^"\-]+)}) then park_id, begParkYear, endParkYear = [$1, $2, $3] ; when line =~ %r{<team></team>} then next ; when line =~ %r{<team} then line =~ %r{team_id="(...)" beg="([^"]+)" end="([^"]+)" games="(\d+)"(?: neutralsite="(.)")?} or (p line; next) ; by, ey = [$2, $3] ; next if (by == "NULL" && ey == "NULL") ; begUseYear = by[0..3].to_i; endUseYear = (ey =="NULL" ? 2013: ey[0..3].to_i); (begUseYear .. endUseYear).each{|year_id| puts [park_id, $1, year_id, $2, $3, $4, $5||"0"].join("\t") } ; end }'
-- SELECT GROUP_CONCAT(DISTINCT home_team_id), park_id, SUBSTR(game_id, 4,4) AS year_id, COUNT(*) AS n_games, COUNT(DISTINCT home_team_id) AS n_teams
--   FROM games
--   WHERE park_id != ""
--   GROUP BY park_id, year_id
--   HAVING n_teams > 1
--   ORDER BY year_id

SELECT NOW() AS starting_datetime, 'Loading parks';

DROP TABLE IF EXISTS `parks`;
CREATE TABLE `parks` (
  `park_id`     VARCHAR(6) NOT NULL,
  `park_name`   VARCHAR(255) DEFAULT NULL,
  `beg_date`    DATE DEFAULT NULL,
  `end_date`    DATE DEFAULT NULL,
  `is_active`   BOOLEAN,
  `n_games`     INT(4),
  `lng`         FLOAT,
  `lat`         FLOAT,
  `city`        VARCHAR(100) DEFAULT NULL,
  `state`       VARCHAR(3) DEFAULT NULL,
  `country`     VARCHAR(100) DEFAULT NULL,
  `zip`         VARCHAR(20) DEFAULT NULL,
  `streetaddr`  VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `extaddr`     VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `tel`         VARCHAR(20) DEFAULT NULL,
  `url`         VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `url_spanish` VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `logofile`    VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `allteams`    VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `allnames`    VARCHAR(1024) CHARSET ascii DEFAULT NULL,
  `comments`    VARCHAR(1024) CHARSET ascii DEFAULT NULL,
  PRIMARY KEY (`park_id`),
  KEY         (`beg_date`),
  KEY         (`park_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOAD DATA INFILE '/Users/flip/ics/book/big_data_for_chimps/data/sports/baseball/baseball_databank/parks/parkinfo.tsv'
  REPLACE INTO TABLE `parks`
  FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\'
  IGNORE 1 ROWS
  ( `park_id`, `park_name`, `beg_date`, `end_date`, `is_active`, `n_games`, `lng`, `lat`,
  `allteams`, `allnames`, `streetaddr`, `extaddr`, `city`, `state`, `country`,
  `zip`, `tel`, `url`, `url_spanish`, `logofile`, `comments` )
  ;


SELECT NOW() AS starting_datetime, 'Loading parks from retrosheet';

DROP TABLE IF EXISTS `parks_raw`;
CREATE TABLE `parks_raw` (
  `park_id`     CHAR(6) NOT NULL,
  `park_name`   VARCHAR(255) DEFAULT NULL,
  `allnames`    VARCHAR(255) CHARSET ASCII DEFAULT NULL,
  `city`        VARCHAR(100) DEFAULT NULL,
  `state`       VARCHAR(3) DEFAULT NULL,
  `beg_date`    DATE DEFAULT NULL,
  `end_date`    DATE DEFAULT NULL,
  `comments`    VARCHAR(1024) CHARSET ASCII DEFAULT NULL,
  PRIMARY KEY (`park_id`),
  KEY         (`beg_date`),
  KEY         (`park_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
LOAD DATA INFILE '/Users/flip/ics/book/big_data_for_chimps/data/sports/baseball/baseball_databank/parks/parkcode.txt'
  REPLACE INTO TABLE `parks_raw`
  FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\'
  IGNORE 1 ROWS
  ( `park_id`, `park_name`, `allnames`,  `city`, `state`, @beg_date, @end_date, @dummy, `comments` )
  SET beg_date = STR_TO_DATE(@beg_date, '%m/%d/%Y'), end_date = STR_TO_DATE(@end_date, '%m/%d/%Y')
  ;


SELECT NOW() AS starting_datetime, 'Loading parks from seamheads';

DROP TABLE IF EXISTS `parks_sh`;
CREATE TABLE `parks_sh` (
  `park_id`     CHAR(6) NOT NULL,
  `park_name`   VARCHAR(255) DEFAULT NULL,
  `city_st`     VARCHAR(100) DEFAULT NULL,
  `beg_date`    DATE DEFAULT NULL,
  `end_date`    DATE DEFAULT NULL,
  -- `n_seasons`   INTEGER,
  `n_games`     INTEGER,
  `lng`         FLOAT,
  `lat`         FLOAT,
  `n_alt`         INTEGER,
  PRIMARY KEY (`park_id`),
  KEY         (`park_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
LOAD DATA INFILE '/Users/flip/ics/book/big_data_for_chimps/data/sports/baseball/baseball_databank/parks/seamheads.tsv'
  REPLACE INTO TABLE `parks_sh`
  FIELDS TERMINATED BY '\t' ESCAPED BY '\\'
  ( `park_id`, `park_name`, `city_st`, @beg_date, @end_date, `n_games`, `lat`, `lng`, `n_alt`)
  SET beg_date = STR_TO_DATE(@beg_date, '%m/%d/%Y'), end_date = STR_TO_DATE(@end_date, '%m/%d/%Y')
  ;

-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Creating park usage info from gamelogs';
--

DROP TABLE IF EXISTS `park_team_years`;
CREATE TABLE `park_team_years` (
  `park_id`    VARCHAR(6) NOT NULL,
  `team_id`    VARCHAR(255) NOT NULL DEFAULT '',
  `year_id`    INT(4) NOT NULL DEFAULT '0',
  `beg_date`   DATE DEFAULT NULL,
  `end_date`   DATE DEFAULT NULL,
  `n_games`    INT(4) DEFAULT NULL,
  `is_main`    BOOLEAN DEFAULT NULL,
  PRIMARY KEY        (`park_id`,`team_id`,`year_id`),
  UNIQUE KEY  `team` (`team_id`,`year_id`,`park_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

INSERT INTO `park_team_years` (park_id, team_id, year_id, beg_date, end_date, n_games)
  SELECT
      park_id, home_team_id AS team_id, year_id,
      MIN(game_date) AS beg_date, MAX(game_date) AS end_date,
      COUNT(*) AS n_games
    FROM     retrosheet.games
    WHERE    park_id != ""
    GROUP BY park_id, team_id, year_id
    ORDER BY park_id, team_id, year_id
    ;

-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Updating park_team_years to show main/alternate parks';
--

DROP TEMPORARY TABLE IF EXISTS `ptymain`;
CREATE TEMPORARY TABLE `ptymain` (
  SELECT pty.*, (n_games = main_games) AS is_main, parks
    FROM park_team_years pty,
      (SELECT team_id, year_id, MAX(n_games) AS main_games,
          GROUP_CONCAT(park_id, ':', n_games ORDER BY n_games DESC SEPARATOR '-') AS parks,
          COUNT(*) AS n_parks FROM park_team_years GROUP BY team_id, year_id) mainpk
  WHERE pty.team_id = mainpk.team_id AND pty.year_id = mainpk.year_id
  ORDER BY n_parks DESC, pty.team_id, pty.year_id, pty.n_games DESC
  );
UPDATE park_team_years pty, ptymain
  SET pty.is_main = ptymain.is_main
  WHERE pty.park_id = ptymain.park_id AND pty.year_id = ptymain.year_id AND pty.team_id = ptymain.team_id
  ;

SELECT NOW() AS starting_datetime, 'Updating parkinfo for correct tenure from park_team_years';

DROP TEMPORARY TABLE IF EXISTS `parks_fixed`;
CREATE TEMPORARY TABLE `parks_fixed` (SELECT * FROM `parks`);
UPDATE parks_fixed pfx, (
  SELECT park_id, GROUP_CONCAT(DISTINCT team_id ORDER BY is_main DESC, team_id DESC SEPARATOR '; ') AS team_ids,
      MIN(beg_date) AS beg_date, MAX(end_date) AS end_date,
      SUM(n_games) AS n_games, (MAX(end_date) > DATE('2013-01-01')) AS is_active
    FROM (SELECT park_id,
      CONCAT(team_id, ' (', SUM(n_games), ':', MIN(year_id), '-', IF(MAX(year_id) >= 2006, 'now', MAX(year_id)), IF(MIN(is_main), '', ' alt'), ')') AS team_id,
      MIN(beg_date) AS beg_date, MAX(end_date) AS end_date,
      SUM(n_games) AS n_games, MIN(is_main) AS is_main
      FROM park_team_years WHERE year_id <= 2050 GROUP BY park_id, team_id) pty1
    GROUP BY park_id) AS pn
  SET allteams = team_ids, pfx.beg_date = pn.beg_date, pfx.end_date = pn.end_date, pfx.n_games = pn.n_games, pfx.is_active = pn.is_active
  WHERE pn.park_id = pfx.park_id;


-- ===========================================================================
--
SELECT NOW() AS starting_datetime, 'Updating parks info from park_team_years and seamheads';
--

UPDATE parks pfx, (
  SELECT park_id, GROUP_CONCAT(DISTINCT team_id ORDER BY is_main DESC, team_id DESC SEPARATOR '; ') AS team_ids,
      MIN(beg_date) AS beg_date, MAX(end_date) AS end_date,
      SUM(n_games) AS n_games, (MAX(end_date) > DATE('2013-01-01')) AS is_active
    FROM (SELECT park_id,
      CONCAT(team_id, ' (', SUM(n_games), ':', MIN(year_id), '-', IF(MAX(year_id) >= 2006, 'now', MAX(year_id)), IF(MIN(is_main), '', ' alt'), ')') AS team_id,
      MIN(beg_date) AS beg_date, MAX(end_date) AS end_date,
      SUM(n_games) AS n_games, MIN(is_main) AS is_main
      FROM park_team_years WHERE year_id <= 2050 GROUP BY park_id, team_id) pty1
    GROUP BY park_id) AS pn
  SET allteams = team_ids, pfx.beg_date = pn.beg_date, pfx.end_date = pn.end_date, pfx.n_games = pn.n_games, pfx.is_active = pn.is_active
  WHERE pn.park_id = pfx.park_id;

UPDATE parks pfx, parks_sh pn
  SET   pfx.lat = pn.lat, pfx.lng = pn.lng, pfx.city = REPLACE(pfx.city, 'Saint ', 'St. ')
  WHERE pn.park_id = pfx.park_id
  ;

--
-- Spot Checking
--

-- SELECT psh.park_id, psh.park_name, pfx.park_name, psh.city_st, CONCAT(pfx.city, ', ', pfx.state) AS p_city_st,
--     ( TRUE
--       AND (CONCAT(pfx.city, ', ', pfx.state) = psh.city_st)
--       -- AND ((psh.park_name = pfx.park_name) OR INSTR(pfx.park_name, psh.park_name))
--       AND psh.beg_date = pfx.beg_date
--       AND ((psh.end_date = pfx.end_date) OR (psh.end_date = "0000-00-00"))
--       ) AS is_match,
--       psh.lat, pfx.lat, psh.lng, pfx.lng, 
--     psh.beg_date, pfx.beg_date, psh.end_date, pfx.end_date
--   FROM 
--   parks_sh psh
--   LEFT JOIN parks pfx
--   ON psh.park_id = pfx.park_id
--   -- WHERE (ABS(pfx.lat - psh.lat) > 0.03) OR (ABS(pfx.lng - psh.lng) > 0.03)
--   ORDER BY is_match ASC
-- ;
