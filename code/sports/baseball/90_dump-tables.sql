SELECT NOW() AS starting_datetime, 'Dumping player team and park statistics into /data/rawd/sports/baseball/retrosheet/\*.tsv: should take only a second or so';

SELECT * FROM `lahman`.`allstars`        ORDER BY year_id, player_id    INTO OUTFILE '/data/rawd/sports/baseball/allstars.tsv';
SELECT * FROM `lahman`.`bat_seasons`     ORDER BY player_id, year_id    INTO OUTFILE '/data/rawd/sports/baseball/bat_seasons.tsv';
SELECT * FROM `lahman`.`teams`           ORDER BY team_id, year_id      INTO OUTFILE '/data/rawd/sports/baseball/teams.tsv';
SELECT * FROM `lahman`.`park_team_years` ORDER BY year_id, park_id      INTO OUTFILE '/data/rawd/sports/baseball/park_team_years.tsv';
SELECT * FROM `lahman`.`franchises`      ORDER BY franch_id             INTO OUTFILE '/data/rawd/sports/baseball/franchises.tsv';

SELECT
    player_id, year_id, team_id, 
    G, PA, AB, H, BB,
    @HBP := IFNULL(HBP, 0)                AS HBP,
    @h1B := (H - h2B - h3B - HR)          AS h1B,
    h2B, h3B, HR,
    @TB  := (@h1B + 2*h2B + 3*h3B + 4*HR) AS TB,
    @OBP := (H + BB + @HBP)/PA            AS OBP,
    @SLG := (@TB / AB)                    AS SLG,
    @ISO := ((@TB - H) / AB)              AS ISO,
    @OPS := (@SLG + @OBP)                 AS OPS,
    height, weight
  FROM `lahman`.`bat_seasons`
  WHERE PA > 0 AND AB > 0
  ORDER BY player_id, year_id    
  INTO OUTFILE '/data/rawd/sports/baseball/bats_lite.tsv'
  ;

SELECT NOW() AS starting_datetime, 'Dumping simplified games into /data/rawd/sports/baseball/retrosheet/games_lite.tsv: should take a second or so';

SELECT game_id, year_id, away_team_id, home_team_id, home_runs_ct, away_runs_ct
  FROM retrosheet.games
  ORDER BY game_id
  INTO OUTFILE '/data/rawd/sports/baseball/games_lite.tsv'
  ;

SELECT NOW() AS starting_datetime, 'Dumping simplified events into /data/rawd/sports/baseball/retrosheet/events_lite.tsv: should take about a minute';
SELECT * FROM `retrosheet`.`events_lite` ORDER BY year_id DESC, game_id ASC, event_seq ASC INTO OUTFILE '/data/rawd/sports/baseball/events_lite.tsv';


SELECT NOW() AS starting_datetime, 'Done dumping tables';

