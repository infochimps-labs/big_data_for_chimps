IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();


-- ***************************************************************************
--
-- === Representing a Collection of Values with a Delimited String
-- 


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Representing a Complex Data Structure with a Delimited String
--

-- ___________________________________________________________________________
--
-- It's occasionally handy to denormalize a collection of values into a single
-- delimited field. The original teams table has a ballpark column listing only
-- the team's most frequent home stadium for each season. We can prepare a table
-- with a ball _parks_ column naming all ballparks the team played at that
-- season:
--


-- Serialize a bag of values into a single delimited field
team_year_w_parks = FOREACH (GROUP park_tm_yr BY (team_id, year_id)) {
  GENERATE group.team_id, group.year_id,
    COUNT_STAR(park_tm_yr) AS n_parks,
    BagToString(park_tm_yr.park_id,'^') AS park_ids;
  };
-- => LIMIT team_year_w_parks 4 ; DUMP @;
-- (ALT,1884,ALT01)
-- (ANA,1997,ANA01)
-- ...
-- (CL4,1898,CHI08^CLE05^CLL01^PHI09^ROC02^ROC03^STL05)


-- The second story: labor problems shut down their normal home field for
-- stretches of time that year, relocating them to Philadelphia, Rochester,
-- St. Louis, and Chicago. What's more, during a Sunday June 19th home game,
-- police arrested the entire team for violating "blue laws" that forbid work
-- on Sunday footnote:[As late as 1967, selling a 'Corning Ware dish with lid'
-- in Ohio was still enough to get you convicted of "Engaging in common labor on
-- Sunday": www.leagle.com/decision/19675410OhioApp2d44_148] footnote:[The
-- Baseball Library Chronology does note that "not so coincidentally‚ the
-- Spiders had just scored to go ahead 4-3‚ so the arrests assured Cleveland of
-- a victory."  Hopefully the officers got to enjoy a few innings of the game.]!
-- Little wonder they spent almost three-quarters of their season elsewhere: 99
-- road games, 15 "home games" held in other cities, and only 42 in Cleveland.
-- The following year they played 50 straight on the road, won fewer than 13%
-- overall (20-134, the worst single-season record ever) and then disbanded. Oh,
-- Cleveland.
--
-- http://www.baseballlibrary.com/chronology/byyear.php?year=1898
-- http://www.baseball-reference.com/teams/CLV/1898.shtml
-- http://www.leagle.com/decision/19675410OhioApp2d44_148

-- To serialize a bag of tuples using two delimiters, use an inner FOREACH. This
-- creates a single field naming the home stadiums and number of games for each:
--
team_year_w_pkgms = FOREACH (GROUP park_tm_yr BY (team_id,year_id)) {
  pty_ordered     = ORDER park_tm_yr BY n_games DESC;
  pk_ng_pairs     = FOREACH pty_ordered GENERATE CONCAT(park_id, ':', (chararray)n_games) AS pk_ng_pair;
  --
  GENERATE group.team_id, group.year_id,
    COUNT_STAR(park_tm_yr) AS n_parks,
    BagToString(pk_ng_pairs,'^') AS pk_ngs;
  };
-- => LIMIT team_year_w_pkgms 4 ; DUMP @;
-- (ALT,1884,ALT01:18)
-- (ANA,1997,ANA01:82)
-- ...
-- (CL4,1898,CLE05:40^PHI09:9^STL05:2^ROC02:2^CLL01:2^CHI08:1^ROC03:1)

vagabonds   = FILTER team_year_w_pkgms BY n_parks > 1;
nparks_hist = FOREACH (GROUP vagabonds BY year_id)
  GENERATE group AS year_id, CountVals(vagabonds.n_parks) AS hist_u;
nparks_hist = FOREACH nparks_hist {
  hist_o     = ORDER   hist_u BY n_parks ASC;
  hist_pairs = FOREACH hist_o GENERATE CONCAT((chararray)count, ':', (chararray)n_parks);
  GENERATE year_id, BagToString(hist_pairs, ' ^ ');
  };
--
DESCRIBE nparks_hist;
=> ORDER nparks_hist BY year_id; DUMP @;

pty2_f       = FOREACH park_tm_yr GENERATE
  team_id, year_id, park_id, n_games,
  SUBSTRING(park_id, 0,3) AS city;
pty2       = FOREACH (GROUP pty2_f BY (team_id, year_id, city)) {
  pty_ordered   = ORDER   pty2_f BY n_games DESC;
  pk_ng_pairs   = FOREACH pty_ordered GENERATE CONCAT(park_id, ':', (chararray)n_games);
  GENERATE
    group.team_id, group.year_id,
    group.city                   AS city,
    COUNT_STAR(pty2_f)           AS n_parks,
    SUM(pty2_f.n_games)          AS n_city_games,
    BagToString(pk_ng_pairs,'^') AS parks
    ;
};

roadhome_gms = FOREACH (GROUP pty2 BY (team_id, year_id)) {
  pty_ordered   = ORDER   pty2 BY n_city_games DESC;
  city_pairs    = FOREACH pty_ordered GENERATE CONCAT(city, ':', (chararray)n_city_games);
  n_home_gms    = SUM(pty2.n_city_games);
  n_main_gms    = MAX(pty2.n_city_games);
  is_modern     = (group.year_id >= 1905 ? 'mod' : NULL);
  --
  GENERATE group.team_id, group.year_id,
    is_modern                      AS is_modern,
    n_home_gms                     AS n_home_gms,
    n_home_gms - n_main_gms        AS n_roadhome_gms,
    COUNT_STAR(pty2)               AS n_cities,
    BagToString(city_pairs,'^')    AS cities,
    BagToString(pty2.parks,'^')    AS parks
    ;
};

-- roadhome_gms = FILTER roadhome_gms BY n_cities > 1;
-- roadhome_gms = ORDER roadhome_gms BY n_roadhome_gms DESC;
-- STORE_TABLE('roadhome_gms', roadhome_gms);
-- cat $out_dir/roadhome_gms;



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
