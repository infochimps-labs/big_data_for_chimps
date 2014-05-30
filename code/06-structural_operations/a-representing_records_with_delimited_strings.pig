IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Grouping Records into a Bag by Key
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Nested GROUP BY

-- ***************************************************************************
--
-- === Representing a Collection of Values with a Delimited String
-- 


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Representing a Complex Data Structure with a Delimited String
--


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Representing a Complex Data Structure with a JSON-encoded String
--

-- team_park_years = FOREACH pty GENERATE team_id, park_id, year_id, n_games;
-- team_park_years = ORDER team_park_years BY team_id ASC, year_id ASC, n_games ASC, park_id ASC;
-- STORE_TABLE('team_park_years', team_park_years);

parks = FOREACH parks GENERATE
  park_id, beg_date, end_date, n_games,
  lng, lat, country_id, state_id, city, park_name, comments;

STORE_TABLE('parks', parks);

-- pty = FILTER (FOREACH pty GENERATE park_id, team_id, year_id) BY
--   true
--   -- AND team_id IN ('BOS', 'NYA', 'SDN')
--   -- AND year_id >= 1995 AND year_id < 2000
--   ;
--
-- team_parks = FOREACH (GROUP pty BY (team_id, park_id)) GENERATE
--   group.team_id, group.park_id, pty.year_id AS years;
-- DUMP team_parks;
-- 
-- rmf                    team_parks;
-- STORE team_parks INTO 'team_parks';
--
-- team_parks = LOAD 'team_parks' AS (team_id:chararray, park_id:chararray, years:bag{(year_id:int)});
-- cat                team_parks;
-- -- BOS     BOS07   {(1995),(1997),(1990),(1992),(1996),(1993),(1991),(1998),(1994),(1999)}
-- -- NYA     NYC16   {(1995),(1999),(1998),(1997),(1996),(1994),(1993),(1992),(1991),(1990)}
-- -- NYA     NYC17   {(1998)}
-- -- SDN     HON01   {(1997)}
-- -- SDN     MNT01   {(1996),(1999)}
-- -- SDN     SAN01   {(1999),(1997),(1993),(1992),(1990),(1998),(1991),(1995),(1996),(1994)}
-- 
-- 
-- --
-- -- Simple delimited strings are simple:
-- --
-- team_parkslist = FOREACH (GROUP team_parks BY team_id) GENERATE
--   group AS team_id, BagToString(team_parks.park_id, ';');
-- rmf                            /tmp/team_parkslist;
-- STORE team_parkslist     INTO '/tmp/team_parkslist';
-- cat                            /tmp/team_parkslist;
-- -- BOS     BOS07
-- -- NYA     NYC17;NYC16
-- -- SDN     SAN01;MNT01;HON01
-- 
-- -- Default handling of complex elements probably isn't what you want.
-- team_parkyearsugly = FOREACH (GROUP team_parks BY team_id) GENERATE
--   group AS team_id,
--   BagToString(team_parks.(park_id, years));
-- 
-- rmf                            /tmp/team_parkyearsugly;
-- STORE team_parkyearsugly INTO '/tmp/team_parkyearsugly';
-- cat                            /tmp/team_parkyearsugly;
-- 
-- -- BOS     BOS07_{(1995),(1997),(1990),(1992),(1996),(1993),(1991),(1998),(1994),(1999)}
-- -- NYA     NYC17_{(1998)}_NYC16_{(1995),(1999),(1998),(1997),(1996),(1994),(1993),(1992),(1991),(1990)}
-- -- SDN     SAN01_{(1999),(1997),(1993),(1992),(1990),(1998),(1991),(1995),(1996),(1994)}_MNT01_{(1996),(1999)}_HON01_{(1997)}
-- 
-- -- Instead, assemble it in pieces.
-- team_park_yearslist = FOREACH team_parks {
--   years_o = ORDER years BY year_id;
--   GENERATE team_id, park_id, SIZE(years_o) AS n_years, BagToString(years_o, '/') AS yearslist;
-- };
-- -- Note that we sort on the first-seen-year but then project it out.
-- team_parkyearslist = FOREACH (GROUP team_park_yearslist BY team_id) {
--   tpy_o = ORDER team_park_yearslist BY n_years DESC, park_id ASC;
--   tpy_f = FOREACH tpy_o GENERATE CONCAT(park_id, ':', yearslist);
--   GENERATE group AS team_id, BagToString(tpy_f, ';');
--   };
-- 
-- rmf                            /tmp/team_parkyearslist;
-- STORE team_parkyearslist INTO '/tmp/team_parkyearslist';
-- cat                            /tmp/team_parkyearslist;
-- 
-- -- BOS     BOS07:1990/1991/1992/1993/1994/1995/1996/1997/1998/1999
-- -- NYA     NYC16:1990/1991/1992/1993/1994/1995/1996/1997/1998/1999;NYC17:1998
-- -- SDN     SAN01:1990/1991/1992/1993/1994/1995/1996/1997/1998/1999;MNT01:1996/1999;HON01:1997
