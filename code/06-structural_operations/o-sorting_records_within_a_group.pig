IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

-- Make sure to run 06-structural_operations/b-
bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Sorting Records within a Group


-- Use ORDER BY within a nested FOREACH to sort within a group. The first
-- request to sort a group does not require extra operations -- Pig simply
-- specifies those fields as secondary sort keys. This will list, for each
-- team's season, the players in decreasing order by 


