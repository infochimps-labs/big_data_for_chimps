IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_tm_yr();

-- ***************************************************************************
--
-- === Joining Records Without Discarding Non-Matches (Outer Join)
--

career_stats = FOREACH (
  JOIN
    bat_careers BY player_id LEFT OUTER,
    batting_hof BY player_id) GENERATE
  bat_careers::player_id..bat_careers::OPS, allstars::year_id AS hof_year;

-- ==== Joining Tables that do not have a Foreign-Key Relationship

geolocated_somewhat = JOIN
  people BY (birth_city, birth_state, birth_country),
  places BY (city, admin_1, country_id)
