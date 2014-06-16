IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Calculating a Relative Distribution Histogram
--


-- ==== Calculating Percent Relative to Total
-- 
-- The histograms we've calculated have results in terms of counts. The results do a better general job of enforcing comparisons if express them as relative frequencies: as fractions of the total count. You know how to find the total:
-- 
-- ------
-- HR_stats = FOREACH (GROUP bats BY ALL) GENERATE COUNT_STAR(bats) AS n_players;
-- ------
-- 
-- The problem is that HR_stats is a single-row table, and so not something we can use directly in a FOREACH expression. Pig gives you a piece of syntactic sugar for this specific case of a one-row table footnote:[called 'scalar projection' in Pig terminology]: project the value as tablename.field as if it were an inner bag, but slap the field's type (in parentheses) in front of it like a typecast expression:
-- 
-- ------
-- HR_stats = FOREACH (GROUP bats BY ALL) GENERATE COUNT_STAR(bats) AS n_total;
-- HR_hist  = FOREACH (GROUP bats BY HR) {
--   ct = COUNT_STAR(bats);
--   GENERATE HR as val, 
--     ct/( (long)HR_stats.n_total ) AS freq,
--     ct;
-- };
-- ------
-- 
-- Typecasting the projected field as if you were simply converting the schema of a field from one scalar type to another acts as a promise to Pig  that what looks like column of possibly many values will turn out to have only row. In return, Pig will understand that you want a sort of über-typecast of the projected column into what is effectively its literal value.
-- 
-- ==== Re-injecting global totals
-- 
-- Sometimes things are more complicated, and what you'd like to do is perform light synthesis of the results of some initial Hadoop jobs, then bring them back into your script as if they were some sort of "global variable". But a pig script just orchestrates the top-level motion of data: there's no good intrinsic ways to bring the result of a step into the declaration of following steps. You can use a backhoe to tear open the trunk of your car, but it's not really set up to push the trunk latch button. The proper recourse is to split the script into two parts, and run it within a workflow tool like Rake, Drake or Oozie. The workflow layer can fish those values out of the HDFS and inject them as runtime parameters into the next stage of the script.
-- 
-- In the case of global counts, it would be so much faster if we could sum the group counts to get the global totals; but that would mean a job to get the counts, a job to get the totals, and a job to get the relative frequencies. Ugh.
-- 
-- If the global statistic is relatively static, there are occasions where we prefer to cheat. Write the portion of the script that finds the global count and stores it, then comment that part out and inject the values statically -- the sample code shows you how to do it with with a templating runner, as runtime parameters, by copy/pasting, or using the `cat` Grunt shell statement. Then, to ensure your time-traveling shenanigans remain valid, add an `ASSERT` statement comparing the memoized values to the actual totals. Pig will not only run the little checkup stage in parallel if possible, it will realize that the data size is small enough to run as a local mode job -- cutting the turnaround time of a tiny job like that in half or better.
-- 
-- ------
-- -- cheat mode: 
-- -- HR_stats = FOREACH (GROUP bats BY ALL) GENERATE COUNT_STAR(bats) AS n_total;
-- SET HR_stats_n_total = `cat $out_dir/HR_stats_n_total`;
-- 
-- HR_hist  = FOREACH (GROUP bats BY HR) {
--   ct = COUNT_STAR(bats);
--   GENERATE HR as val, ct AS ct, 
--     -- ct/( (long)HR_stats.n_total ) AS freq,
--     ct/( (long)HR_stats_n_total) AS freq,
--     ct;
-- };
-- -- the much-much-smaller histogram is used to find the total after the fact
-- -- 
-- ASSERT (GROUP HR_hist ALL) 
--   IsEqualish( SUM(freq), 1.0 ),
--   (HR_stats_n_total == SUM(ct);
-- ------
-- 
-- As we said, this is a cheat-to-win scenario: using it to knock three minutes off an eight minute job is canny when used to make better use of a human data scientist's time, foolish when applied as a production performance optimization.
