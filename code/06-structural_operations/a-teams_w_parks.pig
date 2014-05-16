IMPORT 'common_macros.pig'; %DEFAULT out_dir '/data/out/baseball';
park_tm_yr   = load_park_tm_yr();

-- ___________________________________________________________________________
--
-- === GROUP BY
--

-- The GROUP BY operation is at the heart of every structural operation.
-- Here, we collect all the stadiums each team has played for:
--
park_tm_yr_g = GROUP park_tm_yr BY team_id;

-- The result of a group is always a field called 'group', having the schema of
-- the key (atom) or keys (tuple); and then one field per grouped table, each
-- named for the table it came from. Notice that the name we used to refer to
-- the _table_ is now also the name for a _field_. This will confuse you at
-- first, but soon become natural. Until then, use `DESCRIBE` liberally.
--
-- DESCRIBE park_tm_yr_g;
--   park_tm_yr_g: {
--     group: chararray,
--     park_tm_yr: {
--         ( park_id: chararray, team_id: chararray, year_id: long,
--           beg_date: chararray, end_date: chararray, n_games: long ) } }

-- Notice that the _full record_ is kept, even including the keys:
--
-- => LIMIT park_tm_yr_g 2 ; DUMP @;
-- (ALT,{(ALT01,ALT,1884,1884-04-30,1884-05-31,18)})
-- (ANA,{(ANA01,ANA,2001,2001-04-10,2001-10-07,81),(ANA01,ANA,2010,2010-04-05,2010-09-29,81),...})

-- So it's pretty common to immediately project using a FOREACH.
-- Pig lets you put the GROUP BY statement inline
team_py_pairs = FOREACH (GROUP park_tm_yr BY team_id) GENERATE
  group AS team_id, park_tm_yr.(park_id,year_id);

-- Notice the `park_tm_yr.(park_id,year_id)` form, which gives us a bag of
-- (park_id,year_id) pairs. Using `park_tm_yr.park_id, park_tm_yr.year_id`
-- instead gives two bags, one with park_id tuples and one with year_id tuples:
team_py_bags = FOREACH (GROUP park_tm_yr BY team_id) GENERATE
  group AS team_id, park_tm_yr.park_id, park_tm_yr.year_id;

-- Compare:
--
-- => LIMIT team_py_pairs 2 ; DUMP @;
-- (ALT,{(ALT01,1884)})
-- (ANA,{(ANA01,2001),(ANA01,2010),(ANA01,2002),...})
-- => LIMIT team_py_bags 2 ; DUMP @;
-- (ALT, {(ALT01)}, {(1884)})
-- (ANA, {(ANA01),(ANA01),(ANA01),...}, {(2001),(2010),(2002),...})
--
-- DESCRIBE team_py_pairs;
--   team_parks: { team_id: chararray, { (park_id: chararray, year_id: long) } }
-- DESCRIBE team_py_bags;
--   team_parks: { team_id: chararray, { (park_id: chararray) }, { (year_id: long) } }

-- You can group on multiple fields.  For each park and team, find all the years
-- that the park hosted that team:
--
park_team_g = GROUP park_tm_yr BY (park_id, team_id);
--
-- The first field is still called 'group', but it's now a tuple
--
-- DESCRIBE park_team_g;
--   park_team_g: {
--     group: (park_id: chararray, team_id: chararray),
--     park_tm_yr: { (park_id: chararray, team_id: chararray, year_id: long, ...) } }
--
-- And so we have to dereference into group:
park_team_occupied = FOREACH(GROUP park_tm_yr BY (park_id, team_id)) GENERATE
  group.park_id, group.team_id, park_tm_yr.year_id;
--
-- => LIMIT park_team_occupied 3 ; DUMP @;
-- (ALB01,TRN,{(1882),(1880),(1881)})
-- (ALT01,ALT,{(1884)})
-- (ANA01,ANA,{(2009),(2008),(1997)...})
--

-- ___________________________________________________________________________
--
-- === You can do stuff to groups!
--

-- Operations that summarize the grouped value: This finds all teams that called
-- more than one stadium "home" during a year:
team_n_parks = FOREACH (GROUP park_tm_yr BY (team_id,year_id)) GENERATE
  group.team_id,
  group.year_id,
  COUNT_STAR(park_tm_yr) AS n_parks;
vagabonds = FILTER team_n_parks BY n_parks > 1;
-- => LIMIT (ORDER vagabonds BY n_parks DESC) 4; DUMP @;

-- Always, always look through the data and seek 'second stories'. In this case
-- you'll notice that the 1898 Cleveland Spiders used seven stadiums as home
-- field. The second story: labor problems shut down their normal home field for
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

-- ___________________________________________________________________________
--
-- It's occasionally handy to denormalize a collection of values into a single
-- delimited field. The original teams table has a ballpark column listing only
-- the team's most frequent home stadium for each season. We can prepare a table
-- with a ball _parks_ column naming all ballparks the team played at that
-- season:
--

-- Serialize a bag of values into a single delimited field^
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
