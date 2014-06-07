IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- Here follows an investigation of players' career statistics
--
-- Defining the characteristic what we mean by an exceptional career is a matter
-- of taste, not mathematics; and selecting how we estimate those
-- characteristics is a matter of taste balanced by mathematically-informed
-- practicality.
--
-- * Total production: a long career and high absolute totals for hits, home runs and so forth
-- * Sustained excellence: high normalized rates of production (on-base percentage and so forth)
-- * Peak excellence: multiple seasons of exceptional performance

-- ***************************************************************************
--
-- === Using Group/Decorate/Flatten to Bring Group Context to Individuals
--

-- Earlier, when we created relative histograms, we demonstrated putting records
-- in context with global values.
--
-- To put them in context with whole-group examples, use a pattern we call
-- 'group/decorate/flatten'. Use this when you want a table with the same shape
-- and cardinality as the original (that is, each record in the result comes
-- from a single record in the original), but which integrates aggregate
-- statistics from subgroups of the table.
--
-- Let's annotate each player's season by whether they were the league leader in
-- Home Runs (HR).

-- The group we need is all the player-seasons for a year, so that we can find
-- out what the maximum count of HR was for that year.
bats_by_year_g = GROUP bat_seasons BY year_id;

-- Decorate each individual record with the group summary, and flatten:
bats_with_max_hr = FOREACH bats_by_year_g GENERATE
  MAX(bat_seasons.HR) as max_HR,
  FLATTEN(bat_seasons);

-- Now apply the group context to the records:
bats_with_leaders = FOREACH bats_with_max_hr GENERATE
  player_id.., (HR == max_HR ? 1 : 0);

-- An experienced SQL user might think to do this with a join. That might or
-- might not make sense; we'll explore this alternative later in the chapter
-- under "Selecting Records Associated with Maximum Values".

STORE_TABLE(bats_with_leaders, 'bats_with_leaders');




-- normed_dec = FOREACH (GROUP bat_years BY (year_id, lg_id)) {
--   batq     = FILTER bat_years BY (PA >= 450);
--   avg_BB   = AVG(batq.BB);  sdv_BB  = SQRT(VAR(batq.BB));
--   avg_H    = AVG(batq.H);   sdv_H   = SQRT(VAR(batq.H));
--   avg_HR   = AVG(batq.HR);  sdv_HR  = SQRT(VAR(batq.HR));
--   avg_R    = AVG(batq.R);   sdv_R   = SQRT(VAR(batq.R));
--   avg_RBI  = AVG(batq.RBI); sdv_RBI = SQRT(VAR(batq.RBI));
--   avg_OBP  = AVG(batq.OBP); sdv_OBP = SQRT(VAR(batq.OBP));
--   avg_SLG  = AVG(batq.SLG); sdv_SLG = SQRT(VAR(batq.SLG));
--   --
--   GENERATE
--     -- all the original values, flattened back into player-seasons
--     FLATTEN(bat_years),
--     -- all the materials for normalizing the stats
--     avg_H   AS avg_H,   sdv_H   AS sdv_H,
--     avg_HR  AS avg_HR,  sdv_HR  AS sdv_HR,
--     avg_R   AS avg_R,   sdv_R   AS sdv_R,
--     avg_RBI AS avg_RBI, sdv_RBI AS sdv_RBI,
--     avg_OBP AS avg_OBP, sdv_OBP AS sdv_OBP,
--     avg_SLG AS avg_SLG, sdv_SLG AS sdv_SLG
--     ;
-- };
-- 
-- normed = FOREACH normed_dec GENERATE
--   player_id, year_id, team_id, lg_id,
--   G,    PA,   AB,   HBP,  SH,
--   BB,   H,    h1B,  h2B,  h3B,
--   HR,   R,    RBI,  OBP,  SLG,
--   (H   - avg_H  ) /sdv_H        AS zH,
--   (HR  - avg_HR ) /sdv_HR       AS zHR,
--   (R   - avg_R  ) /sdv_R        AS zR,
--   (RBI - avg_RBI) /sdv_RBI      AS zRBI,
--   (OBP - avg_OBP) /sdv_OBP      AS zOBP,
--   (SLG - avg_SLG) /sdv_SLG      AS zSLG,
--   ( ((OBP - avg_OBP)/sdv_OBP) +
--     ((SLG - avg_SLG)/sdv_SLG) ) AS zOPS
--   ;
-- 
-- normed_seasons = ORDER normed BY zOPS ASC;
-- STORE_TABLE(normed_seasons, 'normed_seasons');
