# ************************************************************
# Sequel Pro SQL dump
# Version 4096
#
# http://www.sequelpro.com/
# http://code.google.com/p/sequel-pro/
#
# Host: localhost (MySQL 5.6.13)
# Database: lahman
# Generation Time: 2014-04-14 01:21:24 +0000
# ************************************************************


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


# Dump of table allstar
# ------------------------------------------------------------

DROP TABLE IF EXISTS `allstar`;

CREATE TABLE `allstar` (
  `player_id` varchar(9) NOT NULL,
  `year_id` int(11) NOT NULL,
  `game_seq` int(11) NOT NULL,
  `game_id` varchar(12) DEFAULT NULL,
  `team_id` varchar(3) DEFAULT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `GP` int(11) DEFAULT NULL,
  `pos_starting` int(11) DEFAULT NULL,
  PRIMARY KEY (`player_id`,`year_id`,`game_seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table appearances
# ------------------------------------------------------------

DROP TABLE IF EXISTS `appearances`;

CREATE TABLE `appearances` (
  `year_id` int(11) NOT NULL,
  `team_id` varchar(3) NOT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `player_id` varchar(9) NOT NULL,
  `G_all` int(11) DEFAULT NULL,
  `G_batting` int(11) DEFAULT NULL,
  `G_defense` int(11) DEFAULT NULL,
  `G_p` int(11) DEFAULT NULL,
  `G_c` int(11) DEFAULT NULL,
  `G_1b` int(11) DEFAULT NULL,
  `G_2b` int(11) DEFAULT NULL,
  `G_3b` int(11) DEFAULT NULL,
  `G_ss` int(11) DEFAULT NULL,
  `G_lf` int(11) DEFAULT NULL,
  `G_cf` int(11) DEFAULT NULL,
  `G_rf` int(11) DEFAULT NULL,
  `G_of` int(11) DEFAULT NULL,
  `G_dh` int(11) DEFAULT NULL,
  `G_ph` int(11) DEFAULT NULL,
  `G_pr` int(11) DEFAULT NULL,
  PRIMARY KEY (`year_id`,`team_id`,`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table awardsmanagers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `awardsmanagers`;

CREATE TABLE `awardsmanagers` (
  `manager_id` varchar(10) NOT NULL,
  `award_id` varchar(25) NOT NULL,
  `year_id` int(11) NOT NULL,
  `lg_id` varchar(2) NOT NULL,
  `tie` varchar(1) DEFAULT NULL,
  `notes` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`year_id`,`award_id`,`lg_id`,`manager_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table awardsplayers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `awardsplayers`;

CREATE TABLE `awardsplayers` (
  `player_id` varchar(9) NOT NULL,
  `award_id` varchar(255) NOT NULL,
  `year_id` int(11) NOT NULL,
  `lg_id` varchar(2) NOT NULL,
  `tie` varchar(1) DEFAULT NULL,
  `notes` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`year_id`,`award_id`,`lg_id`,`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table awardssharemanagers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `awardssharemanagers`;

CREATE TABLE `awardssharemanagers` (
  `award_id` varchar(25) NOT NULL,
  `year_id` int(11) NOT NULL,
  `lg_id` varchar(2) NOT NULL,
  `manager_id` varchar(10) NOT NULL,
  `pointsWon` int(11) DEFAULT NULL,
  `pointsMax` int(11) DEFAULT NULL,
  `votesFirst` int(11) DEFAULT NULL,
  PRIMARY KEY (`award_id`,`year_id`,`lg_id`,`manager_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table awardsshareplayers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `awardsshareplayers`;

CREATE TABLE `awardsshareplayers` (
  `award_id` varchar(25) NOT NULL,
  `year_id` int(11) NOT NULL,
  `lg_id` varchar(2) NOT NULL,
  `player_id` varchar(9) NOT NULL,
  `pointsWon` double DEFAULT NULL,
  `pointsMax` int(11) DEFAULT NULL,
  `votesFirst` double DEFAULT NULL,
  PRIMARY KEY (`award_id`,`year_id`,`lg_id`,`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table bat_stints
# ------------------------------------------------------------

DROP TABLE IF EXISTS `bat_stints`;

CREATE TABLE `bat_stints` (
  `player_id` varchar(9) NOT NULL,
  `year_id` int(11) NOT NULL,
  `stint_id` int(11) NOT NULL,
  `team_id` varchar(3) DEFAULT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `G` int(11) DEFAULT NULL,
  `G_batting` int(11) DEFAULT NULL,
  `AB` int(11) DEFAULT NULL,
  `R` int(11) DEFAULT NULL,
  `H` int(11) DEFAULT NULL,
  `h2B` int(11) DEFAULT NULL,
  `h3B` int(11) DEFAULT NULL,
  `HR` int(11) DEFAULT NULL,
  `RBI` int(11) DEFAULT NULL,
  `SB` int(11) DEFAULT NULL,
  `CS` int(11) DEFAULT NULL,
  `BB` int(11) DEFAULT NULL,
  `SO` int(11) DEFAULT NULL,
  `IBB` int(11) DEFAULT NULL,
  `HBP` int(11) DEFAULT NULL,
  `SH` int(11) DEFAULT NULL,
  `SF` int(11) DEFAULT NULL,
  `GIDP` int(11) DEFAULT NULL,
  `G_old` int(11) DEFAULT NULL,
  PRIMARY KEY (`player_id`,`year_id`,`stint_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table battingpost
# ------------------------------------------------------------

DROP TABLE IF EXISTS `battingpost`;

CREATE TABLE `battingpost` (
  `year_id` int(11) NOT NULL,
  `round` varchar(10) NOT NULL,
  `player_id` varchar(9) NOT NULL,
  `team_id` varchar(3) DEFAULT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `G` int(11) DEFAULT NULL,
  `AB` int(11) DEFAULT NULL,
  `R` int(11) DEFAULT NULL,
  `H` int(11) DEFAULT NULL,
  `h2B` int(11) DEFAULT NULL,
  `h3B` int(11) DEFAULT NULL,
  `HR` int(11) DEFAULT NULL,
  `RBI` int(11) DEFAULT NULL,
  `SB` int(11) DEFAULT NULL,
  `CS` int(11) DEFAULT NULL,
  `BB` int(11) DEFAULT NULL,
  `SO` int(11) DEFAULT NULL,
  `IBB` int(11) DEFAULT NULL,
  `HBP` int(11) DEFAULT NULL,
  `SH` int(11) DEFAULT NULL,
  `SF` int(11) DEFAULT NULL,
  `GIDP` int(11) DEFAULT NULL,
  PRIMARY KEY (`year_id`,`round`,`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table fielding
# ------------------------------------------------------------

DROP TABLE IF EXISTS `fielding`;

CREATE TABLE `fielding` (
  `player_id` varchar(9) NOT NULL,
  `year_id` int(11) NOT NULL,
  `stint` int(11) NOT NULL,
  `team_id` varchar(3) DEFAULT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `POS` varchar(2) NOT NULL,
  `G` int(11) DEFAULT NULL,
  `GS` int(11) DEFAULT NULL,
  `InnOuts` int(11) DEFAULT NULL,
  `PO` int(11) DEFAULT NULL,
  `A` int(11) DEFAULT NULL,
  `E` int(11) DEFAULT NULL,
  `DP` int(11) DEFAULT NULL,
  `PB` int(11) DEFAULT NULL,
  `WP` int(11) DEFAULT NULL,
  `SB` int(11) DEFAULT NULL,
  `CS` int(11) DEFAULT NULL,
  `ZR` double DEFAULT NULL,
  PRIMARY KEY (`player_id`,`year_id`,`stint`,`POS`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table fieldingof
# ------------------------------------------------------------

DROP TABLE IF EXISTS `fieldingof`;

CREATE TABLE `fieldingof` (
  `player_id` varchar(9) NOT NULL,
  `year_id` int(11) NOT NULL,
  `stint` int(11) NOT NULL,
  `Glf` int(11) DEFAULT NULL,
  `Gcf` int(11) DEFAULT NULL,
  `Grf` int(11) DEFAULT NULL,
  PRIMARY KEY (`player_id`,`year_id`,`stint`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table fieldingpost
# ------------------------------------------------------------

DROP TABLE IF EXISTS `fieldingpost`;

CREATE TABLE `fieldingpost` (
  `player_id` varchar(9) NOT NULL,
  `year_id` int(11) NOT NULL,
  `team_id` varchar(3) DEFAULT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `round` varchar(10) NOT NULL,
  `POS` varchar(2) NOT NULL,
  `G` int(11) DEFAULT NULL,
  `GS` int(11) DEFAULT NULL,
  `InnOuts` int(11) DEFAULT NULL,
  `PO` int(11) DEFAULT NULL,
  `A` int(11) DEFAULT NULL,
  `E` int(11) DEFAULT NULL,
  `DP` int(11) DEFAULT NULL,
  `TP` int(11) DEFAULT NULL,
  `PB` int(11) DEFAULT NULL,
  `SB` int(11) DEFAULT NULL,
  `CS` int(11) DEFAULT NULL,
  PRIMARY KEY (`player_id`,`year_id`,`round`,`POS`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table halloffame
# ------------------------------------------------------------

DROP TABLE IF EXISTS `halloffame`;

CREATE TABLE `halloffame` (
  `hof_id` varchar(10) NOT NULL,
  `year_id` int(11) NOT NULL,
  `votedBy` varchar(64) DEFAULT NULL,
  `ballots` int(11) DEFAULT NULL,
  `needed` int(11) DEFAULT NULL,
  `votes` int(11) DEFAULT NULL,
  `inducted` varchar(1) DEFAULT NULL,
  `category` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`hof_id`,`year_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table hofold
# ------------------------------------------------------------

DROP TABLE IF EXISTS `hofold`;

CREATE TABLE `hofold` (
  `hof_id` varchar(10) NOT NULL,
  `yearid` int(11) DEFAULT NULL,
  `votedBy` varchar(10) DEFAULT NULL,
  `ballots` int(11) DEFAULT NULL,
  `votes` int(11) DEFAULT NULL,
  `inducted` varchar(1) DEFAULT NULL,
  `category` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`hof_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table managers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `managers`;

CREATE TABLE `managers` (
  `manager_id` varchar(10) DEFAULT NULL,
  `year_id` int(11) NOT NULL,
  `team_id` varchar(3) NOT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `inseason` int(11) NOT NULL,
  `G` int(11) DEFAULT NULL,
  `W` int(11) DEFAULT NULL,
  `L` int(11) DEFAULT NULL,
  `W_rank` int(11) DEFAULT NULL,
  `plyrMgr` varchar(1) DEFAULT NULL,
  PRIMARY KEY (`year_id`,`team_id`,`inseason`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table managershalf
# ------------------------------------------------------------

DROP TABLE IF EXISTS `managershalf`;

CREATE TABLE `managershalf` (
  `manager_id` varchar(10) NOT NULL,
  `year_id` int(11) NOT NULL,
  `team_id` varchar(3) NOT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `inseason` int(11) DEFAULT NULL,
  `half` int(11) NOT NULL,
  `G` int(11) DEFAULT NULL,
  `W` int(11) DEFAULT NULL,
  `L` int(11) DEFAULT NULL,
  `W_rank` int(11) DEFAULT NULL,
  PRIMARY KEY (`year_id`,`team_id`,`manager_id`,`half`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table master
# ------------------------------------------------------------

DROP TABLE IF EXISTS `master`;

CREATE TABLE `master` (
  `lahman_id` int(11) NOT NULL,
  `player_id` varchar(10) DEFAULT NULL,
  `manager_id` varchar(10) DEFAULT NULL,
  `hof_id` varchar(10) DEFAULT NULL,
  `birth_year` int(11) DEFAULT NULL,
  `birth_month` int(11) DEFAULT NULL,
  `birth_day` int(11) DEFAULT NULL,
  `birth_country` varchar(50) DEFAULT NULL,
  `birth_state` varchar(2) DEFAULT NULL,
  `birth_city` varchar(50) DEFAULT NULL,
  `death_year` int(11) DEFAULT NULL,
  `death_month` int(11) DEFAULT NULL,
  `death_day` int(11) DEFAULT NULL,
  `death_country` varchar(50) DEFAULT NULL,
  `death_state` varchar(2) DEFAULT NULL,
  `death_city` varchar(50) DEFAULT NULL,
  `name_first` varchar(50) DEFAULT NULL,
  `name_last` varchar(50) DEFAULT NULL,
  `name_note` varchar(255) DEFAULT NULL,
  `name_given` varchar(255) DEFAULT NULL,
  `name_nick` varchar(255) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  `height` double DEFAULT NULL,
  `bats` varchar(1) DEFAULT NULL,
  `throws` varchar(1) DEFAULT NULL,
  `first_game` varchar(10) DEFAULT NULL,
  `final_game` varchar(10) DEFAULT NULL,
  `college` varchar(50) DEFAULT NULL,
  `lahman40_id` varchar(9) DEFAULT NULL,
  `lahman45_id` varchar(9) DEFAULT NULL,
  `retro_id` varchar(9) DEFAULT NULL,
  `holtz_id` varchar(9) DEFAULT NULL,
  `bbref_id` varchar(9) DEFAULT NULL,
  PRIMARY KEY (`lahman_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table people
# ------------------------------------------------------------

DROP TABLE IF EXISTS `people`;

CREATE TABLE `people` (
  `lahman_id` int(11) NOT NULL DEFAULT '0',
  `player_id` char(9) CHARACTER SET ascii DEFAULT NULL,
  `bbref_id` char(9) CHARACTER SET ascii DEFAULT NULL,
  `retro_id` char(8) CHARACTER SET ascii DEFAULT NULL,
  `name_common` varchar(100) DEFAULT NULL,
  `birth_year` int(11) DEFAULT NULL,
  `birth_month` int(11) DEFAULT NULL,
  `birth_day` int(11) DEFAULT NULL,
  `birth_country` varchar(50) DEFAULT NULL,
  `birth_state` varchar(2) DEFAULT NULL,
  `birth_city` varchar(50) DEFAULT NULL,
  `death_year` int(11) DEFAULT NULL,
  `death_month` int(11) DEFAULT NULL,
  `death_day` int(11) DEFAULT NULL,
  `death_country` varchar(50) DEFAULT NULL,
  `death_state` varchar(2) DEFAULT NULL,
  `death_city` varchar(50) DEFAULT NULL,
  `name_first` varchar(50) DEFAULT NULL,
  `name_last` varchar(50) DEFAULT NULL,
  `name_note` varchar(255) DEFAULT NULL,
  `name_given` varchar(255) DEFAULT NULL,
  `name_nick` varchar(255) DEFAULT NULL,
  `weight` int(11) DEFAULT NULL,
  `height` float DEFAULT NULL,
  `bats` varchar(1) DEFAULT NULL,
  `throws` varchar(1) DEFAULT NULL,
  `first_game` date DEFAULT NULL,
  `final_game` date DEFAULT NULL,
  `college` varchar(50) DEFAULT NULL,
  `manager_id` char(10) CHARACTER SET ascii DEFAULT NULL,
  `hof_id` char(10) CHARACTER SET ascii DEFAULT NULL,
  PRIMARY KEY (`lahman_id`),
  UNIQUE KEY `bbref_id` (`bbref_id`),
  UNIQUE KEY `player_id` (`player_id`),
  UNIQUE KEY `retro_id` (`retro_id`,`bbref_id`),
  UNIQUE KEY `manager_id` (`manager_id`),
  UNIQUE KEY `hof_id` (`hof_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table pit_stints
# ------------------------------------------------------------

DROP TABLE IF EXISTS `pit_stints`;

CREATE TABLE `pit_stints` (
  `player_id` varchar(9) NOT NULL,
  `year_id` int(11) NOT NULL,
  `stint_id` int(11) NOT NULL,
  `team_id` varchar(3) DEFAULT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `W` int(11) DEFAULT NULL,
  `L` int(11) DEFAULT NULL,
  `G` int(11) DEFAULT NULL,
  `GS` int(11) DEFAULT NULL,
  `CG` int(11) DEFAULT NULL,
  `SHO` int(11) DEFAULT NULL,
  `SV` int(11) DEFAULT NULL,
  `IPouts` int(11) DEFAULT NULL,
  `H` int(11) DEFAULT NULL,
  `ER` int(11) DEFAULT NULL,
  `HR` int(11) DEFAULT NULL,
  `BB` int(11) DEFAULT NULL,
  `SO` int(11) DEFAULT NULL,
  `BAOpp` double DEFAULT NULL,
  `ERA` double DEFAULT NULL,
  `IBB` int(11) DEFAULT NULL,
  `WP` int(11) DEFAULT NULL,
  `HBP` int(11) DEFAULT NULL,
  `BK` int(11) DEFAULT NULL,
  `BFP` int(11) DEFAULT NULL,
  `GF` int(11) DEFAULT NULL,
  `R` int(11) DEFAULT NULL,
  `SH` int(11) DEFAULT NULL,
  `SF` int(11) DEFAULT NULL,
  `GIDP` int(11) DEFAULT NULL,
  PRIMARY KEY (`player_id`,`year_id`,`stint_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table pitchingpost
# ------------------------------------------------------------

DROP TABLE IF EXISTS `pitchingpost`;

CREATE TABLE `pitchingpost` (
  `player_id` varchar(9) NOT NULL,
  `year_id` int(11) NOT NULL,
  `round` varchar(10) NOT NULL,
  `team_id` varchar(3) DEFAULT NULL,
  `lg_id` varchar(2) DEFAULT NULL,
  `W` int(11) DEFAULT NULL,
  `L` int(11) DEFAULT NULL,
  `G` int(11) DEFAULT NULL,
  `GS` int(11) DEFAULT NULL,
  `CG` int(11) DEFAULT NULL,
  `SHO` int(11) DEFAULT NULL,
  `SV` int(11) DEFAULT NULL,
  `IPouts` int(11) DEFAULT NULL,
  `H` int(11) DEFAULT NULL,
  `ER` int(11) DEFAULT NULL,
  `HR` int(11) DEFAULT NULL,
  `BB` int(11) DEFAULT NULL,
  `SO` int(11) DEFAULT NULL,
  `BAOpp` double DEFAULT NULL,
  `ERA` double DEFAULT NULL,
  `IBB` int(11) DEFAULT NULL,
  `WP` int(11) DEFAULT NULL,
  `HBP` int(11) DEFAULT NULL,
  `BK` int(11) DEFAULT NULL,
  `BFP` int(11) DEFAULT NULL,
  `GF` int(11) DEFAULT NULL,
  `R` int(11) DEFAULT NULL,
  `SH` int(11) DEFAULT NULL,
  `SF` int(11) DEFAULT NULL,
  `GIDP` int(11) DEFAULT NULL,
  PRIMARY KEY (`player_id`,`year_id`,`round`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table salaries
# ------------------------------------------------------------

DROP TABLE IF EXISTS `salaries`;

CREATE TABLE `salaries` (
  `year_id` int(11) NOT NULL,
  `team_id` varchar(3) NOT NULL,
  `lg_id` varchar(2) NOT NULL,
  `player_id` varchar(9) NOT NULL,
  `salary` double DEFAULT NULL,
  PRIMARY KEY (`year_id`,`team_id`,`lg_id`,`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table schools
# ------------------------------------------------------------

DROP TABLE IF EXISTS `schools`;

CREATE TABLE `schools` (
  `school_id` varchar(15) NOT NULL,
  `school_name` varchar(255) DEFAULT NULL,
  `school_city` varchar(55) DEFAULT NULL,
  `school_state` varchar(55) DEFAULT NULL,
  `school_nick` varchar(55) DEFAULT NULL,
  PRIMARY KEY (`school_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table schoolsplayers
# ------------------------------------------------------------

DROP TABLE IF EXISTS `schoolsplayers`;

CREATE TABLE `schoolsplayers` (
  `player_id` varchar(9) NOT NULL,
  `school_id` varchar(15) NOT NULL,
  `first_year` int(11) DEFAULT NULL,
  `final_year` int(11) DEFAULT NULL,
  PRIMARY KEY (`player_id`,`school_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table seriespost
# ------------------------------------------------------------

DROP TABLE IF EXISTS `seriespost`;

CREATE TABLE `seriespost` (
  `year_id` int(11) NOT NULL,
  `round` varchar(5) NOT NULL,
  `team_idwinner` varchar(3) DEFAULT NULL,
  `lg_idwinner` varchar(2) DEFAULT NULL,
  `team_idloser` varchar(3) DEFAULT NULL,
  `lg_idloser` varchar(2) DEFAULT NULL,
  `wins` int(11) DEFAULT NULL,
  `losses` int(11) DEFAULT NULL,
  `ties` int(11) DEFAULT NULL,
  PRIMARY KEY (`year_id`,`round`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table teams
# ------------------------------------------------------------

DROP TABLE IF EXISTS `teams`;

CREATE TABLE `teams` (
  `year_id` int(11) NOT NULL,
  `lg_id` varchar(2) NOT NULL,
  `team_id` varchar(3) NOT NULL,
  `franch_id` varchar(3) DEFAULT NULL,
  `div_id` varchar(1) DEFAULT NULL,
  `W_rank` int(11) DEFAULT NULL,
  `G` int(11) DEFAULT NULL,
  `G_home` int(11) DEFAULT NULL,
  `W` int(11) DEFAULT NULL,
  `L` int(11) DEFAULT NULL,
  `W_div` varchar(1) DEFAULT NULL,
  `W_wc` varchar(1) DEFAULT NULL,
  `W_lg` varchar(1) DEFAULT NULL,
  `W_ws` varchar(1) DEFAULT NULL,
  `R` int(11) DEFAULT NULL,
  `AB` int(11) DEFAULT NULL,
  `H` int(11) DEFAULT NULL,
  `h2B` int(11) DEFAULT NULL,
  `h3B` int(11) DEFAULT NULL,
  `HR` int(11) DEFAULT NULL,
  `BB` int(11) DEFAULT NULL,
  `SO` int(11) DEFAULT NULL,
  `SB` int(11) DEFAULT NULL,
  `CS` int(11) DEFAULT NULL,
  `HBP` int(11) DEFAULT NULL,
  `SF` int(11) DEFAULT NULL,
  `RA` int(11) DEFAULT NULL,
  `ER` int(11) DEFAULT NULL,
  `ERA` double DEFAULT NULL,
  `CG` int(11) DEFAULT NULL,
  `SHO` int(11) DEFAULT NULL,
  `SV` int(11) DEFAULT NULL,
  `IPouts` int(11) DEFAULT NULL,
  `HA` int(11) DEFAULT NULL,
  `HRA` int(11) DEFAULT NULL,
  `BBA` int(11) DEFAULT NULL,
  `SOA` int(11) DEFAULT NULL,
  `E` int(11) DEFAULT NULL,
  `DP` int(11) DEFAULT NULL,
  `FP` double DEFAULT NULL,
  `team_name` varchar(50) DEFAULT NULL,
  `park_name` varchar(255) DEFAULT NULL,
  `attendance` int(11) DEFAULT NULL,
  `BPF` int(11) DEFAULT NULL,
  `PPF` int(11) DEFAULT NULL,
  `team_id_BR` varchar(3) DEFAULT NULL,
  `team_id_lahman45` varchar(3) DEFAULT NULL,
  `team_id_retro` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`year_id`,`lg_id`,`team_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table teamsfranchises
# ------------------------------------------------------------

DROP TABLE IF EXISTS `teamsfranchises`;

CREATE TABLE `teamsfranchises` (
  `franch_id` varchar(3) NOT NULL,
  `franch_name` varchar(50) DEFAULT NULL,
  `is_active` varchar(2) DEFAULT NULL,
  `is_NAassoc` varchar(3) DEFAULT NULL,
  PRIMARY KEY (`franch_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



# Dump of table teamshalf
# ------------------------------------------------------------

DROP TABLE IF EXISTS `teamshalf`;

CREATE TABLE `teamshalf` (
  `year_id` int(11) NOT NULL,
  `lg_id` varchar(2) NOT NULL,
  `team_id` varchar(3) NOT NULL,
  `half_id` varchar(1) NOT NULL,
  `div_id` varchar(1) DEFAULT NULL,
  `W_div` varchar(1) DEFAULT NULL,
  `W_rank` int(11) DEFAULT NULL,
  `G` int(11) DEFAULT NULL,
  `W` int(11) DEFAULT NULL,
  `L` int(11) DEFAULT NULL,
  PRIMARY KEY (`year_id`,`team_id`,`lg_id`,`half_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;




/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
