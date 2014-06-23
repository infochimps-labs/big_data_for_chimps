IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Partitioning Data into Multiple Files By Key
--

-- Ue the multistorage storefunc from the Piggybank UDF collection.

STORE events INTO '$out_dir/evs_away'
  USING MultiStorage('$out_dir/evs_away','5'); -- field 5: away_team_id
STORE events INTO '$out_dir/evs_home'
  USING MultiStorage('$out_dir/evs_home','6'); -- field 6: home_team_id

--
-- This script will run a map-only job with 9 map tasks (assuming 1GB+ of data and a 128MB block size). With MultiStorage, all Boston Red Sox (team id `BOS`) home games that come from say the fifth map task will go into `$out_dir/evs_home/BOS/part-m-0004` (contrast that to the normal case of  `$out_dir/evs_home/part-m-00004`). Each map task would write its records into the sub directory named for the team with the `part-m-` file named for its taskid index.

-- Since most teams appear within each input split, each subdirectory will have a full set of part-m-00000 through part-m-00008 files. In our runs, we ended up with XXX output files -- not catastrophic, but (a) against best practices, (b) annoying to administer, (c) the cause of either nonlocal map tasks (if splits are combined) or proliferation of downstream map tasks (if splits are not combined). The methods of (REF) "Cleaning up Many Small Files" would work, but you'll need to run a cleanup job per team. Better by far is to precede the `STORE USING MultiStorage` step with a `GROUP BY team_id`. We'll learn all about grouping next chapter, but its use should be clear enough: all of each team's events will be sent to a common reducer; as long as the Pig `pig.output.lazy` option is set, the other reducers will not output files.

events_by_away = FOREACH (GROUP events BY away_team_id) GENERATE FLATTEN(events);
events_by_home = FOREACH (GROUP events BY home_team_id) GENERATE FLATTEN(events);
STORE events_by_away INTO '$out_dir/evs_away-g'
  USING MultiStorage('$out_dir/evs_away-g','5'); -- field 5: away_team_id
STORE events_by_home INTO '$out_dir/evs_home-g'
  USING MultiStorage('$out_dir/evs_home-g','6'); -- field 6: home_team_id
-- sh cp $data_dir/sports/baseball/events/.pig_schema $out_dir/evs_away-g

-- Lastly, a couple notes about MultiStorage. It only partitions by a single key field in each record, and that key will is unavoidably written to disk along with the records -- you need to be OK with it sticking around. If the key is null, the word 'null' will be substituted without warning. (TODO check). You can produce compressed output by supplying an additional option; see the documentation. Lastly, it does not accept PigStorage's advanced options such as writing schema files or overwriting output.
