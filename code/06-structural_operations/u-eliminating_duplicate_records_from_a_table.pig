IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

-- ***************************************************************************
--
-- === Eliminating Duplicate Records from a Table
--

-- Every team a player has played for
SELECT DISTINCT player_id, team_id from batting;



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- === Eliminating Duplicate Records from a Group
--

SELECT team_id, GROUP_CONCAT(DISTINCT park_id ORDER BY park_id) AS park_ids
  FROM park_teams
  GROUP BY team_id
  ORDER BY team_id, park_id DESC
  ;



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- === Counting and Identifying Duplicates
--

