IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- ==== Parsing a Delimited String into a Collection of Values
--

-- TSV (tab-separated-values) is the Volkswagen Beetle of go-anywhere file formats: it's robust, simple, friendly and works everywhere. However, it has significant drawbacks, most notably that it can only store flat records: a member field with, say, an array type must be explicitly handled after loading. One common workaround for serializing an array type is to convert the array into a string, where each value is separated from the next using a delimiter -- a character that doesn't appear in any of the values. We'll demonstrate creating such a field in the next chapter (REF), and in fact we're going to sneak into the future and steal that section's output files.

team_parkslists = LOAD team_parklists AS (...)
xxx = FOREACH ... {
  parks = STRSPLITBAG(...);
  GENERATE ..., FLATTEN(parks), ...;
};

-- In other cases the value may not be a bag holding an arbitrarily-sized collection of values, but a tuple holding several composite fields. Among other examples, it's common to find addresses serialized this way. The people table has fields for (city,state,country) of both birth and death. We will demonstrate by first creating single birth_loc and death_loc fields, then untangling them.

people_shrunk = FOREACH people GENERATE
  player_id..birth_day,
  CONCAT(birth_city,'|', birth_state, '|', birth_country) AS birth_loc,
  death_year, death_month, death_day,
  CONCAT(death_city,'|', death_state, '|', death_country) AS death_loc,
  name_first.. ;

people_2 = FOREACH people_shrunk GENERATE
  player_id..birth_day,
  FLATTEN(STRSPLIT(birth_loc)) AS (birth_city, birth_state, birth_country),
  death_year, death_month, death_day,
  FLATTEN(STRSPLIT(death_loc)) AS (death_city, death_state, death_country),
  name_first.. ;

In this case we apply STRSPLIT, which makes a tuple (rather than STRSPLITBAG, which makes a bag). When we next apply FLATTEN to our tuple, it turns its fields into new columns (rather than if we had a bag, which would generate new rows). You can run the sample code to verify the output and input are identical.

-- TODO-qem (combine this with the later chapter? There's a lot going on there, so I think no, but want opinion)

STORE_TABLE(people_2, 'people_2');


