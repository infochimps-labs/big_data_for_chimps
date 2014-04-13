SELECT
    playerID, yearID, teamID, 
    G, PA, AB, H, BB,
    @HBP := IFNULL(HBP, 0)              AS HBP,
    @h1B := (H - 2B - 3B - HR)          AS h1B,
    2B AS h2B, 3B AS h3B, HR,
    @TB  := (@h1B + 2*2B + 3*3B + 4*HR) AS TB,
    @OBP := (H + BB + @HBP)/PA          AS OBP,
    @SLG := (@TB / AB)                  AS SLG,
    @ISO := ((@TB - H) / AB)            AS ISO,
    @OPS := (@SLG + @OBP)               AS OPS
  FROM bat_season
  WHERE PA > 0 AND AB > 0
  INTO OUTFILE '/tmp/simple_bats.tsv'
  ;
