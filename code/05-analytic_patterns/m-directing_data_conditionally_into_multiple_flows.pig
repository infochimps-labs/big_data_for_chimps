IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Directing Data Conditionally into Multiple Data Flows
--

-- TODO integrate prose

-- The most natural use of the SPLIT operator is when you really do require divergent processing flows. In the next chapter, you'll use a JOIN LEFT OUTER to geolocate (derive longitude and latitude from place name) records. That method is susceptible to missing matches, and so in practice a next step might be to apply a fancier but more costly geolocation tool. This is a strategy that arises often in advanced machine learning applications: run a first pass with a cheap algorithm that can estimate its error rate; isolate the low-confidence results for harder processing; then reunite the whole dataset.

-- Run the 06-.../Matching_records_imperfectly...
-- (Most records have been geolocated)

-- The syntax of the SPLIT command does not have an equals sign to the left of it; the new table aliases are created in its body.
SPLIT players_geoloced_some INTO 
  players_non_geoloced_us IF ((IsNull(lng) OR IsNull(lat)) AND (country_id == "US")),
  players_non_geoloced_fo IF ((IsNull(lng) OR IsNull(lat)),
  players_geoloced_a OTHERWISE;
  
-- ... Pretend we're applying a more costly / higher quality geolocation tool, rather than just sending all unmatched records to Disneyland...
players_geoloced_b = FOREACH players_non_geoloced_us GENERATE
  player_id..country_id,
  FLATTEN((Disney,land)) as (lng, lat);
-- ... And again, pretend we are not just sending all non-us to the Eiffel Tower.
players_geoloced_c = FOREACH players_non_geoloced_us GENERATE
  player_id..country_id,
  FLATTEN((Eiffel,tower)) as (lng, lat);

Players_geoloced = UNION alloftheabove;


-- The SPLIT statement is fairly rare in use, and though its own performance cost is low it can lead to proliferation of code paths and map-reduce jobs downstream. If the different streams receive significantly different schema or different processing downstream, the SPLIT statement is justified. But if you follow a SPLIT statement with parallel repeated stanzas applied to each stream, consider whether you're not better off using a case or ternary statement (REF); the "Partitioning Data By Keys into Multiple Files" (REF) pattern; the "Summarizing Multiple Subsets of a Table Simultaneously" (REF) pattern; or some other application of the "summing trick" (REF) introduced in the next chapter.