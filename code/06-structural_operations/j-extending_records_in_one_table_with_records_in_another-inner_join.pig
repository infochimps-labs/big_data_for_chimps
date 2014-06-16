IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

-- You will need to first generate the career stats by running
-- 06-structural_operations/b-summarizing_aggregate_statistics_of_a_group.pig:DESCRIBE
bat_careers = LOAD_RESULT('bat_careers');
peeps       = load_people();

-- ***************************************************************************
--
-- === Joining Records in a Table with Corresponding Records in Another Table (Inner Join)
--
-- // alternate title??: Matching Records Between Tables (Inner Join)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Joining Records in a Table with Directly Matching Records from Another Table (Direct Inner Join)
--

-- There is a stereotypical picture in baseball of a "slugger": a big fat man
-- who comes to plate challenging your notion of what an athlete looks like, and
-- challenging the pitcher to prevent him from knocking the ball for multiple
-- bases (or at least far enough away to lumber up to first base). To examine
-- the correspondence from body type to ability to hit for power (i.e. high
-- SLG), we will need to join the `people` table (listing height and weight)
-- with their hitting stats.
--
-- The BMI (Body Mass Index) is a reasonable measure of body type and easy to
-- calculate: just divide the weight by the height squared (and, since we're
-- stuck with english units, multiply by 703 to convert to metric). Though it
-- doesn't distinguish between 180 pounds of muscle and 180 pounds of flab, it
-- acceptably lumps together beanpole Randy Johnson (6'10"/2.1m;
-- 225lb/102kg; BMI 23) with pocket rocket Tim Raines (5'8"/1.7m;
-- 160lb/73kb; BMI 24) and puts
-- Babe Ruth (who in his later days was
-- 6'2"/1.88m 260lb/118kb for a BMI of 33) up with Cecil Fielder.
--
--
-- Bill James' Historical Baseball Abstract, the encyclopedia of baseball:
-- Summary of Cecil Fielder's career, in whole: "A big fat guy who hit home runs for a few years."
-- Also: "Fielder acknowledges a weight of 261, leaving unanswered the question of what he might weigh if he put his other foot on the scale."
--
-- 
-- 
fatness = FOREACH peeps GENERATE
  player_id, name_first, name_last,
  height_in, weight_lb, 
  ROUND_TO(703.0*weight_lb/(height_in*height_in),1) AS BMI;


--
-- Let's also use our criteria for "significant careers" to 
stats = FILTER bat_careers BY ((PA > 1000) AND (OPS > 0.));


stats_and_fatness = FOREACH (JOIN fatness BY player_id, stats BY player_id)
  GENERATE fatness::player_id..BMI, stats::n_seasons..OPS;

STORE_TABLE(stats_and_fatness, 'stats_and_fatness');

-- ===== Exercise
--
-- Exercise: Explore the correspondence of weight, height and BMI to SLG using a
-- medium-data tool such as R, Pandas or Excel. Spoiler alert: the stereotypes
-- of the big fat slugger is quire true.



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Disambiguating Field Names With `::`
--
