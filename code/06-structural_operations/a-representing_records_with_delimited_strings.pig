IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
park_teams   = load_park_teams();
parks        = load_parks();


-- ***************************************************************************
--
-- === Representing a Collection of Values with a Delimited String
--

-- The BagToString function will serialize a bag of values into a single
-- delimited field as follows:
--
team_year_w_parks = FOREACH (GROUP park_teams BY (team_id, year_id)) GENERATE
  group.team_id,
  COUNT_STAR(park_teams) AS n_parks,
  BagToString(park_teams.park_id, '^') AS park_ids;
--
-- -- (ALT,1,ALT01)
-- -- (ANA,1,ANA01)
-- -- ...
-- -- (CL4,7,CHI08^CLE05^CLL01^PHI09^ROC02^ROC03^STL05)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Representing a Complex Data Structure with a Delimited String
--

-- Instead of a simple list of park ids, we'd now like to serialize a collection
-- of (park id, number of games) pairs. We can handle this case, and the case
-- where we want to serialize an object with simple attribute-value pairs, by
-- using two delimiters: one for separating list elements and one for delimiting
-- its contents.
--
team_year_w_pkgms = FOREACH (GROUP park_teams BY (team_id,year_id)) {
  pty_ordered     = ORDER park_teams BY n_games DESC;
  pk_ng_pairs     = FOREACH pty_ordered GENERATE
    CONCAT(park_id, ':', (chararray)n_games) AS pk_ng_pair;
  --
  GENERATE group.team_id, group.year_id,
    COUNT_STAR(park_teams) AS n_parks,
    BagToString(pk_ng_pairs,'|') AS pk_ngs;
  };
--
-- -- ALT  1   ALT01:18
-- -- ANA  1   ANA01:82
-- -- ...
-- -- CL4  7   CLE05:40|PHI09:9|STL05:2|ROC02:2|CLL01:2|CHI08:1|ROC03:1

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Representing a Complex Data Structure with a JSON-encoded String
--

-- So their extreme position is not a mistake; is it an anomaly? The first three
-- characters of the park id mirror the city name, so we can identify not just
-- alternative parks but season spent in alternative cities. And since an 1898
-- season is quite pre-modern, let's also keep around the year_id field to see
-- what it says.

-- Prepare the city field
pktm_city     = FOREACH park_teams GENERATE
  team_id, year_id, park_id, n_games,
  SUBSTRING(park_id, 0,3) AS city;

-- First grouping: stats about each city of residence
pktm_stats = FOREACH (GROUP pktm_city BY (team_id, year_id, city)) {
  pty_ordered   = ORDER   pktm_city BY n_games DESC;
  pk_ct_pairs   = FOREACH pty_ordered GENERATE CONCAT(park_id, ':', (chararray)n_games);
  GENERATE
    group.team_id,
    group.year_id,
    group.city                   AS city,
    COUNT_STAR(pktm_city)        AS n_parks,
    SUM(pktm_city.n_games)       AS n_city_games,
    MAX(pktm_city.n_games)       AS max_in_city,
    BagToString(pk_ct_pairs,'|') AS parks
    ;
};

--
-- TODO: make the code better match the story here, make the record a bit less
-- byzantine.
--
-- Next, assemble full picture:
farhome_gms = FOREACH (GROUP pktm_stats BY (team_id, year_id)) {
  pty_ordered   = ORDER   pktm_stats BY n_city_games DESC;
  city_pairs    = FOREACH pty_ordered GENERATE CONCAT(city, ':', (chararray)n_city_games);
  n_home_gms    = SUM(pktm_stats.n_city_games);
  n_main_city   = MAX(pktm_stats.n_city_games);
  n_main_park   = MAX(pktm_stats.max_in_city);
  -- a nice trick to make the modern-ness easily visible while scanning the data:
  is_modern     = (group.year_id >= 1905 ? 'mod' : NULL);
  --
  GENERATE group.team_id, group.year_id,
    is_modern                      AS is_modern,
    n_home_gms                     AS n_home_gms,
    n_home_gms - n_main_city       AS n_farhome_gms,
    n_home_gms - n_main_park       AS n_althome_games,
    COUNT_STAR(pktm_stats)         AS n_cities,
    BagToString(city_pairs,'|')    AS cities,
    BagToString(pktm_stats.parks,'|')    AS parks
    ;
};
farhome_gms = ORDER farhome_gms BY n_cities DESC, n_farhome_gms DESC;
--
-- -- CL4	1898	   	57	17	17	6	CLE:40|PHI:9|ROC:3|STL:2|CLL:2|CHI:1	CLE05:40|PHI09:9|ROC02:2|ROC03:1|STL05:2|CLL01:2|CHI08:1
-- -- CLE	1902	   	65	5 	5 	5	CLE:60|FOR:2|COL:1|CAN:1|DAY:1      	CLE05:60|FOR03:2|COL03:1|CAN01:1|DAY01:1
-- -- ...
-- -- MON	2003	mod	81	22	22	2	MON:59|SJU:22                       	MON02:59|SJU01:22
-- -- MON	2004	mod	80	21	21	2	MON:59|SJU:21                       	MON02:59|SJU01:21
-- -- ...
-- -- CHA	1969	mod	81	11	11	2	CHI:70|MIL:11                       	CHI10:70|MIL05:11
-- -- CHA	1968	mod	81	9 	9 	2	CHI:72|MIL:9                        	CHI10:72|MIL05:9
-- -- BRO	1957	mod	77	8 	8 	2	NYC:69|JER:8                        	NYC15:69|JER02:8

STORE_TABLE(team_year_w_parks, 'team_year_w_parks');
STORE_TABLE(team_year_w_pkgms, 'team_year_w_pkgms');
STORE_TABLE('farhome_gms', farhome_gms);
