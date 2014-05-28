IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
people            = load_people();
teams             = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Selecting Records with Unique (or with Duplicate) Values for a Key
--

SELECT nameFirst, nameLast, COUNT(*) AS n_usages
  FROM bat_career
  WHERE    nameFirst IS NOT NULL
  GROUP BY nameFirst
  HAVING   n_usages = 1
  ORDER BY nameFirst
  ;


  -- group by, then emit bags with more than one size; call back to the won-loss example

  
  -- Teams who played in more than one stadium in a year
SELECT COUNT(*) AS n_parks, pty.*
  FROM park_teams pty
  GROUP BY team_id, year_id
  HAVING n_parks > 1


-- ***************************************************************************
--
-- ==== Eliminating rows that have a duplicated value
-- 
-- (ie the whole row isn't distinct,
-- just the field you're distinct-ing on.
-- Note: this chooses an arbitrary value from each group


SELECT COUNT(*) AS n_asg, ast.*
  FROM allstarfull ast
  GROUP BY year_id, player_id
  HAVING n_asg > 1
  ;

