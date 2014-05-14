SELECT NOW() AS starting_datetime, "Creating simplified events: will take several minutes";

DROP TABLE IF EXISTS `events_lite`;
CREATE TABLE         `events_lite` (
    `game_id`       CHAR(12)    NOT NULL, -- Game ID, composed of home team ID, date, and game sequence id
    `event_seq`     SMALLINT(3),          -- Event sequence ID: All events are numbered consecutively throughout each game for easy reference. Note that there may be many events in a plate appearance, due to stolen bases and so forth.
    `year_id`       SMALLINT(4) NOT NULL, -- Year the game took place
    `game_date`     DATE        NOT NULL, -- Game date, YYYY-mm-dd
    `game_seq`      TINYINT(1),           -- Game sequence ID: 0 if only one game; otherwise 1 for first game in day, 2 for the second)
    `away_team_id`  CHAR(3)     NOT NULL, -- Team ID for the away (visiting) team; they bat first in each inning.
    `home_team_id`  CHAR(3)     NOT NULL, -- Team ID for the home team
    --
    `inn`           TINYINT(2)  NOT NULL, -- Inning in which this play took place.
    `inn_home`      BOOLEAN     NOT NULL, -- "0" if the visiting team is at bat, "1" if the home team is at bat
    `beg_outs_ct`   TINYINT(1),           -- Number of outs before this play.
    `away_score`    TINYINT(3),           -- Away score, the number of runs for the visiting team before this play.
    `home_score`    TINYINT(3),           -- Home score, the number of runs for the home team before this play.
    --
    `event_desc`    VARCHAR(100),         -- The complete description of the play using the format described for the event files.
    `event_cd`      TINYINT(2),           -- Simplified event type -- see below.
    `hit_cd`        TINYINT(1),           -- Value of hit: 0 = no hit; 1 = single; 2 = double; 3 = triple; 4 = home run.
    --
    `ev_outs_ct`    TINYINT(1),           -- Number of outs recorded on this play.
    `ev_runs_ct`    TINYINT(2),           -- Number of runs recorded on this play.
    `bat_dest`      TINYINT(1),           -- The base which the batter reached at the conclusion of the play.  The value is 0 for an out, 4 if scores an earned run, 5 if scores and unearned, 6 if scores and team unearned.
    `run1_dest`     TINYINT(1),           -- Base reached by the runner on first at the conclusion of the play, using the same coding as `bat_dest`.  If there was no advance, then the base shown will be the one where the runner started.  Note that these runner fields are not updated on plays which end an inning, even if the inning-ending play would have resulted in an advance of one or more runners had it occurred earlier in the inning.
    `run2_dest`     TINYINT(1),           -- Base reached by the runner on second at the conclusion of the play -- see `run1_dest`.
    `run3_dest`     TINYINT(1),           -- Base reached by the runner on third at the conclusion of the play -- see `run1_dest`.
    --
    `is_end_bat`    BOOLEAN,              -- 1 if the event terminated the batter's appearance; 0 means the same batter stayed at the plate, such as after a stolen base).
    `is_end_inn`    BOOLEAN,              -- 1 if the event terminated the inning.
    `is_end_game`   BOOLEAN,              -- 1 if this is the last record of a game.
    --
    `bat_team_id`   CHAR(3),              -- Team ID of the batting team
    `fld_team_id`   CHAR(3),              -- Team ID of the fielding team
    `pit_id`        CHAR(8),              -- Player ID code for the pitcher responsible for the play (NOTE: this is the `res_pit_id` field in the original).
    `bat_id`        CHAR(8),              -- Player ID code for the batter responsible for the play (NOTE: this is the `res_bat_id` field in the original).
    `run1_id`       CHAR(8),              -- Player ID code for the runner on first base, if any.
    `run2_id`       CHAR(8),              -- Player ID code for the runner on second base, if any.
    `run3_id`       CHAR(8),              -- Player ID code for the runner on third base, if any.
    --
    PRIMARY KEY `event`     (`game_id`,      `event_seq`, `year_id`),
    KEY         `inning`    (`year_id`, `game_id`, `inn`, `inn_home`),
    KEY         `batter`    (`bat_id`,       `year_id`),
    KEY         `pitcher`   (`pit_id`,       `year_id`),
    KEY         `away_team` (`away_team_id`, `year_id`),
    KEY         `home_team` (`home_team_id`, `year_id`),
    KEY         `bat_team`  (`bat_team_id`,  `year_id`),
    KEY         `fld_team`  (`fld_team_id`,  `year_id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=ascii PARTITION BY KEY (year_id)
    ;

INSERT INTO `events_lite` (
  `game_id`, `event_seq`, `year_id`, `game_date`, `game_seq`,
  `away_team_id`, `home_team_id`,
  `inn`, `inn_home`, `beg_outs_ct`, `away_score`, `home_score`,
  `event_desc`, `event_cd`, `hit_cd`,
  `ev_outs_ct`, `ev_runs_ct`,
  `bat_dest`, `run1_dest`, `run2_dest`, `run3_dest`,
  `is_end_bat`, `is_end_inn`, `is_end_game`,
  `bat_team_id`, `fld_team_id`, `pit_id`, `bat_id`, `run1_id`, `run2_id`, `run3_id`
  ) SELECT
    game_id, event_id AS event_seq, 0+SUBSTRING(game_id, 4,4) AS year_id,
    DATE(SUBSTRING(game_id, 4,8)) AS game_date, 0+RIGHT(game_id, 1) AS game_seq,
    away_team_id, LEFT(game_id,3) AS home_team_id,
    -- inning and outs
    inn_ct        AS inn,        bat_home_id   AS inn_home,   outs_ct AS beg_outs_ct,
    away_score_ct AS away_score, home_score_ct AS home_score,
    -- event
    event_tx      AS event_desc, event_cd,   h_cd,
    event_outs_ct AS ev_outs_ct, event_runs_ct AS ev_runs_ct,
    bat_dest_id   AS bat_dest,   run1_dest_id  AS run1_dest, run2_dest_id AS run2_dest, run3_dest_id AS run3_dest,
    IF(bat_event_fl = 'T', 1, 0) AS is_end_bat, IF(inn_end_fl = 'T', 1, 0) AS is_end_inn, IF(game_end_fl = 'T', 1, 0) AS is_end_game,
    -- participants
    IF(bat_home_id = 0, away_team_id, home_team_id) AS bat_team_id,
    IF(bat_home_id = 0, home_team_id, away_team_id) AS fld_team_id,
    pit_id, bat_id, base1_run_id AS run1_id, base2_run_id AS run2_id, base3_run_id AS run3_id
  FROM `retrosheet_bhm`.`events`
  WHERE game_id != 'GAME_ID' -- whoops, the kind folks who made the originals left the header line in
  ORDER BY year_id DESC, game_id ASC, inn ASC, inn_home ASC, outs_ct ASC
  ;

SELECT NOW() AS starting_datetime, 'Done loading events_lite';
