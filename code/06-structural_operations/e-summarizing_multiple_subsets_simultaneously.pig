IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();
mod_seasons = load_mod_seasons(); -- modern (post-1900) seasons of any number of PA only

-- ***************************************************************************
--
-- === The Summing Trick
--

-- Create indicator fields on each figure of merit for the season
standards = FOREACH mod_seasons {
  OBP    = 1.0*(H + BB + HBP) / PA;
  SLG    = 1.0*(h1B + 2*h2B + 3*h3B + 4*HR) / AB;
  GENERATE
    player_id,
    (H   >=   180 ? 1 : 0) AS hi_H,
    (HR  >=    30 ? 1 : 0) AS hi_HR,
    (RBI >=   100 ? 1 : 0) AS hi_RBI,
    (OBP >= 0.400 ? 1 : 0) AS hi_OBP,
    (SLG >= 0.500 ? 1 : 0) AS hi_SLG
    ;
};

-- Count the seasons that pass the threshold by summing the indicator value
career_standards = FOREACH (GROUP standards BY player_id) GENERATE
    group AS player_id,
    COUNT_STAR(standards) AS n_seasons,
    SUM(standards.hi_H)   AS hi_H,
    SUM(standards.hi_HR)  AS hi_HR,
    SUM(standards.hi_RBI) AS hi_RBI,
    SUM(standards.hi_OBP) AS hi_OBP,
    SUM(standards.hi_SLG) AS hi_SLG
    ;

-- ***************************************************************************
--
-- === Summarizing Multiple Subsets of a Group Simultaneously
--

--
-- Project the numerator and denominator of each offensive stat into the field
-- for that age bucket. Only one of the subset fields will be filled in; as an
-- example, an age-25 season will have values for PA_all and PA_prime and zeros
-- for PA_young and PA_older.
--
age_seasons = FOREACH mod_seasons {
  young = (age <= 21               ? true : false);
  prime = (age >= 22 AND age <= 29 ? true : false);
  older = (age >= 30               ? true : false);
  OB = H + BB + HBP;
  TB = h1B + 2*h2B + 3*h3B + 4*HR;
  GENERATE
    player_id, year_id,
    PA AS PA_all, AB AS AB_all, OB AS OB_all, TB AS TB_all,
    (young ? 1 : 0) AS is_young,
      (young ? PA : 0) AS PA_young, (young ? AB : 0) AS AB_young,
      (young ? OB : 0) AS OB_young, (young ? TB : 0) AS TB_young,
    (prime ? 1 : 0) AS is_prime,
      (prime ? PA : 0) AS PA_prime, (prime ? AB : 0) AS AB_prime,
      (prime ? OB : 0) AS OB_prime, (prime ? TB : 0) AS TB_prime,
    (older ? 1 : 0) AS is_older,
      (older ? PA : 0) AS PA_older, (older ? AB : 0) AS AB_older,
      (older ? OB : 0) AS OB_older, (older ? TB : 0) AS TB_older
    ;
};

--
-- After the group, we can sum across all the records to find the
-- plate-appearances-in-prime-seasons even though only some of the records
-- belong to the prime-seasons subset. The irrelevant seasons show a zero value
-- in the projected field and so don't contribute to the total.
--
career_epochs = FOREACH (GROUP age_seasons BY player_id) {
  PA_all    = SUM(age_seasons.PA_all  );
  PA_young  = SUM(age_seasons.PA_young);
  PA_prime  = SUM(age_seasons.PA_prime);
  PA_older  = SUM(age_seasons.PA_older);
  -- OBP = (H + BB + HBP) / PA
  OBP_all   = 1.0f*SUM(age_seasons.OB_all)   / PA_all  ;
  OBP_young = 1.0f*SUM(age_seasons.OB_young) / PA_young;
  OBP_prime = 1.0f*SUM(age_seasons.OB_prime) / PA_prime;
  OBP_older = 1.0f*SUM(age_seasons.OB_older) / PA_older;
  -- SLG = TB / AB
  SLG_all   = 1.0f*SUM(age_seasons.TB_all)   / SUM(age_seasons.AB_all);
  SLG_prime = 1.0f*SUM(age_seasons.TB_prime) / SUM(age_seasons.AB_prime);
  SLG_older = 1.0f*SUM(age_seasons.TB_older) / SUM(age_seasons.AB_older);
  SLG_young = 1.0f*SUM(age_seasons.TB_young) / SUM(age_seasons.AB_young);
  --
  GENERATE
    group AS player_id,
    MIN(age_seasons.year_id)  AS beg_year,
    MAX(age_seasons.year_id)  AS end_year,
    --
    OBP_all   + SLG_all       AS OPS_all:float,
    (PA_young >= 700 ? OBP_young + SLG_young : Null) AS OPS_young:float,
    (PA_prime >= 700 ? OBP_prime + SLG_prime : Null) AS OPS_prime:float,
    (PA_older >= 700 ? OBP_older + SLG_older : Null) AS OPS_older:float,
    --
    COUNT_STAR(age_seasons)   AS n_seasons,
    SUM(age_seasons.is_young) AS n_young,
    SUM(age_seasons.is_prime) AS n_prime,
    SUM(age_seasons.is_older) AS n_older
    ;
};

-- ***************************************************************************
--
-- === Testing for Absence of a Value Within a Group
--

-- Players who were on the Red Sox at some time
onetime_sox_ids = FOREACH (FILTER bat_seasons BY (team_id == 'BOS')) GENERATE player_id;
onetime_sox     = DISTINCT onetime_sox_ids;

player_soxness   = FOREACH bat_seasons GENERATE
  player_id, (team_id == 'BOS' ? 1 : 0) AS is_soxy;
player_soxness_g = FILTER
  (GROUP player_soxness BY player_id)
  BY MAX(is_soxy) == 0;

never_sox = FOREACH player_soxness_g GENERATE group AS player_id;

--
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
career_standards = ORDER (FOREACH career_standards GENERATE
    player_id, (hi_H + hi_HR + hi_RBI + hi_OBP + hi_SLG) AS awesomeness, n_seasons..
  ) BY awesomeness DESC;
STORE_TABLE(career_standards, 'career_standards');

career_epochs = ORDER career_epochs BY OPS_all DESC, player_id;
STORE_TABLE(career_epochs, 'career_epochs');

STORE_TABLE(never_sox, 'never_sox');
