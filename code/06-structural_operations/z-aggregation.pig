IMPORT 'common_macros.pig'; %DEFAULT out_dir '/data/out/baseball';
bat_yrs   = load_bat_seasons();

-- Turn the batting season statistics into batting career statistics
--
bat_careers = FOREACH (GROUP bat_yrs BY player_id) {
  team_ids = DISTINCT bat_yrs.team_id;
  totG   = SUM(bat_yrs.G);   totPA  = SUM(bat_yrs.PA);  totAB  = SUM(bat_yrs.AB);
  totH   = SUM(bat_yrs.H);   totBB  = SUM(bat_yrs.BB);  totHBP = SUM(bat_yrs.HBP); totR   = SUM(bat_yrs.R);    
  toth1B = SUM(bat_yrs.h1B); toth2B = SUM(bat_yrs.h2B); toth3B = SUM(bat_yrs.h3B); totHR  = SUM(bat_yrs.HR); 
  OBP    = (totH + totBB + totHBP) / totPA;
  SLG    = (toth1B + 2*toth2B + 3*toth3B + 4*totHR) / totAB;
  GENERATE group               AS player_id,
    COUNT_STAR(bat_yrs)       AS n_seasons,
    MIN(bat_yrs.year_id)	     AS beg_year,
    MAX(bat_yrs.year_id)      AS end_year,
    BagToString(team_ids, '^') AS team_ids,
    totG   AS G,   totPA  AS PA,  totAB  AS AB,
    totH   AS H,   totBB  AS BB,  totHBP AS HBP,
    toth1B AS h1B, toth2B AS h2B, toth3B AS h3B, totHR AS HR,
    OBP AS OBP, SLG AS SLG, (OBP + SLG) AS OPS
    ;
};

STORE_TABLE('bat_careers', bat_careers);

DESCRIBE bat_yrs;
DESCRIBE bat_careers;
