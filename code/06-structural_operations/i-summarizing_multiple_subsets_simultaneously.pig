IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

mod_seasons = load_mod_seasons(); -- modern (post-1900) seasons of any number of PA only

-- ***************************************************************************
--
-- === Summarizing Multiple Subsets Simultaneously
--

-- Some players are brilliant young and flame out; some
--
-- We can use the summing trick to find aggregates on conditional subsets. For
-- this example, we will classify players as being "young" (age 21 and below),
-- "prime" (22-29 inclusive) or "old" (30 and older), and then find the OPS (our
-- overall performance metric) for their full career and for the subsets of
-- seasons where they were young, in their prime, or old footnote:[these
-- breakpoints are based on where
-- www.fangraphs.com/blogs/how-do-star-hitters-age research by fangraphs.com
-- showed a performance drop-off by 10% from peak.]
--
-- We're

-- Project the numerator and denominator of our offensive stats into the field
-- for that age bucket... for an age-25 season, there will be values for PA_all
-- and PA_prime; PA_young and PA_older will have the value 0.
age_seasons = FOREACH mod_seasons {
  young = (age <= 21               ? true : false);
  prime = (age >= 22 AND age <= 29 ? true : false);
  older = (age >= 30               ? true : false);
  OB = H + BB + HBP;
  TB = h1B + 2*h2B + 3*h3B + 4*HR;
  GENERATE
    player_id, year_id,
    PA AS PA_all, AB AS AB_all, OB AS OB_all, TB AS TB_all,
    (young ? PA : 0) AS PA_young, (young ? AB : 0) AS AB_young,
    (young ? OB : 0) AS OB_young, (young ? TB : 0) AS TB_young, (young ? 1 : 0) AS is_young,
    (prime ? PA : 0) AS PA_prime, (prime ? AB : 0) AS AB_prime,
    (prime ? OB : 0) AS OB_prime, (prime ? TB : 0) AS TB_prime, (prime ? 1 : 0) AS is_prime,
    (older ? PA : 0) AS PA_older, (older ? AB : 0) AS AB_older,
    (older ? OB : 0) AS OB_older, (older ? TB : 0) AS TB_older, (older ? 1 : 0) AS is_older
    ;
};

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
    PA_all                    AS PA_all,
    PA_young                  AS PA_young,
    PA_prime                  AS PA_prime,
    PA_older                  AS PA_older,
    --
    COUNT_STAR(age_seasons)   AS n_seasons,
    SUM(age_seasons.is_young) AS n_young,
    SUM(age_seasons.is_prime) AS n_prime,
    SUM(age_seasons.is_older) AS n_older
    ;
};

career_epochs = ORDER career_epochs BY OPS_all DESC, player_id;
STORE_TABLE(career_epochs, 'career_epochs');

-- You'll spot Ted Williams (willite01) as one of the top three young players,
-- top three prime players, and top three old players. He's pretty awesome.
