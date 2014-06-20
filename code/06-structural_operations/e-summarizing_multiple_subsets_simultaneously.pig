IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
mod_seasons = load_mod_seasons(); -- modern (post-1900) seasons of any number of PA only

-- ***************************************************************************
--
-- === The Summing Trick
--

-- ***************************************************************************
--
-- === Counting Conditional Subsets of a Group -- The Summing Trick
--

--
-- Whenever you are exploring a dataset, you should determine figures of merit
-- for each of the key statistics -- easy-to-remember values that separate
-- qualitatively distinct behaviors. You probably have a feel for the way that
-- 30 C / 85 deg F reasonably divides a "warm" day from a "hot" one; and if I
-- tell you that a sub-three-hour marathon distinguishes "really impress your
-- friends" from "really impress other runners", you are equipped to recognize
-- how ludicrously fast a 2:15 (the pace of a world-class runner) marathon is.
--
-- For our purposes, we can adopt 180 hits (H), 30 home runs (HR), 100 runs
-- batted in (RBI), a 0.400 on-base percentage (OBP) and a 0.500 slugging
-- percentage (SLG) each as the dividing line between a good and a great
-- performance.
--
-- One reasonable way to define a great career is to ask how many great seasons
-- a player had. We can answer that by counting how often a player's season
-- totals exceeded each figure of merit. The obvious tactic would seem to
-- involve filtering and counting each bag of seasonal stats for a player's
-- career; that is cumbersome to write, brings most of the data down to the
-- reducer, and exerts GC pressure materializing multiple bags.
-- 
-- Instead, we will apply what we like to call the "Summing trick", a frequently
-- useful way to act on subsets of a group without having to perform multiple
-- GROUP BY or FILTER operations. Call it to mind every time you find yourself
-- thinking "gosh, this sure seems like a lot of reduce steps on the same key".
-- 
-- The summing trick involves projecting a new field whose value is based on
-- whether it's in the desired set, forming the desired groups, and aggregating
-- on those new fields. Irrelevant records are assigned a value that will be
-- ignored by the aggregate function (typically zero or NULL), and so although
-- we operate on the group as a whole, only the relevant records contribute.
--
-- In this case, instead of sending all the hit, home run, etc figures directly
-- to the reducer to be bagged and filtered, we send a `1` for seasons above the
-- threshold and `0` otherwise. After the group, we find the _count_ of values
-- meeting our condition by simply _summing_ the values in the indicator
-- field. This approach allows Pig to use combiners (and so less data to the
-- reducer); and more importantly it doesn't cause a bag of values to be
-- collected, only a running sum (and so way less garbage-collector pressure).

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

--
-- This isn't a terribly sophisticated analysis: the numbers were chosen to be
-- easy-to-remember, and not based on the data. Better bases for rigorous
-- comparison (we'll describe both later on) would be the z-score (REF) or
-- quantile (REF) figures. And yet, for the exploratory phase we prefer the
-- ad-hoc figures. A 0.400 OBP is a number you can hold in your hand and your
-- head; you can go click around
-- http://espn.go.com/mlb/stats/batting/_/sort/onBasePct/order/true[ESPN] and
-- see that it selects about the top 10-15 players in most seasons; you can use
-- paper-and-pencil to feed it to the run expectancy table (REF) we'll develop
-- later and see what it says a 0.400-on-base hitter would produce. We've shown
-- you how useful it is to identify exemplar records; learn to identify these
-- touchstone values as well.
-- 
-- Another example will help you see what we mean -- next, we'll use one GROUP
-- operation to summarize multiple subsets of a table at the same time.

-- ***************************************************************************
--
-- === Summarizing Multiple Subsets of a Group Simultaneously
--

--
-- We can use the summing trick to apply even more sophisticated aggregations to
-- conditional subsets. How did each player's career evolve -- a brief brilliant
-- flame? a rise to greatness? sustained quality? Let's classify a player's
-- seasons by whether they are "young" (age 21 and below), "prime" (22-29
-- inclusive) or "older" (30 and older). We can then tell the story of their
-- career by finding their OPS (our overall performance metric) both overall and
-- for the subsets of seasons in each age range footnote:[these breakpoints are
-- based on where www.fangraphs.com/blogs/how-do-star-hitters-age research by
-- fangraphs.com showed a performance drop-off by 10% from peak.].
--
-- The complication here over the previous exercise is that we are forming
-- compound aggregates on the group. To apply the formula `career SLG = (career
-- TB) / (career AB)`, we need to separately determine the career values for
-- `TB` and `AB` and then form the combined `SLG` statistic.
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

-- If you do a sort on the different OPS fields, you'll spot Ted Williams
-- (player ID willite01) as one of the top three young players, top three prime
-- players, and top three old players. He's pretty awesome.

-- ***************************************************************************
--
-- === Testing for Absence of a Value Within a Group
--

-- We don't need a trick to answer "which players have ever played for the Red
-- Sox" -- just select seasons with team id `BOS` and eliminate duplicate player
-- ids:

-- Players who were on the Red Sox at some time
onetime_sox_ids = FOREACH (FILTER bat_seasons BY (team_id == 'BOS')) GENERATE player_id;
onetime_sox     = DISTINCT onetime_sox_ids;

-- The summing trick is useful for the complement, "which players have _never_
-- played for the Red Sox?" You might think to repeat the above but filter for
-- `team_id != 'BOS'` instead, but what that gives you is "which players have
-- ever played for a non-Red Sox team?". The right approach is to generate a
-- field with the value `1` for a Red Sox season and the irrelevant value `0`
-- otherwise. The never-Sox are those with zeroes for every year.

player_soxness   = FOREACH bat_seasons GENERATE
  player_id, (team_id == 'BOS' ? 1 : 0) AS is_soxy;

player_soxness_g = FILTER (GROUP player_soxness BY player_id)
  BY MAX(is_soxy) == 0;

never_sox = FOREACH player_soxness_g GENERATE group AS player_id;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

career_standards = ORDER (FOREACH career_standards GENERATE
    player_id, (hi_H + hi_HR + hi_RBI + hi_OBP + hi_SLG) AS awesomeness, n_seasons..
  ) BY awesomeness DESC;
STORE_TABLE(career_standards, 'career_standards');

career_epochs = ORDER career_epochs BY OPS_all DESC, player_id;
STORE_TABLE(career_epochs, 'career_epochs');

STORE_TABLE(never_sox, 'never_sox');
