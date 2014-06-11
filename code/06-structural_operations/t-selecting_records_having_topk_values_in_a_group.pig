IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Selecting Records Having the Top K Values in a Group (discarding ties)
--

-- Let's find the top ten home-run hitters for each season
--

%DEFAULT k_leaders 10
;

HR_seasons = FOREACH bat_seasons GENERATE
  player_id, name_first, name_last, year_id, HR;

HR_leaders = FOREACH (GROUP HR_seasons BY year_id) GENERATE
  group AS year_id,
  TOP($k_leaders, 3, HR_seasons.(player_id, name_first, name_last, HR)) AS top_k;

-- HR_leaders = FOREACH HR_leaders {
--   top_k_o = ORDER top_k BY HR DESC;
--   GENERATE
--
--   top_k  =
--   GENERATE top_k_o;
--   };
--
--   top_k_o = ORDER top_k BY HR DESC;

--
-- STORE_TABLE(HR_leaders, 'HR_leaders');



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Selecting Attribute wdw
-- -- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/ExtremalTupleByNthField.html
-- DEFINE BiggestInBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');
--
-- pl_best = FOREACH (GROUP bat_seasons BY player_id) GENERATE
--   group AS player_id,
--   BiggestInBag(bat_seasons.(H,   year_id, team_id)),
--   BiggestInBag(bat_seasons.(HR,  year_id, team_id)),
--   BiggestInBag(bat_seasons.(OBP, year_id, team_id)),
--   BiggestInBag(bat_seasons.(SLG, year_id, team_id)),
--   BiggestInBag(bat_seasons.(OPS, year_id, team_id))
--   ;
--
-- DESCRIBE pl_best;
--
-- rmf                 $out_dir/pl_best;
-- STORE pl_best INTO '$out_dir/pl_best';
