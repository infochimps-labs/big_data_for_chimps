SELECT
    player_id, year_id, team_id, 
    G, PA, AB, H, BB,
    @HBP := IFNULL(HBP, 0)              AS HBP,
    @h1B := (H - h2B - h3B - HR)          AS h1B,
    h2B, h3B, HR,
    @TB  := (@h1B + 2*h2B + 3*h3B + 4*HR) AS TB,
    @OBP := (H + BB + @HBP)/PA          AS OBP,
    @SLG := (@TB / AB)                  AS SLG,
    @ISO := ((@TB - H) / AB)            AS ISO,
    @OPS := (@SLG + @OBP)               AS OPS
  FROM bat_seasons
  WHERE PA > 0 AND AB > 0
  INTO OUTFILE '/tmp/bat_seasons.tsv'
  ;

SELECT
    player_id, year_id, team_id, stint_id,
    G, 
    @PA  := AB + BB + IFNULL(HBP,0) + IFNULL(SH,0) + IFNULL(SF,0),
    AB, H, BB,
    @HBP := IFNULL(HBP, 0)              AS HBP,
    @h1B := (H - h2B - h3B - HR)          AS h1B,
    h2B, h3B, HR,
    @TB  := (@h1B + 2*h2B + 3*h3B + 4*HR) AS TB,
    @OBP := (H + BB + @HBP)/@PA          AS OBP,
    @SLG := (@TB / AB)                  AS SLG,
    @ISO := ((@TB - H) / AB)            AS ISO,
    @OPS := (@SLG + @OBP)               AS OPS
  FROM bat_stints
  WHERE AB > 0
  INTO OUTFILE '/tmp/bat_stints.tsv'
  ;

SELECT * FROM allstars
  INTO OUTFILE '/tmp/allstars.tsv'
  ;

SELECT * FROM retrosheet.games
  WHERE year_id = 2004
  INTO OUTFILE '/tmp/games_2004.tsv'
  ;


  
