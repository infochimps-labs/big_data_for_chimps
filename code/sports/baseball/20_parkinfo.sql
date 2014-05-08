-- tail -n+2 parkinfo.tsv | ruby -ne 'park_id,parkname,beg_date,end_date,is_active,n_games,lat,lng,allteams,allnames,streetaddr,extaddr,city,state,country,zip,tel,url,url_spanish,logofile,comments = $_.split("\t"); teams = allteams.split(/; /); teams.each{|team| m = /^(...) \((\d+)-(\d+|now)\)( \[alt\])?/.match(team) ; unless m then p team ; next ; end ; team_id, t_begYear, t_endYear, alt = m.captures.to_a; puts [park_id, team_id, t_begYear, t_endYear, alt.nil? ? 0 : 1, n_games].join("\t") }' | sort > park-team-seasons-b.tsv
-- cat parkinfo-all.xml |  ruby -e 'park_id, begYear, endYear = ["","",""]; $stdin.readlines[1..-2].each{|line| case when (line =~ %r{<park park_id="(.....)".*beg="([^"\-]+).*end="([^"\-]+)}) then park_id, begParkYear, endParkYear = [$1, $2, $3] ; when line =~ %r{<team></team>} then next ; when line =~ %r{<team} then line =~ %r{team_id="(...)" beg="([^"]+)" end="([^"]+)" games="(\d+)"(?: neutralsite="(.)")?} or (p line; next) ; by, ey = [$2, $3] ; next if (by == "NULL" && ey == "NULL") ; begUseYear = by[0..3].to_i; endUseYear = (ey =="NULL" ? 2013: ey[0..3].to_i); (begUseYear .. endUseYear).each{|year_id| puts [park_id, $1, year_id, $2, $3, $4, $5||"0"].join("\t") } ; end }'
-- SELECT GROUP_CONCAT(DISTINCT home_team_id), park_id, SUBSTR(game_id, 4,4) AS year_id, COUNT(*) AS n_games, COUNT(DISTINCT home_team_id) AS n_teams
--   FROM games
--   WHERE park_id != ""
--   GROUP BY park_id, year_id
--   HAVING n_teams > 1
--   ORDER BY year_id

DROP TABLE IF EXISTS `parks`;
CREATE TABLE `parks` (
  `park_id`     VARCHAR(6       ) NOT NULL,
  `park_name`   VARCHAR(255) DEFAULT NULL,
  `beg_date`    DATE DEFAULT NULL,
  `end_date`    DATE DEFAULT NULL,
  `is_active`      BOOLEAN,
  `n_games`     INT(4),
  `lat`         FLOAT,
  `lng`         FLOAT,
  `allteams`    VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `allnames`    VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `streetaddr`  VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `extaddr`     VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `city`        VARCHAR(100) DEFAULT NULL,
  `state`       VARCHAR(3) DEFAULT NULL,
  `country`     VARCHAR(100) DEFAULT NULL,
  `zip`         VARCHAR(20) DEFAULT NULL,
  `tel`         VARCHAR(20) DEFAULT NULL,
  `url`         VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `url_spanish` VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `logofile`    VARCHAR(255) CHARSET ascii DEFAULT NULL,
  `comments`    VARCHAR(1024) CHARSET ascii DEFAULT NULL,
  PRIMARY KEY (`park_id`),
  KEY         (`beg_date`),
  KEY         (`park_name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

LOAD DATA INFILE '/Users/flip/ics/book/big_data_for_chimps/data/sports/baseball/baseball_databank/parks/parkinfo.tsv'
  REPLACE INTO TABLE `parks`
  FIELDS TERMINATED BY '\t' ENCLOSED BY '"' ESCAPED BY '\\'
  IGNORE 1 ROWS
  ( `park_id`, `park_name`, `beg_date`, `end_date`, `is_active`, `n_games`, `lat`, `lng`,
  `allteams`, `allnames`, `streetaddr`, `extaddr`, `city`, `state`, `country`,
  `zip`, `tel`, `url`, `url_spanish`, `logofile`, `comments` )
  ;

DROP TABLE IF EXISTS `park_team_years`;
CREATE TABLE `park_team_years` (
  `park_id`    VARCHAR(6) NOT NULL,
  `team_id`    VARCHAR(255) NOT NULL DEFAULT '',
  `year_id`    INT(4) NOT NULL DEFAULT '0',
  `beg_date`   DATE DEFAULT NULL,
  `end_date`   DATE DEFAULT NULL,
  `n_games`   INT(4) DEFAULT NULL,
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
