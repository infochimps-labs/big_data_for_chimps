IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Grouping Records into a Bag by Key
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

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ===== You can do stuff to groups!
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
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
bat_seasons   = load_bat_seasons();


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Calculating Quantiles
--

--
-- Example of quantile extraction
--

-- Adding in a little randomness so that the values on the boundary don't stack up
vals = FOREACH bat_seasons GENERATE
  weight + 0.001*RANDOM() AS val
  ;

h_4ile = FOREACH (GROUP (FILTER vals BY val IS NOT NULL) ALL) {
  sorted = ORDER    $1.val BY val;
  GENERATE
    FLATTEN(SortedQuartile(sorted))
  ;
};
DESCRIBE h_4ile;
DUMP h_4ile;

cts = FOREACH vals {
  GENERATE
    ((val >= (double)h_4ile.quantile_0_0  AND val <  (double)h_4ile.quantile_0_25) ? 1 : 0) AS is_q1,
    ((val >= (double)h_4ile.quantile_0_25 AND val <  (double)h_4ile.quantile_0_5 ) ? 1 : 0) AS is_q2,
    ((val >= (double)h_4ile.quantile_0_5  AND val <  (double)h_4ile.quantile_0_75) ? 1 : 0) AS is_q3,
    ((val >= (double)h_4ile.quantile_0_75 AND val <= (double)h_4ile.quantile_1_0 ) ? 1 : 0) AS is_q4
    ;
};

dist = FOREACH (GROUP cts ALL) {
  n_vals = COUNT_STAR(cts);
  GENERATE
    n_vals,
    SUM(cts.is_q1)  AS q1_ct,
    SUM(cts.is_q2)  AS q2_ct,
    SUM(cts.is_q3)  AS q3_ct,
    SUM(cts.is_q4)  AS q4_ct
    ;
};

DUMP dist;
  
bins = FOREACH vals GENERATE ROUND_TO(val, 0) AS bin;
hist = FOREACH (GROUP bins BY bin) GENERATE
  group AS bin, COUNT_STAR(bins) AS ct;
DUMP hist;

-- tc_cities = load_us_city_pops();
-- 
-- parks = load_parks();
-- parks  = FILTER parks BY n_games > 50;
-- bb_cities = FOREACH parks GENERATE park_id, city;
-- 
-- summary = summarize_strings_by(parks, 'park_id',    'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'park_name',  'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'city',       'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'streetaddr', 'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'url',        'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'allnames',   'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'allteams',   'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'comments',   'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'state_id',   'ALL'); DUMP summary;
-- summary = summarize_strings_by(parks, 'country_id', 'ALL'); DUMP summary;
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
IMPORT 'summarizer_bot_9000.pig';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Completely Summarizing the Values of a Numeric Field
--

H_summary_base = FOREACH (GROUP bat_seasons ALL) {
  dist       = DISTINCT bat_seasons.H;
  examples   = LIMIT    dist.H 5;
  n_recs     = COUNT_STAR(bat_seasons);
  n_notnulls = COUNT(bat_seasons.H);
  GENERATE
    group,
    'H'                       AS var:chararray,
    MIN(bat_seasons.H)             AS minval,
    MAX(bat_seasons.H)             AS maxval,
    --
    AVG(bat_seasons.H)             AS avgval,
    SQRT(VAR(bat_seasons.H))       AS stddev,
    SUM(bat_seasons.H)             AS sumval,
    --
    n_recs                         AS n_recs,
    n_recs - n_notnulls            AS n_nulls,
    COUNT(dist)                    AS cardinality,
    BagToString(examples, '^')     AS examples
    ;
};
-- (all,H,46.838027175098475,56.05447208643693,0,262,77939,0,250,3650509,0^1^2^3^4)

H_summary = FOREACH (GROUP bat_seasons ALL) {
  dist       = DISTINCT bat_seasons.H;
  non_nulls  = FILTER   bat_seasons.H BY H IS NOT NULL;
  sorted     = ORDER    non_nulls BY H;
  examples   = LIMIT    dist.H 5;
  n_recs     = COUNT_STAR(bat_seasons);
  n_notnulls = COUNT(bat_seasons.H);
  GENERATE
    group,
    'H'                       AS var:chararray,
    MIN(bat_seasons.H)             AS minval,
    FLATTEN(SortedEdgeile(sorted)) AS (p01, p05, p10, p50, p90, p95, p99),
    MAX(bat_seasons.H)             AS maxval,
    --
    AVG(bat_seasons.H)             AS avgval,
    SQRT(VAR(bat_seasons.H))       AS stddev,
    SUM(bat_seasons.H)             AS sumval,
    --
    n_recs                         AS n_recs,
    n_recs - n_notnulls            AS n_nulls,
    COUNT(dist)                    AS cardinality,
    BagToString(examples, '^')     AS examples
    ;
};
-- (all,H,46.838027175098475,56.05447208643693,0,0.0,0.0,0.0,17.0,141.0,163.0,193.0,262,77939,0,250,3650509,0^1^2^3^4)

-- ***************************************************************************
--
-- === Completely Summarizing the Values of a String Field
--

name_first_summary_0 = FOREACH (GROUP bat_seasons ALL) {
  dist       = DISTINCT bat_seasons.name_first;
  lens       = FOREACH  bat_seasons GENERATE SIZE(name_first) AS len; -- Coalesce(name_first,'')
  --
  n_recs     = COUNT_STAR(bat_seasons);
  n_notnulls = COUNT(bat_seasons.name_first);
  --
  examples   = LIMIT    dist.name_first 5;
  snippets   = FOREACH  examples GENERATE (SIZE(name_first) > 15 ? CONCAT(SUBSTRING(name_first, 0, 15),'…') : name_first) AS val;
  GENERATE
    group,
    'name_first'                   AS var:chararray,
    MIN(lens.len)                  AS minlen,
    MAX(lens.len)                  AS maxlen,
    --
    AVG(lens.len)                  AS avglen,
    SQRT(VAR(lens.len))            AS stdvlen,
    SUM(lens.len)                  AS sumlen,
    --
    n_recs                         AS n_recs,
    n_recs - n_notnulls            AS n_nulls,
    COUNT(dist)                    AS cardinality,
    MIN(bat_seasons.name_first)    AS minval,
    MAX(bat_seasons.name_first)    AS maxval,
    BagToString(snippets, '^')     AS examples,
    lens  AS lens
    ;
};

name_first_summary = FOREACH name_first_summary_0 {
  sortlens   = ORDER lens  BY len;
  pctiles    = SortedEdgeile(sortlens);
  GENERATE
    var,
    minlen, FLATTEN(pctiles) AS (p01, p05, p10, p50, p90, p95, p99), maxlen,
    avglen, stdvlen, sumlen,
    n_recs, n_nulls, cardinality,
    minval, maxval, examples
    ;
};

-- => LIMIT nf_chars 200 ; DUMP @;
-- STORE_TABLE(name_first_summary, 'name_first_summary');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
IMPORT 'summarizer_bot_9000.pig';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Pig Macros
--

nums_header = numeric_summary_header();
strs_header = strings_summary_header();

-- ***************************************************************************
--
-- === Pig Macros
--

-- (see code in ../common_macros)

-- player_id_summary  = summarize_strings_by(bat_seasons, 'player_id',  'ALL');
-- name_first_summary = summarize_strings_by(bat_seasons, 'name_first', 'ALL');
-- name_last_summary  = summarize_strings_by(bat_seasons, 'name_last',  'ALL');
-- team_id_summary    = summarize_strings_by(bat_seasons, 'team_id',    'ALL');
-- lg_id_summary      = summarize_strings_by(bat_seasons, 'lg_id',      'ALL');
year_id_summary    = summarize_numeric(bat_seasons,   'year_id',    'ALL');
age_summary        = summarize_numeric(bat_seasons,   'age',        'ALL');
G_summary          = summarize_numeric(bat_seasons,   'G',          'ALL');
PA_summary         = summarize_numeric(bat_seasons,   'PA',         'ALL');
AB_summary         = summarize_numeric(bat_seasons,   'AB',         'ALL');
HBP_summary        = summarize_numeric(bat_seasons,   'HBP',        'ALL');
SH_summary         = summarize_numeric(bat_seasons,   'SH',         'ALL');
BB_summary         = summarize_numeric(bat_seasons,   'BB',         'ALL');
H_summary          = summarize_numeric(bat_seasons,   'H',          'ALL');
h1B_summary        = summarize_numeric(bat_seasons,   'h1B',        'ALL');
h2B_summary        = summarize_numeric(bat_seasons,   'h2B',        'ALL');
h3B_summary        = summarize_numeric(bat_seasons,   'h3B',        'ALL');
HR_summary         = summarize_numeric(bat_seasons,   'HR',         'ALL');
R_summary          = summarize_numeric(bat_seasons,   'R',          'ALL');
RBI_summary        = summarize_numeric(bat_seasons,   'RBI',        'ALL');

summaries = UNION
  -- player_id_summary, name_first_summary, name_last_summary,
  -- year_id_summary,   team_id_summary,    lg_id_summary,
  age_summary, G_summary, PA_summary, AB_summary,
  HBP_summary, SH_summary, BB_summary, H_summary,
  h1B_summary, h2B_summary, h3B_summary, HR_summary,
  R_summary, RBI_summary ;

-- STORE_TABLE(player_id_summary,  'player_id_summary' );
-- STORE_TABLE(name_first_summary, 'name_first_summary');
-- STORE_TABLE(name_last_summary,  'name_last_summary' );
-- STORE_TABLE(team_id_summary,    'team_id_summary'   );
-- STORE_TABLE(lg_id_summary,      'lg_id_summary'     );
STORE_TABLE(year_id_summary,    'year_id_summary');
STORE_TABLE(age_summary,        'age_summary'    );
STORE_TABLE(G_summary,          'G_summary'      );
STORE_TABLE(PA_summary,         'PA_summary'     );
STORE_TABLE(AB_summary,         'AB_summary'     );
STORE_TABLE(HBP_summary,        'HBP_summary'    );
STORE_TABLE(SH_summary,         'SH_summary'     );
STORE_TABLE(BB_summary,         'BB_summary'     );
STORE_TABLE(H_summary,          'H_summary'      );
STORE_TABLE(h1B_summary,        'h1B_summary'    );
STORE_TABLE(h2B_summary,        'h2B_summary'    );
STORE_TABLE(h3B_summary,        'h3B_summary'    );
STORE_TABLE(HR_summary,         'HR_summary'     );
STORE_TABLE(R_summary,          'R_summary'      );
STORE_TABLE(RBI_summary,        'RBI_summary'    );

-- STORE_TABLE(summaries, 'summaries');

STORE_TABLE(nums_header, 'nums_header');
STORE_TABLE(strs_header, 'strs_header');

cat $out_dir/strs_header/part-m-00000;
cat $out_dir/nums_header/part-m-00000;
-- cat $out_dir/summaries;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Completely Summarizing the Values of a String Field
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Finding the Size of a String in Bytes or in Characters
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Completely Summarizing the Values of a Numeric Field
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Summarizing Aggregate Statistics of a Full Table
--


bat_seasons = FOREACH bat_seasons GENERATE *, (float)HR*HR AS HRsq:float;

hr_stats = FOREACH (GROUP bat_seasons ALL) {
  hrs_distinct = DISTINCT bat_seasons.HR;
  GENERATE
    MIN(bat_seasons.HR)        AS hr_min,
    MAX(bat_seasons.HR)        AS hr_max,
    AVG(bat_seasons.HR)        AS hr_avg,
    SUM(bat_seasons.HR)        AS hr_sum,
    SQRT(VAR(bat_seasons.HR))  AS hr_stdev,
    SQRT((SUM(bat_seasons.HRsq)/COUNT(bat_seasons)) - (AVG(bat_seasons.HR)*AVG(bat_seasons.HR))) AS hr_stdev2,
    COUNT_STAR(bat_seasons)    AS n_recs,
    COUNT_STAR(bat_seasons) - COUNT(bat_seasons.HR) AS hr_n_nulls,
    COUNT(hrs_distinct) AS hr_card
    ;
  }

rmf                  $out_dir/hr_stats;
STORE hr_stats INTO '$out_dir/hr_stats';
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons   = load_bat_seasons();

-- === Summarizing Aggregate Statistics of a Group
-- ==== Average of all non-Null values
-- ==== Count of Distinct Values
-- ==== Count of non-Null values
-- ==== Median (50th Percentile Value) of a Bag
-- ==== Minimum / Maximum non-Null value
-- ==== Size of Bag (Count of all values, Null or not)
-- ==== Standard Deviation of all non-Null Values
-- ==== Sum of non-Null values

--
-- * COUNT_STAR(bag)              -- Counting records in a bag
-- * COUNT(bag)                   -- Counting non-null values in a bag
-- * DISTINCT;..COUNT_STAR        -- Counting Distinct Values in a bag
--
-- * SUM(bag)                     -- Totalling
-- * AVG(bag)                     -- 
-- * VAR(bag)                     -- 
-- * SQRT(VAR(bag))               -- 
-- * MIN(bag)                     -- Minimum value
-- * MAX(bag)                     -- Maximum value
-- * BagToString(bag, delimiter)  -- 


-- Turn the batting season statistics into batting career statistics
--
bat_careers = FOREACH (GROUP bat_seasons BY player_id) {
  team_ids = DISTINCT bat_seasons.team_id;
  totG   = SUM(bat_seasons.G);   totPA  = SUM(bat_seasons.PA);  totAB  = SUM(bat_seasons.AB);
  totH   = SUM(bat_seasons.H);   totBB  = SUM(bat_seasons.BB);  totHBP = SUM(bat_seasons.HBP); totR   = SUM(bat_seasons.R);    
  toth1B = SUM(bat_seasons.h1B); toth2B = SUM(bat_seasons.h2B); toth3B = SUM(bat_seasons.h3B); totHR  = SUM(bat_seasons.HR); 
  OBP    = (totH + totBB + totHBP) / totPA;
  SLG    = (toth1B + 2*toth2B + 3*toth3B + 4*totHR) / totAB;
  GENERATE group               AS player_id,
    COUNT_STAR(bat_seasons)        AS n_seasons,
    MIN(bat_seasons.year_id)	     AS beg_year,
    MAX(bat_seasons.year_id)       AS end_year,
    BagToString(team_ids, '^') AS team_ids,
    totG   AS G,   totPA  AS PA,  totAB  AS AB,
    totH   AS H,   totBB  AS BB,  totHBP AS HBP,
    toth1B AS h1B, toth2B AS h2B, toth3B AS h3B, totHR AS HR,
    OBP AS OBP, SLG AS SLG, (OBP + SLG) AS OPS
    ;
};

STORE_TABLE('bat_careers', bat_careers);

DESCRIBE bat_seasons;
DESCRIBE bat_careers;

-- weight_summary = FOREACH (GROUP bat_seasons ALL) {
--   dist         = DISTINCT bat_seasons.weight;
--   sorted_a     = FILTER   bat_seasons.weight BY weight IS NOT NULL;
--   sorted       = ORDER    sorted_a BY weight;
--   some         = LIMIT    dist.weight 5;
--   n_recs       = COUNT_STAR(bat_seasons);
--   n_notnulls   = COUNT(bat_seasons.weight);
--   GENERATE
--     group,
--     AVG(bat_seasons.weight)             AS avg_val,
--     SQRT(VAR(bat_seasons.weight))       AS stddev_val,
--     MIN(bat_seasons.weight)             AS min_val,
--     FLATTEN(SortedEdgeile(sorted))  AS (p01, p05, p50, p95, p99),
--     MAX(bat_seasons.weight)             AS max_val,
--     --
--     n_recs                          AS n_recs,
--     n_recs - n_notnulls             AS n_nulls,
--     COUNT(dist)                     AS cardinality,
--     SUM(bat_seasons.weight)             AS sum_val,
--     BagToString(some, '^')          AS some_vals
--     ;
-- };
-- 
-- DESCRIBE     weight_summary;
-- STORE_TABLE('weight_summary', weight_summary);
-- cat $out_dir/weight_summary;
-- 
-- weight_yr_stats = FOREACH (GROUP bat_seasons BY year_id) {
--   dist         = DISTINCT bat_seasons.weight;
--   sorted_a     = FILTER   bat_seasons.weight BY weight IS NOT NULL;
--   sorted       = ORDER    sorted_a BY weight;
--   some         = LIMIT    dist.weight 5;
--   n_recs       = COUNT_STAR(bat_seasons);
--   n_notnulls   = COUNT(bat_seasons.weight);
--   GENERATE
--     group,
--     AVG(bat_seasons.weight)             AS avg_val,
--     SQRT(VAR(bat_seasons.weight))       AS stddev_val,
--     MIN(bat_seasons.weight)             AS min_val,
--     FLATTEN(SortedEdgeile(sorted))  AS (p01, p05, p50, p95, p99),
--     MAX(bat_seasons.weight)             AS max_val,
--     --
--     n_recs                          AS n_recs,
--     n_recs - n_notnulls             AS n_nulls,
--     COUNT(dist)                     AS cardinality,
--     SUM(bat_seasons.weight)             AS sum_val,
--     BagToString(some, '^')          AS some_vals
--     ;
-- };
-- 
-- DESCRIBE     weight_yr_stats;
-- STORE_TABLE('weight_yr_stats', weight_yr_stats);
-- cat $out_dir/weight_yr_stats;

stats_G   = summarize_values_by(bat_seasons, 'G',   'ALL');    STORE_TABLE('stats_G',   stats_G  );
stats_PA  = summarize_values_by(bat_seasons, 'PA',  'ALL');    STORE_TABLE('stats_PA',  stats_PA  );
stats_H   = summarize_values_by(bat_seasons, 'H',   'ALL');    STORE_TABLE('stats_H',   stats_H  );
stats_HR  = summarize_values_by(bat_seasons, 'HR',  'ALL');    STORE_TABLE('stats_HR',  stats_HR );
stats_OBP = summarize_values_by(bat_seasons, 'OBP', 'ALL');    STORE_TABLE('stats_OBP', stats_OBP);
stats_BAV = summarize_values_by(bat_seasons, 'BAV', 'ALL');    STORE_TABLE('stats_BAV', stats_BAV);
stats_SLG = summarize_values_by(bat_seasons, 'SLG', 'ALL');    STORE_TABLE('stats_SLG', stats_SLG);
stats_OPS = summarize_values_by(bat_seasons, 'OPS', 'ALL');    STORE_TABLE('stats_OPS', stats_OPS);

stats_wt  = summarize_values_by(bat_seasons, 'weight', 'ALL'); STORE_TABLE('stats_wt', stats_wt);
stats_ht  = summarize_values_by(bat_seasons, 'height', 'ALL'); STORE_TABLE('stats_ht', stats_ht);

-- pig ./06-structural_operations/c-summary_statistics.pig
-- cat /data/out/baseball/stats_*/part-r-00000 | wu-lign -- %s %s %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f %7.3f 

-- group   field   average  stdev     min     p01     p05     p10    p50     p90     p95     p99      max  count   nulls   cardnty    sum                  some
-- all     BAV       0.209   0.122   0.000   0.000   0.000   0.000   0.231   0.308   0.333   0.500   1.000 69127     0     11503       14415.623359973975  0.0^0.015625^0.01639344262295082^0.01694915254237288^0.017543859649122806
-- all     G        61.575  49.645   1.000   1.000   3.000   6.000  43.000 143.000 152.000 159.000 165.000 69127     0       165     4256524.000000000000  1^2^3^4^5                                                                
-- all     H        45.956  56.271   0.000   0.000   0.000   0.000  15.000 142.000 163.000 194.000 262.000 69127     0       250     3176790.000000000000  0^1^2^3^4                                                                
-- all     HR        3.751   7.213   0.000   0.000   0.000   0.000   0.000  13.000  20.000  34.000  73.000 69127     0        66      259305.000000000000  0^1^2^3^4                                                                
-- all     OBP       0.259   0.134   0.000   0.000   0.000   0.000   0.286   0.377   0.407   0.556   2.333 69127     0     14214       17872.834545988590  0.0^0.020833334^0.021276595^0.023255814^0.024390243                      
-- all     OPS       0.550   0.308   0.000   0.000   0.000   0.000   0.602   0.838   0.921   1.333   5.000 69127     0     45768       38051.246410079300  0.0^0.021276595^0.02631579^0.027027028^0.028571429                       
-- all     PA      197.398 220.678   1.000   1.000   2.000   4.000  86.000 582.000 643.000 701.000 778.000 69127     0       766    13645539.000000000000  1^2^3^4^5                                                                
-- all     SLG       0.292   0.187   0.000   0.000   0.000   0.000   0.312   0.478   0.525   0.800   4.000 69127     0     16540       20178.412007378414  0.0^0.015625^0.016393442^0.01754386^0.018518519                          
-- all     height  183.700   5.903 160.000 170.000 175.000 175.000 183.000 190.000 193.000 198.000 211.000 69127   113        21    12677857.000000000000  null^160^163^165^168                                                     
-- all     weight   84.435   8.763  57.000  68.000  73.000  75.000  84.000  95.000 100.000 109.000 145.000 69127   176        64     5821854.000000000000  null^57^59^60^61                                                         

-- group   field   average  stdev     min     p01     p05     p10    p50     p90     p95     p99      max  count   nulls   cardnty    sum                  some
-- all     BAV       0.265   0.036   0.122   0.181   0.207   0.220   0.265   0.309   0.323   0.353   0.424 27750   0       10841        7352.282635679735  0.12244897959183673^0.12435233160621761^0.125^0.12598425196850394^0.12878787878787878
-- all     G       114.147  31.707  32.000  46.000  58.000  68.000 118.000 153.000 156.000 161.000 165.000 27750   0       134       3167587.000000000000  32^33^34^35^36                                                                       
-- all     H       103.566  47.301  16.000  28.000  36.000  42.000 101.000 168.000 182.000 206.000 262.000 27750   0       234       2873945.000000000000  16^17^18^19^20                                                                       
-- all     HR        8.829   9.236   0.000   0.000   0.000   0.000   6.000  22.000  28.000  40.000  73.000 27750   0       66         245001.000000000000  0^1^2^3^4                                                                            
-- all     OBP       0.329   0.042   0.156   0.233   0.261   0.276   0.328   0.383   0.399   0.436   0.609 27750   0       13270        9119.456519946456  0.15591398^0.16666667^0.16849817^0.16872428^0.16935484                               
-- all     OPS       0.721   0.115   0.312   0.478   0.544   0.581   0.715   0.867   0.916   1.027   1.422 27750   0       27642       20014.538630217314  0.31198335^0.31925547^0.32882884^0.33018503^0.3321846                                
-- all     PA      430.130 168.812 150.000 154.000 172.000 196.000 434.000 656.000 682.000 719.000 778.000 27750   0       617      11936098.000000000000  150^151^152^153^154                                                                  
-- all     SLG       0.393   0.080   0.148   0.230   0.272   0.295   0.387   0.497   0.534   0.609   0.863 27750   0       15589       10895.082128539681  0.14795919^0.15151516^0.15418503^0.15492958^0.15544042                               
-- all     height  182.460   5.608 163.000 168.000 173.000 175.000 183.000 190.000 190.000 196.000 203.000 27750   28      17        5058166.000000000000  null^163^165^168^170                                                                 
-- all     weight   83.569   8.797  57.000  68.000  71.000  73.000  82.000  95.000 100.000 109.000 132.000 27750   35      54        2316119.000000000000  null^57^59^63^64                                                                     


IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Calculating a Histogram Within a Group
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Calculating a Relative Distribution Histogram
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();

-- ***************************************************************************
--
-- === Calculating the Distribution of Numeric Values with a Histogram

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Binning Data for a Histogram
--

G_vals = FOREACH bat_seasons GENERATE G;
G_hist = FOREACH (GROUP G_vals BY G) GENERATE 
  group AS G, COUNT_STAR(G_vals) AS n_seasons;

--
-- We can separate out the two eras using the summing trick: 
--
G_vals_2 = FOREACH bat_seasons GENERATE G,
  (year_id <  1961 AND year_id > 1900 ? 1 : 0) AS G_154,
  (year_id >= 1961                   ? 1 : 0) AS G_162
  ;
G_hist_154_vs_162 = FOREACH (GROUP G_vals_2 BY G) GENERATE 
  group AS G,
  COUNT_STAR(G_vals_2) AS n_seasons,
  SUM(G_vals_2.G_154)  AS n_seasons_154,
  SUM(G_vals_2.G_162)  AS n_seasons_162
  ;


-- STORE_TABLE(G_hist, 'G_hist');
-- STORE_TABLE(G_hist_154_vs_162, 'G_hist_154_vs_162');


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Interpreting a Histogram
--

-- Different underlying mechanics will give different distributions.


DEFINE hist(table, key) RETURNS dist {
  vals = FOREACH $table GENERATE $key;
  $dist = FOREACH (GROUP vals BY $key) GENERATE
    group AS val, COUNT_STAR(vals) AS ct;
}

-- we have to be careful here because *nothing* about a professional should be taken as typical of the overall population
-- you are drawing from the extreme tails of the extreme tails of the population,
-- and there are very few 

-- Distribution of Games Played

-- Distribution of Players' Weight

age_hist = hist(bat_seasons, 'age');

-- Surely they are born and die like the rest of us?

-- Distribution of Birth and Death day of year

vitals = FOREACH peeps GENERATE
  height_in,
  10*CEIL(weight_lb/10.0) AS weight_lb,
  birth_month,
  death_month;

birth_month_hist = hist(vitals, 'birth_month');
death_month_hist = hist(vitals, 'death_month');
height_hist = hist(vitals, 'height_in');
weight_hist = hist(vitals, 'weight_lb');

STORE_TABLE(birth_month_hist, 'birth_month_hist');
STORE_TABLE(death_month_hist, 'death_month_hist');
STORE_TABLE(height_hist, 'height_hist');
STORE_TABLE(weight_hist, 'weight_hist');

-- attr_vals = FOREACH vitals GENERATE
--   FLATTEN(Transpose(height, weight, birth_month, death_month)) AS (attr, val);
-- 
-- attr_vals_nn = FILTER attr_vals BY val IS NOT NULL;
-- 
-- -- peep_stats   = FOREACH (GROUP attr_vals_nn BY attr) GENERATE
-- --   group                    AS attr,
-- --   COUNT_STAR(attr_vals_nn) AS ct_all,
-- --   COUNT(attr_vals_nn.val)  AS ct;
-- 
-- peep_stats = FOREACH (GROUP attr_vals_nn ALL) GENERATE
--   BagToMap(CountVals(attr_vals_nn.attr)) AS cts:map[long];
-- 
-- peep_hist = FOREACH (GROUP attr_vals BY (attr, val)) {
--   ct = COUNT_STAR(attr_vals);
--   GENERATE
--     FLATTEN(group) AS (attr, val),
--     ct             AS ct
--     -- , (float)ct / ((float)peep_stats.ct) AS freq
--     ;
-- };
-- peep_hist = ORDER peep_hist BY attr, val;
-- 
-- -- STORE_TABLE(peep_hist, 'peep_hist');
-- DUMP peep_stats;
-- 
-- one = LOAD '$data_dir/stats/numbers/one.tsv' AS (num:int);
-- ht = FOREACH one GENERATE peep_stats.cts#'height';
-- DUMP ht;

-- A lot of big data explorations involve population extremes: manufacturing defects, security threats, high- or low-performers. In such cases you must not rely on easy assumptions such as distributions having a central tendency, outliers being rare, or that the impact of errors can be bounded.

-- nf_chars = FOREACH bat_seasons GENERATE
--   FLATTEN(STRSPLITBAG(name_first, '(?!^)')) AS char;
-- chars_hist = FOREACH (GROUP nf_chars BY char) {
--   GENERATE group AS char, COUNT_STAR(nf_chars.char) AS ct;
-- };
-- chars_hist = ORDER chars_hist BY ct;
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

-- ***************************************************************************
--
-- === Re-injecting Global Values
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Testing for Absence of a Value Within a Group
--

-- We can answer to the question "what players have ever played for the Red Sox"
-- by selecting seasons with team id `BOS`, then eliminating duplicates:

-- Players who were on the Red Sox at some time
onetime_sox_ids = FOREACH (FILTER bat_seasons BY (team_id == 'BOS')) GENERATE player_id;
onetime_sox     = DISTINCT onetime_sox_ids;

-- However, filtering for `team_id != 'BOS'` does *not* work to select players
-- who were _never_ on the Red Sox. (It finds players who played at least one
-- season for another team.) The elegant way to do this involves the 'summing
-- trick', a device that will reoccur several times in this chapter.

player_soxness   = FOREACH bat_seasons GENERATE
  player_id, (team_id == 'BOS' ? 1 : 0) AS is_soxy;

player_soxness_g = FILTER (GROUP player_soxness BY player_id)
  BY SUM(is_soxy) == 0;

never_sox = FOREACH player_soxness_g GENERATE group AS player_id;

-- The summing trick involves projecting a new field whose value is based on
-- whether it's in the desired set, then forming the group we want to
-- summarize. For the irrelevant records, we assign a value that is ignored by
-- the aggregate function (typically zero or NULL), and so even though we
-- operate on the group as a whole, only the relevant records contribute.
--
-- Another example will help you see what we mean -- next, we'll use one GROUP
-- operation to summarize multiple subsets of a table at the same time.
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

mod_seasons = load_mod_seasons(); -- modern (post-1900) seasons of any number of PA only

-- ***************************************************************************
--
-- === Summarizing Multiple Subsets Simultaneously
--

--
-- We can use the summing trick to find aggregates on conditional subsets. For
-- this example, we will classify players as being "young" (age 21 and below),
-- "prime" (22-29 inclusive) or "old" (30 and older), and then find the OPS (our
-- overall performance metric) for their full career and for the subsets of
-- seasons where they were young, in their prime, or old footnote:[these
-- breakpoints are based on where
-- www.fangraphs.com/blogs/how-do-star-hitters-age research by fangraphs.com
-- showed a performance drop-off by 10% from peak.]
--

-- Project the numerator and denominator of our offensive stats into the field
-- for that age bucket... for an age-25 season, there will be values for PA_all
-- and PA_prime; PA_young and PA_older will have the value 0.
age_seasons = FOREACH mod_seasons {
  young = (age <= 21               ? true : false);
  prime = (age >= 22 AND age <= 29 ? true : false);
  older = (age >= 30               ? true : false);
  OB = H + BB + HBP;
  TB = h1B + 2*h2B + 3*h3B + 4*HR;
  GENERATE
    player_id, year_id,
    PA AS PA_all, AB AS AB_all, OB AS OB_all, TB AS TB_all,
    (young ? 1 : 0) AS is_young,
      (young ? PA : 0) AS PA_young, (young ? AB : 0) AS AB_young,
      (young ? OB : 0) AS OB_young, (young ? TB : 0) AS TB_young,
    (prime ? 1 : 0) AS is_prime,
      (prime ? PA : 0) AS PA_prime, (prime ? AB : 0) AS AB_prime,
      (prime ? OB : 0) AS OB_prime, (prime ? TB : 0) AS TB_prime,
    (older ? 1 : 0) AS is_older,
      (older ? PA : 0) AS PA_older, (older ? AB : 0) AS AB_older,
      (older ? OB : 0) AS OB_older, (older ? TB : 0) AS TB_older
    ;
};

career_epochs = FOREACH (GROUP age_seasons BY player_id) {
  PA_all    = SUM(age_seasons.PA_all  );
  PA_young  = SUM(age_seasons.PA_young);
  PA_prime  = SUM(age_seasons.PA_prime);
  PA_older  = SUM(age_seasons.PA_older);
  -- OBP = (H + BB + HBP) / PA
  OBP_all   = 1.0f*SUM(age_seasons.OB_all)   / PA_all  ;
  OBP_young = 1.0f*SUM(age_seasons.OB_young) / PA_young;
  OBP_prime = 1.0f*SUM(age_seasons.OB_prime) / PA_prime;
  OBP_older = 1.0f*SUM(age_seasons.OB_older) / PA_older;
  -- SLG = TB / AB
  SLG_all   = 1.0f*SUM(age_seasons.TB_all)   / SUM(age_seasons.AB_all);
  SLG_prime = 1.0f*SUM(age_seasons.TB_prime) / SUM(age_seasons.AB_prime);
  SLG_older = 1.0f*SUM(age_seasons.TB_older) / SUM(age_seasons.AB_older);
  SLG_young = 1.0f*SUM(age_seasons.TB_young) / SUM(age_seasons.AB_young);
  --
  GENERATE
    group AS player_id,
    MIN(age_seasons.year_id)  AS beg_year,
    MAX(age_seasons.year_id)  AS end_year,
    --
    OBP_all   + SLG_all       AS OPS_all:float,
    (PA_young >= 700 ? OBP_young + SLG_young : Null) AS OPS_young:float,
    (PA_prime >= 700 ? OBP_prime + SLG_prime : Null) AS OPS_prime:float,
    (PA_older >= 700 ? OBP_older + SLG_older : Null) AS OPS_older:float,
    --
    PA_all                    AS PA_all,
    PA_young                  AS PA_young,
    PA_prime                  AS PA_prime,
    PA_older                  AS PA_older,
    --
    COUNT_STAR(age_seasons)   AS n_seasons,
    SUM(age_seasons.is_young) AS n_young,
    SUM(age_seasons.is_prime) AS n_prime,
    SUM(age_seasons.is_older) AS n_older
    ;
};

career_epochs = ORDER career_epochs BY OPS_all DESC, player_id;
STORE_TABLE(career_epochs, 'career_epochs');

-- You'll spot Ted Williams (willite01) as one of the top three young players,
-- top three prime players, and top three old players. He's pretty awesome.
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- Here follows an investigation of players' career statistics
--
-- Defining the characteristic what we mean by an exceptional career is a matter
-- of taste, not mathematics; and selecting how we estimate those
-- characteristics is a matter of taste balanced by mathematically-informed
-- practicality.
--
-- * Total production: a long career and high absolute totals for hits, home runs and so forth
-- * Sustained excellence: high normalized rates of production (on-base percentage and so forth)
-- * Peak excellence: multiple seasons of exceptional performance

-- ***************************************************************************
--
-- === Using Group/Decorate/Flatten to Bring Group Context to Individuals
--

-- Earlier, when we created relative histograms, we demonstrated putting records
-- in context with global values.
--
-- To put them in context with whole-group examples, use a pattern we call
-- 'group/decorate/flatten'. Use this when you want a table with the same shape
-- and cardinality as the original (that is, each record in the result comes
-- from a single record in the original), but which integrates aggregate
-- statistics from subgroups of the table.
--
-- Let's annotate each player's season by whether they were the league leader in
-- Home Runs (HR).

-- The group we need is all the player-seasons for a year, so that we can find
-- out what the maximum count of HR was for that year.
bats_by_year_g = GROUP bat_seasons BY year_id;

-- Decorate each individual record with the group summary, and flatten:
bats_with_max_hr = FOREACH bats_by_year_g GENERATE
  MAX(bat_seasons.HR) as max_HR,
  FLATTEN(bat_seasons);

-- Now apply the group context to the records:
bats_with_leaders = FOREACH bats_with_max_hr GENERATE
  player_id.., (HR == max_HR ? 1 : 0);

-- An experienced SQL user might think to do this with a join. That might or
-- might not make sense; we'll explore this alternative later in the chapter
-- under "Selecting Records Associated with Maximum Values".

STORE_TABLE(bats_with_leaders, 'bats_with_leaders');




-- normed_dec = FOREACH (GROUP bat_years BY (year_id, lg_id)) {
--   batq     = FILTER bat_years BY (PA >= 450);
--   avg_BB   = AVG(batq.BB);  sdv_BB  = SQRT(VAR(batq.BB));
--   avg_H    = AVG(batq.H);   sdv_H   = SQRT(VAR(batq.H));
--   avg_HR   = AVG(batq.HR);  sdv_HR  = SQRT(VAR(batq.HR));
--   avg_R    = AVG(batq.R);   sdv_R   = SQRT(VAR(batq.R));
--   avg_RBI  = AVG(batq.RBI); sdv_RBI = SQRT(VAR(batq.RBI));
--   avg_OBP  = AVG(batq.OBP); sdv_OBP = SQRT(VAR(batq.OBP));
--   avg_SLG  = AVG(batq.SLG); sdv_SLG = SQRT(VAR(batq.SLG));
--   --
--   GENERATE
--     -- all the original values, flattened back into player-seasons
--     FLATTEN(bat_years),
--     -- all the materials for normalizing the stats
--     avg_H   AS avg_H,   sdv_H   AS sdv_H,
--     avg_HR  AS avg_HR,  sdv_HR  AS sdv_HR,
--     avg_R   AS avg_R,   sdv_R   AS sdv_R,
--     avg_RBI AS avg_RBI, sdv_RBI AS sdv_RBI,
--     avg_OBP AS avg_OBP, sdv_OBP AS sdv_OBP,
--     avg_SLG AS avg_SLG, sdv_SLG AS sdv_SLG
--     ;
-- };
-- 
-- normed = FOREACH normed_dec GENERATE
--   player_id, year_id, team_id, lg_id,
--   G,    PA,   AB,   HBP,  SH,
--   BB,   H,    h1B,  h2B,  h3B,
--   HR,   R,    RBI,  OBP,  SLG,
--   (H   - avg_H  ) /sdv_H        AS zH,
--   (HR  - avg_HR ) /sdv_HR       AS zHR,
--   (R   - avg_R  ) /sdv_R        AS zR,
--   (RBI - avg_RBI) /sdv_RBI      AS zRBI,
--   (OBP - avg_OBP) /sdv_OBP      AS zOBP,
--   (SLG - avg_SLG) /sdv_SLG      AS zSLG,
--   ( ((OBP - avg_OBP)/sdv_OBP) +
--     ((SLG - avg_SLG)/sdv_SLG) ) AS zOPS
--   ;
-- 
-- normed_seasons = ORDER normed BY zOPS ASC;
-- STORE_TABLE(normed_seasons, 'normed_seasons');

-- ***************************************************************************
--
-- === Detecting Outliers
--

--
-- The "Summing trick" is a frequently useful way to identify subsets of a group
-- without having to perform multiple GROUP BY operatons. Think of it every time
-- you find yourself thinking "gosh, this sure seems like a lot of reduce steps"
--
--
-- Let's make a
--
-- footnote:[this is a miniature version of the Career Standards Test formulated
-- by Bill James, the Newton of baseball analytics -- see
-- www.baseball-reference.com/about/leader_glossary.shtml#hof_standard]
--
-- In this case, we're interested in the outliers precisely because they are outliers.
--
-- but in other situations you might use this trick to identify values that are
-- spurious or deserve closer inspection.
--
-- Your first instinct might be to use a nested FILTER or FOREACH on each
-- group's bag, but that is unweildy at best. Instead, make a new field that
-- has a value only when the record should be selected:
--
-- First, project a column with an innocuous value like zero or null when not in
-- the chosen set, and the value to retrieve when in the set. Here, we project
-- the value 1 for outlier seasons -- more than one standard deviation over the
-- league average.
--
tops = FOREACH normed GENERATE
  player_id, year_id,
  G,    PA,   AB,   HBP,  SH,
  BB,   H,    h1B,  h2B,  h3B,
  HR,   R,    RBI,  OBP,  SLG,
  zH,   zHR,  zR,   zRBI, zOBP,  zSLG, zOPS,
  ((zH   >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_H,
  ((zHR  >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_HR,
  ((zR   >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_R,
  ((zRBI >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_RBI,
  ((zOBP >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_OBP,
  ((zSLG >= 1.0 AND PA >= 450) ? 1 : 0) AS hi_SLG
  ;

--
-- Now we can roll up a player's career and count the number of outlier seasons
-- simultaneously.
--
career_peaks = FOREACH (GROUP tops BY player_id) {
  topq   = FILTER tops BY PA >= 450;
  G   = SUM(tops.G);   PA  = SUM(tops.PA);  AB  = SUM(tops.AB);
  HBP = SUM(tops.HBP); BB  = SUM(tops.BB);  H   = SUM(tops.H);
  h1B = SUM(tops.h1B); h2B = SUM(tops.h2B); h3B = SUM(tops.h3B);
  HR  = SUM(tops.HR);  R   = SUM(tops.R);   RBI = SUM(tops.RBI);
  OBP    = 1.0*(H + BB + HBP) / (PA-SUM(tops.SH));
  SLG    = 1.0*(h1B + 2*h2B + 3*h3B + 4*HR) / AB;
  avzH   = ROUND_TO(AVG(topq.zH),3);   avzHR  = ROUND_TO(AVG(topq.zHR),3);
  avzR   = ROUND_TO(AVG(topq.zR),3);   avzRBI = ROUND_TO(AVG(topq.zRBI),3);
  avzOBP = ROUND_TO(AVG(topq.zOBP),3); avzSLG = ROUND_TO(AVG(topq.zSLG),3);
  avzOPS = ROUND_TO(AVG(topq.zOPS),3);
  GENERATE
    group AS player_id,
    MIN(tops.year_id)   AS beg_year, MAX(tops.year_id) AS end_year,
    --
    -- Total career contribution:
    --   Cumulative statistics
    G   AS G,   PA  AS PA,  BB  AS BB,
    H   AS H,   HR  AS HR,  R   AS R,  RBI AS RBI,
    ROUND_TO(OBP,3) AS OBP, ROUND_TO(SLG,3) AS SLG, ROUND_TO(OBP+SLG,3) AS OPS, 
    --
    -- Peak excellence, normalized to era:
    --   Average of seasonal z-scores (qual. only)
    -- avzH   AS avzH,   avzHR  AS avzHR,
    avzR   AS avzR,   avzRBI AS avzRBI,
    avzOBP AS avzOBP, avzSLG AS avzSLG, avzOPS AS avzOPS,
    --
    -- Sustained excellence, normalized to era:
    --   total seasons and qualified (at least 450 plate appearances) seasons
    COUNT_STAR(tops)  AS n_seasons, COUNT_STAR(topq)  AS n_qualsns,
    --   number of qualified seasons with > 1-sigma performance
    SUM(tops.hi_H)    AS n_hiH,     SUM(tops.hi_HR)   AS n_hiHR,
    SUM(tops.hi_R)    AS n_hiR,     SUM(tops.hi_RBI)  AS n_hiRBI,
    SUM(tops.hi_OBP)  AS n_hiOBP,   SUM(tops.hi_SLG)  AS n_hiSLG
    ;
  };

--
-- We've prepared a set of metrics we think will be useful in identifying
-- players with historically great careers, but we don't yet have any
--
-- That is, we know Tony Gwynn's ten seasons of 1-sigma-plus OBP
-- and Jim Rice's ten seasons of 1-sigma-plus SLG are both impressive, 
--
-- (these are defensible choices, though guided in part by narrative goals)
--
-- Players with truly exceptional careers
-- footnote:[Voting is based on a player's "record, playing ability, integrity, sportsmanship, character, and contributions to [their] team(s)". Induction requires 75% or more of votes in a yearly ballot of baseball writers, or selection by special committee. Players must have played 10 or more seasons, and become eligible five years after retirement or if deceased; eligibility ends 20 years after retirement or by receiving less than 5% of votes -- baseballhall.org/hall-famers/rules-election/BBWAA]
-- are selected for the Hall of Fame.
--
-- The 'bat_hof' table lists every player eligible for the hall of fame
--

-- ballplayers or hospitals or keyword advertisements
-- 

-- Earlier we stated that the
--
-- Whenever possible,
--
-- Any rational evaluation will place Babe Ruth, Ted Williams and Willie Mays among the very
-- best of players.

-- If we chose to judge players' careers by number of high-OBP or high-SLG
-- seasons, total career home runs, and career OPS on-base-plus-slugging, then
-- Ellis Burks  (2 high-OPS, 8 high-SLG; 0.874 career OPS) would seem to be the superior of
-- Andre Dawson (0 high-OPS, 8 high-SLG; 0.806 career OPS), both superior to
-- Robin Yount  (4 high-OPS, 4 high-SLG, 0.772 career OPS).

-- In fact, however, Yount is acknowledged as one of the hundred best players
-- ever; Dawson as being right above the edge of what defines a great career; and
-- Burks as being very good but well short of great. Any metric as simplistic as this 

-- Ellis Burks, Carl Yastrzemski ("Yaz" from here on) and Andre Dawson each had
-- 8 1-sigma-SLG seasons, a career OPS over 0.800, and more than 350 home runs. 

-- The details of performing logistic regression analysis are out of scope for
-- this book, but you can look in the sample code.

--
-- We'd like to

-- *
-- *

-- * multiple seasons of excellent performance
-- *

hof = load_hofs();

hof = FOREACH hof GENERATE player_id, hof_score, (is_pending == 1 ? 'pending' : Coalesce(inducted_by, '.'));
hof_worthy = FOREACH (JOIN career_peaks BY player_id, hof BY player_id)
  GENERATE *,
   (n_hiH + n_hiHR + n_hiR + n_hiRBI + 1.5*n_hiOBP + 1.5*n_hiSLG) AS is_awesome;
hof_worthy = ORDER hof_worthy BY is_awesome, avzOPS, hof_score;
STORE_TABLE('hof_worthy', hof_worthy);
-- cat $out_dir/hof_worthy
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Enumerating a Many-to-Many Relationship
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Joining Records in a Table with Corresponding Records in Another Table (Inner Join)
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Joining Records in a Table with Directly Matching Records from Another Table (Direct Inner Join)
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Disambiguating Field Names With `::`
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
numbers_10k = load_numbers_10k();

-- ***************************************************************************
--
-- === Joining on an Integer Table to Fill Holes in a List 

-- In some cases you want to ensure that there is an output row for each
-- potential value of a key. For example, a histogram of career hits will show
-- that Pete Rose (4256 hits) and Ty Cobb (4189 hits) have so many more hits
-- than the third-most player (Hank Aaron, 3771 hits) there are gaps in the
-- output bins.
-- 
-- To fill the gaps, generate a list of all the potential keys, then generate
-- your (possibly hole-y) result table, and do a join of the keys list (LEFT
-- OUTER) with results. In some cases, this requires one job to enumerate the
-- keys and a separate job to calculate the results. For our purposes here, we
-- can simply use the integer table. (We told you it was surprisingly useful!)


-- 
-- Regular old histogram of career hits, bin size 100
--
H_vals = FOREACH (GROUP bat_seasons BY player_id) GENERATE
  100*ROUND(SUM(bat_seasons.H)/100.0) AS bin;
H_hist_0 = FOREACH (GROUP H_vals BY bin) GENERATE 
  group AS bin, COUNT(H_vals) AS ct;

--
-- Generate a list of all the bins we want to keep.
--
H_bins = FOREACH (FILTER numbers_10k BY from_0 <= 43) GENERATE 100*from_0  AS bin;

--
-- Perform a LEFT JOIN of bins with histogram counts Missing rows will have a
-- null `ct` value, which we can convert to zero.
--
H_hist = FOREACH (JOIN H_bins BY bin LEFT OUTER, H_hist_0 BY bin) GENERATE
  H_bins::bin,
  ct,                    -- leaves missing values as null
  (ct IS NULL ? 0 : ct)  -- converts missing values to zero
;

STORE_TABLE(H_hist, 'histogram_H');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
one_line    = load_one_line();

-- ***************************************************************************
--
-- === Joining a Table with Itself (self-join)
--

-- We have to generate two table copies -- Pig doesn't like a pure self-join
p1 = FOREACH bat_seasons GENERATE player_id, team_id, year_id, name_first, name_last;
p2 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;

teammate_pairs = FOREACH (JOIN p1 BY (team_id, year_id), p2 by (team_id, year_id)) GENERATE
  p1::player_id AS pl1,        p2::player_id AS pl2,
  p1::team_id   AS p1_team_id, p1::year_id   AS p1_year_id;
teammate_pairs = FILTER teammate_pairs BY NOT (pl1 == pl2);

teammates = FOREACH (GROUP teammate_pairs BY pl1) {
  years = DISTINCT teammate_pairs.p1_year_id;
  mates = DISTINCT teammate_pairs.pl2;
  teams = DISTINCT teammate_pairs.p1_team_id;
  GENERATE group AS player_id, 
    COUNT_STAR(mates) AS n_mates,    COUNT_STAR(years) AS n_seasons,
    MIN(years)        AS beg_year,   MAX(years)        AS end_year, 
    BagToString(teams,';') AS teams,
    BagToString(mates,';') AS mates;
  };

teammates = ORDER teammates BY n_mates DESC;

-- STORE_TABLE(teammates, 'teammates');


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- SQL Equivalent:
--
-- SELECT DISTINCT b1.player_id, b2.player_id
--   FROM bat_season b1, bat_season b2
--   WHERE b1.team_id = b2.team_id          -- same team
--     AND b1.year_id = b2.year_id          -- same season
--     AND b1.player_id != b2.player_id     -- reject self-teammates
--   GROUP BY b1.player_id
--   ;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Summary of results
--

teammates = LOAD_RESULT('teammates');

tm_pair_stats  = FOREACH (GROUP teammate_pairs ALL) GENERATE
  COUNT_STAR(teammate_pairs) AS n_pairs;
teammate_stats = FOREACH (GROUP teammates      ALL) GENERATE
  COUNT_STAR(teammates)      AS n_players,
  SUM(teammates.n_mates)     AS n_teammates;

summary = FOREACH one_line GENERATE
  'n_pairs',     (long)tm_pair_stats.n_pairs AS n_pairs,
  'n_players',   (long)teammate_stats.n_players AS n_players,
  'n_teammates', (long)teammate_stats.n_teammates AS n_teammates
  ;

STORE_TABLE(summary, 'summary');
cat $out_dir/summary;

IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

-- === Selecting Records With No Match in Another Table (anti-join)
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_tm_yr();

-- ***************************************************************************
--
-- === Joining Records Without Discarding Non-Matches (Outer Join)
--

-- Here's how to take the career stats table we assembled earlier and decorate it with the years



-- One application of an outer join is
--
-- Experienced database hands might now suggest doing a join using a SOUNDEX
-- match or some sort of other fuzzy equality. In map-reduce, the only kind of
-- join you can do is on key equality (an "equi-join"). For a sharper example,
-- you cannot do joins on range criteria (where the two keys are related through
-- inequalities (x < y). You can accomplish the _goals_ of a 
-- Matching Records Between Tables (Inner Join)
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
allstars    = load_allstars();

-- ***************************************************************************
--
-- === Selecting Records With No Match in Another Table (anti-join)
--

-- Project just the fields we need
allstars_py  = FOREACH allstars GENERATE player_id, year_id;

-- An outer join of the two will leave both matches and non-matches.
bats_allstars_jn = JOIN
  bat_seasons BY (player_id, year_id) LEFT OUTER,
  allstars_py BY (player_id, year_id);

-- ...and the non-matches will have Nulls in all the allstars slots
bat_seasons_nonast_jn_f = FILTER bats_allstars_jn BY allstars_py::player_id IS NULL;

-- Once the matches have been eliminated, pick off the first table's fields.
-- The double-colon in 'bat_seasons::' makes clear which table's field we mean.
-- The fieldname-ellipsis 'bat_seasons::player_id..bat_seasons::RBI' selects all
-- the fields in bat_seasons from player_id to RBI, which is to say all of them.
bat_seasons_nonast_jn   = FOREACH bat_seasons_nonast_jn_f
  GENERATE bat_seasons::player_id..bat_seasons::RBI;

--
-- This is a good use of the fieldname-ellipsis syntax: to the reader it says
-- "all fields of bat_seasons, the exact members of which are of no concern".
-- (It would be even better if we could write `bat_seasons::*`, but that's not
-- supported in Pig <= 0.12.0.)
--
-- In a context where we did go on to care about the actual fields, that syntax
-- becomes an unstated assumption about not just what fields exist at this
-- stage, but what _order_ they occur in. We can try to justify why you wouldn't
-- use it with a sad story: Suppose you wrote `bat_seasons::PA..bat_seasons::HR`
-- to mean the counting stats (PA, AB, HBP, SH, BB, H, h1B, h2B, h3b, HR). In
-- that case, an upstream rearrangement of the schema could cause fields to be
-- added or removed in a way that would be hard to identify. Now, that failure
-- scenario almost certainly won't happen, and if it did it probably wouldn't
-- lead to real problems, and if there were they most likely wouldn't be that
-- hard to track down. The true point is that it's lazy and unhelpful to the
-- reader. If you mean "PA, AB, HBP, SH, BB, H, h1B, h2B, h3b, HR", then that's
-- what you should say.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- An Alternative version: use a COGROUP
--

-- Players with no entry in the allstars_py table have an empty allstars_py bag
bats_ast_cg = COGROUP
  bat_seasons BY (player_id, year_id),
  allstars_py BY (player_id, year_id);

-- Select all cogrouped rows where there were no all-star records, and project
-- the batting table fields.
bat_seasons_nonast_cg = FOREACH
  (FILTER bats_ast_cg BY IsEmpty(allstars_py))
  GENERATE FLATTEN(bat_seasons);

-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(bat_seasons_nonast_jn, 'bat_seasons_nonast_jn');
STORE_TABLE(bat_seasons_nonast_cg, 'bat_seasons_nonast_cg');


-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- There are three opportunities for optimization here. Though these tables are
-- far to small to warrant optimization, it's a good teachable moment for when
-- to (not) optimize.
--
-- * You'll notice that we projected off the extraneous fields from the allstars
--   table before the map. Pig is sometimes smart enough to eliminate fields we
--   don't need early. There's two ways to see if it did so. The surest way is
--   to consult the tree that EXPLAIN produces. If you make the program use
--   `allstars` and not `allstars_py`, you'll see that the extra fields are
--   present. The other way is to look at how much data comes to the reducer
--   with and without the projection. If there is less data using `allstars_py`
--   than `allstars`, the explicit projection is required.
--
-- * The EXPLAIN output also shows that co-group version has a simpler
--   map-reduce plan, raising the question of whether it's more performant.
--
-- * Usually we put the smaller table (allstars) on the right in a join or
--   cogroup. However, although the allstars table is smaller, it has larger
--   cardinality (barely): `(player_id, team_id)` is a primary key for the
--   bat_seasons table. So the order is likely to be irrelevant.
--
EXPLAIN  non_allstars_jn;
EXPLAIN  non_allstars_cg;
--
-- But more performant or possibly more performant doesn't mean "use it
-- instead".
--
-- Eliminating extra fields is almost always worth it, but the explicit
-- projection means extra lines of code and it means an extra alias for the
-- reader to understand. On the other hand, the explicit projection reassures
-- the experienced reader that the projection is for-sure-no-doubt-about-it
-- taking place. That's actually why we chose to be explicit here: we find that
-- the more-complicated script gives the reader less to think about.
--
-- In contrast, any SQL user will immediately recognize the join formulation of
-- this as an anti-join. Introducing a RIGHT OUTER join or choosing the cogroup
-- version disrupts that familiarity. Choose the version you find most readable,
-- and then find out if you care whether it's more performant; the simpler
-- explain graph or the smaller left-hand join table _do not_ necessarily imply
-- a faster dataflow. For this particular shape of data, even at much larger
-- scale we'd be surprised to learn that either of the latter two optimizations
-- mattered.
--
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons    = load_bat_seasons();
allstars = load_allstars();

-- ***************************************************************************
--
-- === Selecting Records Having a Match in Another Table (semi-join)
--

--
-- !!! Don't use a join for this !!!
--
-- From 1959-1962 there were _two_ all-star games, and so the allstar table has multiple entries;
-- this means that players will appear twice in the results
--

-- Project just the fields we need
allstars_py   = FOREACH allstars GENERATE player_id, year_id;

-- An outer join of the two will leave both matches and non-matches
seasons_allstars_jn = JOIN
  bat_seasons BY (player_id, year_id) LEFT OUTER,
  allstars_py BY (player_id, year_id);

-- And we can filter-then-project just as for the anti-join case
bat_seasons_ast_jn  = FOREACH
  (FILTER seasons_allstars_jn BY allstars_py::player_id IS NOT NULL)
  GENERATE bat_seasons::player_id..bat_seasons::RBI;

-- but also
-- produce multiple rows where there was more than one all-star game in a year

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Instead, in this case you must use a COGROUP
--

-- Players with no entry in the allstars_py table have an empty allstars_py bag
bats_ast_cg = COGROUP
  bat_seasons BY (player_id, year_id),
  allstars_py BY (player_id, year_id);

-- Select all cogrouped rows where there was an all-star record
-- Project the batting table fields.
--
-- One row in the batting table => One row in the result
bat_seasons_ast_cg = FOREACH
  (FILTER bats_ast_cg BY NOT IsEmpty(allstars_py)))
  GENERATE FLATTEN(bat_seasons);


-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(bat_seasons_ast_jn, 'bat_seasons_ast_jn');
STORE_TABLE(bat_seasons_ast_cg, 'bat_seasons_ast_cg');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
SET default_parallel 3;

bats = load_bat_seasons();
bats = FILTER bats BY (year_id >= 2000);


-- ***************************************************************************
--
-- === Sorting All Records in Total Order

-- Run the script 'i-summarizing_multiple_subsets_simultaneously.pig' beforehand
-- to get career stats broken up into young (age 21 and below), prime (22 to 29
-- inclusive), and older (30 and over).
--
career_epochs = LOAD_RESULT('career_epochs');

-- We're only going to look at players able to make solid contributions over
-- several years, which we'll define as playing for five or more seasons and
-- 2000 or more plate appearances (enough to show statistical significance), and
-- a OPS of 0.650 (an acceptable-but-not-allstar level) or better.
career_epochs = FILTER career_epochs BY
  ((PA_all >= 2000) AND (n_seasons >= 5) AND (OPS_all >= 0.650));

career_young = ORDER career_epochs BY OPS_young DESC;
career_prime = ORDER career_epochs BY OPS_prime DESC;
career_older = ORDER career_epochs BY OPS_older DESC;

-- STORE_TABLE(career_young, 'career_young');
-- STORE_TABLE(career_prime, 'career_prime');
-- STORE_TABLE(career_older, 'career_older');

-- You'll spot Ted Williams (willite01) as one of the top three young players,
-- top three prime players, and top three old players. He's pretty awesome.
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Sorting by Multiple Fields
--

-- Sorting on Multiple fields is as easy as adding them in order with commas.
-- Sort by number of older seasons, breaking ties by number of prime seasons:

career_young = ORDER career_epochs BY n_young DESC, n_prime DESC;

-- Whereever reasonable, always "stabilize" your sorts: add a unique id column
-- (or any other you're sure won't have ties), ensuring the output will remain
-- the same from run to run.

career_young = ORDER career_epochs BY n_young DESC, n_prime DESC,
  player_id ASC; -- makes sure that ties are always broken the same way.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Cannot Use an Expression in an ORDER BY statement
--

-- You cannot use an expression to sort the table. This won't work:
--
-- by_diff_older = ORDER career_epochs BY (OPS_older-OPS_prime) DESC; -- fails!


-- Instead, use a foreach to prepare the field and then sort on it:
by_diff_older = ORDER (
  FOREACH career_epochs GENERATE *, OPS_older - OPS_prime AS diff_older
  ) BY diff_older DESC;
STORE_TABLE(by_diff_older, 'by_diff_older');

-- Current-era players seem to be very over-represented at the top of the
-- career_older table. Part of that is due to better training, nutrition, and
-- medical care. Part of that is probably also to to abuse of
-- performance-enhancing drugs.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Dealing with Nulls When Sorting
--

-- When the sort field has nulls you can of course filter them out, and
-- sometimes it's acceptable to substitute in a harmless value using a ternary
-- expression: `(val IS NULL ? 0 : val)`. But you typically want to retain the
-- Null field. By default, Pig will sort Nulls as least-most: the first rows for
-- `BY .. DESC` and the last rows for `BY .. ASC`. You can float Nulls to the
-- front or back by projecting a dummy field exhibiting whatever favoritism
-- you want to impose, and list it first in the sort order.

nulls_sort_demo = FOREACH career_epochs GENERATE
  *, (OPS_older IS NULL ? 0 : 1) AS has_older_epoch;


nulls_then_vals = ORDER nulls_sort_demo BY
  has_older_epoch ASC, OPS_all DESC;

vals_then_nulls = ORDER nulls_sort_demo BY
  has_older_epoch DESC, OPS_all DESC;




-- Floating Values to the Head or Tail of the Sort Order
--
-- Use a dummy field, same as with the preceding discussion on Nulls. This
-- floats to the top all players whose careers start in 1985 or later, and
-- otherwise sorts on number of older seasons:

post1985_vs_earlier = ORDER (
  FOREACH career_epochs GENERATE *, (beg_year >= 1985 ? 1 : 0) AS is_1985
  ) BY is_1985 DESC, n_older DESC;

STORE_TABLE(post1985_vs_earlier, 'post1985_vs_earlier');


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Case-insensitive Sorting
--



-- sunset = FOREACH career_epochs GENERATE
--   player_id, beg_year, end_year, OPS_all,
--   (PA_young >= 700 ? OPS_young : Null),
--   (PA_prime >= 700 ? OPS_prime : Null),
--   (PA_older >= 700 ? OPS_older : Null),
--   (PA_young >= 700 AND PA_prime >= 700 ? OPS_young - OPS_prime : Null) AS diff_young,
--   (PA_prime >= 700 AND PA_prime >= 700 ? OPS_prime - OPS_all   : Null) AS diff_prime,
--   (PA_older >= 700 AND PA_prime >= 700 ? OPS_older - OPS_prime : Null) AS diff_older,
--   PA_all, PA_young, PA_prime, PA_older
-- 
--   , ((end_year + beg_year)/2.0 > 1990 ? 'post' : '-') AS epoch
--   ;
-- 
-- golden_oldies = ORDER sunset BY diff_older DESC;


-- If you sort to find older player Those more familiar with the game will also note an overrepresentation of
--
-- http://cms.colgate.edu/portaldata/imagegallerywww/21c0d002-4098-4995-941f-9ae8013632ee/ImageGallery/2012/the-impact-of-age-on-baseball-players-performance.pdf


-- Look at the jobtracker
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

-- Make sure to run 06-structural_operations/b-
bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Sorting Records within a Group


-- Use ORDER BY within a nested FOREACH to sort within a group. The first
-- request to sort a group does not require extra operations -- Pig simply
-- specifies those fields as secondary sort keys. This will list, for each
-- team's season, the players in decreasing order by 


IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

vals = LOAD 'us_city_pops.tsv' USING PigStorage('\t', '-tagMetadata')
  AS (metadata:map[], city:chararray, state:chararray, pop:int);

-- === Shuffle all Records in a Table
-- ==== Shuffle all Records in a Table Consistently

-- Use a hash with good mixing properties to shuffle. MD5 is OK but murmur3 from
-- DATAFU-47 would be even better.
DEFINE HashVal datafu.pig.hash.Hasher('murmur3-32');

vals_rked     = RANK vals;

DESCRIBE vals_rked;

vals_ided = FOREACH vals_rked GENERATE
  rank_vals,
  metadata,
  metadata#'pathname'  AS pathname:chararray,
  metadata#'sp_index'  AS sp_index:int,
  metadata#'sp_offset' AS sp_offset:long,
  metadata#'sp_bytes'  AS sp_bytes:long,
  city, state, pop;

vals_ided = FOREACH vals_ided GENERATE
  HashVal(pathname) AS pathhash, metadata,
  sp_index, sp_offset, sp_bytes, city, state, pop;

STORE_TABLE('vals_ided',  vals_ided);
-- USING MultiStorage

-- vals_wtag = FOREACH vals_rked {
--   line_info   = CONCAT((chararray)split_info, '#', (chararray)rank_vals);
--   GENERATE HashVal((chararray)line_info) AS rand_id, city, state, pop, FLATTEN(split_attrs) AS (sp_path, sp_idx, sp_offs, sp_size); 
--   };
-- vals_shuffled = FOREACH (ORDER vals_wtag BY rand_id) GENERATE *;
-- STORE vals_shuffled INTO '/data/out/vals_shuffled';


DEFINE Hasher datafu.pig.hash.MD5('hex');
-- DEFINE Hasher org.apache.pig.piggybank.evaluation.string.HashFNV();

-- evs = LOAD '/data/rawd/sports/baseball/events_lite-smallblks.tsv' USING PigStorage('\t', '-tagSplit') AS (
--     split_info:chararray, game_id:chararray, event_seq:int, year_id:int, game_date:chararray, game_seq:int, away_team_id:chararray, home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int, away_score:int, home_score:int, event_desc:chararray, event_cd:int, hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int, run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int, bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray, bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
--     );
-- evs_numd = RANK evs;
-- evs_ided = FOREACH evs_numd {
--   line_info = CONCAT((chararray)split_info, '#', (chararray)rank_evs);
--   GENERATE MurmurH32(line_info) AS rand_id, *; -- game_id..run3_id;
--   };
-- DESCRIBE evs_ided;
-- evs_shuffled = FOREACH (ORDER evs_ided BY rand_id) GENERATE $1..;
-- STORE_TABLE('evs_shuffled', evs_shuffled);

-- -- -smallblks
-- vals = LOAD '/data/rawd/sports/baseball/events_lite.tsv' USING PigStorage('\t', '-tagSplit') AS (
--     split_info:chararray, game_id:chararray, event_seq:int, year_id:int, game_date:chararray, game_seq:int, away_team_id:chararray, home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int, away_score:int, home_score:int, event_desc:chararray, event_cd:int, hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int, run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int, bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray, bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
--     );
-- vals = FOREACH vals GENERATE MurmurH32((chararray)split_info) AS split_info:chararray, $1..;

vals = LOAD '$rawd/geo/census/us_city_pops.tsv' USING PigStorage('\t', '-tagSplit')
  AS (split_info:chararray, city:chararray, state:chararray, pop:int);

vals_rk = RANK vals;
vals_ided = FOREACH vals_rk {
  line_info = CONCAT((chararray)split_info, '#', (chararray)rank_vals);
  GENERATE Hasher((chararray)line_info) AS rand_id, *; -- $2..;
  };
DESCRIBE vals_ided;
DUMP     vals_ided;

vals_shuffled = FOREACH (ORDER vals_ided BY rand_id) GENERATE *; -- $1..;
DESCRIBE vals_shuffled;

STORE_TABLE('vals_shuffled', vals_shuffled);


-- vals_shuffled = LOAD '/data/rawd/sports/baseball/events_lite.tsv' AS (
--     sh_key:chararray, line_id:int, spl_key:chararray, game_id:chararray, event_seq:int, year_id:int, game_date:chararray, game_seq:int, away_team_id:chararray, home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int, away_score:int, home_score:int, event_desc:chararray, event_cd:int, hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int, run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int, bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray, bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
--     );
-- vals_foo = ORDER vals_shuffled BY sh_key;
-- STORE_TABLE('vals_foo', vals_shuffled);

-- numbered = RANK cities;
-- DESCRIBE numbered;
-- ided = FOREACH numbered {
--   line_info = CONCAT((chararray)split_info, '#', (chararray)rank_cities);
--   GENERATE
--     *;
--   };
-- DESCRIBE ided;
-- STORE_TABLE('cities_with_ids', ided);
-- 
-- sampled_lines = FILTER(FOREACH ided GENERATE MD5(id_md5) AS digest, id_md5) BY (STARTSWITH(digest, 'b'));
-- STORE_TABLE('sampled_lines', sampled_lines);
-- 
-- data_in = LOAD 'input' as (val:chararray);
-- 
-- data_out = FOREACH data_in GENERATE
--   DefaultH(val),   GoodH(val),       BetterH(val),
--   MurmurH32(val),  MurmurH32A(val),  MurmurH32B(val),
--   MurmurH128(val), MurmurH128A(val), MurmurH128B(val),
--   SHA1H(val),      SHA256H(val),    SHA512H(val),
--   MD5H(val)
-- ;
-- 
-- STORE_TABLE('data_out', data_out);
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
SET DEFAULT_PARALLEL 3;

SET pig.noSplitCombination    true
SET pig.splitCombination      false
SET opt.multiquery            false;

bat_seasons = load_bat_seasons();
parks       = load_parks();

-- ***************************************************************************
--
-- === Numbering Records in Rank Order


-- ***************************************************************************
--
-- ==== Handling Ties when Ranking Records
--

parks_o = ORDER parks BY state_id PARALLEL 3;

parks_nosort_inplace    = RANK parks;
parks_presorted_inplace = RANK parks_o;
parks_presorted_ranked  = RANK parks_o BY state_id DESC;
parks_ties_cause_skips  = RANK parks   BY state_id DESC;
parks_ties_no_skips     = RANK parks   BY state_id DESC DENSE;

STORE_TABLE(parks_nosort_inplace,    'parks_nosort_inplace');
STORE_TABLE(parks_presorted_inplace, 'parks_presorted_inplace');
STORE_TABLE(parks_presorted_ranked,  'parks_presorted_ranked');
STORE_TABLE(parks_ties_cause_skips,  'parks_ties_cause_skips');
STORE_TABLE(parks_ties_no_skips,     'parks_ties_no_skips');

-- partridge            1    1    1 
-- turtle dove          2    2    2
-- turtle dove          3    2    2
-- french hen           4    3    4
-- french hen           5    3    4
-- french hen           6    3    4
-- calling birds        7    4    7
-- calling birds        8    4    7
-- calling birds        9    4    7
-- calling birds       10    4    7
-- K golden rings      11    5   11
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- ==== Selecting Rows from the Middle of a Result Set
--


IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
bat_seasons = load_bat_seasons();

-- === Selecting Records Associated with Maximum Values

--   -- For each season by a player, select the team they played the most games for.
--   -- In SQL, this is fairly clumsy (involving a self-join and then elimination of
--   -- ties) In Pig, we can ORDER BY within a foreach and then pluck the first
--   -- element of the bag.
-- 
-- SELECT bat.player_id, bat.year_id, bat.team_id, MAX(batmax.Gmax), MAX(batmax.stints), MAX(team_ids), MAX(Gs)
--   FROM       batting bat
--   INNER JOIN (SELECT player_id, year_id, COUNT(*) AS stints, MAX(G) AS Gmax, GROUP_CONCAT(team_id) AS team_ids, GROUP_CONCAT(G) AS Gs FROM batting bat GROUP BY player_id, year_id) batmax
--   ON bat.player_id = batmax.player_id AND bat.year_id = batmax.year_id AND bat.G = batmax.Gmax
--   GROUP BY player_id, year_id
--   -- WHERE stints > 1
--   ;
-- 
--   -- About 7% of seasons have more than one stint; only about 2% of seasons have
--   -- more than one stint and more than a half-season's worth of games
-- SELECT COUNT(*), SUM(mt1stint), SUM(mt1stint)/COUNT(*) FROM (SELECT player_id, year_id, IF(COUNT(*) > 1 AND SUM(G) > 77, 1, 0) AS mt1stint FROM batting GROUP BY player_id, year_id) bat


--
-- Earlier in the chapter we annotated each player's season by whether they were
-- the league leader in Home Runs (HR):

bats_with_max_hr = FOREACH (GROUP bat_seasons BY year_id) GENERATE
  MAX(bat_seasons.HR) as max_HR,
  FLATTEN(bat_seasons);

-- Find the desired result:
bats_with_l_cg = FOREACH bats_with_max_hr GENERATE
  player_id.., (HR == max_HR ? 1 : 0);
bats_with_l_cg = ORDER bats_with_l_cg BY player_id, year_id;

  
-- We can also do this using a join:

-- Find the max_HR for each season
HR_by_year     = FOREACH bat_seasons GENERATE year_id, HR;
max_HR_by_year = FOREACH (GROUP HR_by_year BY year_id) GENERATE
  group AS year_id, MAX(HR_by_year.HR) AS max_HR;

-- Join it with the original table to put records in full-season context:
bats_with_max_hr_jn = JOIN
  bat_seasons    BY year_id, -- large table comes *first* in a replicated join
  max_HR_by_year BY year_id  USING 'replicated';
-- Find the desired result:
bats_with_l_jn = FOREACH bats_with_max_hr_jn GENERATE
  player_id..RBI, (HR == max_HR ? 1 : 0);

-- The COGROUP version has only one reduce step, but it requires sending the
-- full contents of the table to the reducer: its cost is two full-table scans
-- and one full-table group+sort. The JOIN version first requires effectively
-- that same group step, but with only the group key and the field of interest
-- sent to the reducer. It then requires a JOIN step to bring the records into
-- context, and a final pass to use it. If we can use a replicated join, the
-- cost is a full-table scan and a fractional group+sort for preparing the list,
-- plus two full-table scans for the replicated join. If we can't use a
-- replicated join, the cogroup version is undoubtedly superior.
--
-- So if a replicated join is possible, and the projected table is much smaller
-- than the original, go with the join version. However, if you are going to
-- decorate with multiple aggregations, or if the projected table is large, use
-- the GROUP/DECORATE/FLATTEN pattern.

STORE_TABLE(bats_with_l_cg, 'bats_with_l_cg');
STORE_TABLE(bats_with_l_jn, 'bats_with_l_jn');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Selecting Records Having the Top K Values in a Group (discarding ties)
-- 

-- Let's find the top ten home-run hitters for each season
--

%DEFAULT k_leaders 10
;

HR_seasons = FOREACH bat_seasons GENERATE
  player_id, name_first, name_last, year_id, HR;

HR_leaders = FOREACH (GROUP HR_seasons BY year_id) GENERATE
  group AS year_id,
  TOP($k_leaders, 3, HR_seasons.(player_id, name_first, name_last, HR)) AS top_k;

-- HR_leaders = FOREACH HR_leaders {
--   top_k_o = ORDER top_k BY HR DESC;
--   GENERATE 
-- 
--   top_k  = 
--   GENERATE top_k_o;
--   };
-- 
--   top_k_o = ORDER top_k BY HR DESC;

--
-- STORE_TABLE(HR_leaders, 'HR_leaders');



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Selecting Attribute wdw 
-- -- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/ExtremalTupleByNthField.html
-- DEFINE BiggestInBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');
-- 
-- pl_best = FOREACH (GROUP bat_seasons BY player_id) GENERATE
--   group AS player_id,
--   BiggestInBag(bat_seasons.(H,   year_id, team_id)),
--   BiggestInBag(bat_seasons.(HR,  year_id, team_id)),
--   BiggestInBag(bat_seasons.(OBP, year_id, team_id)),
--   BiggestInBag(bat_seasons.(SLG, year_id, team_id)),
--   BiggestInBag(bat_seasons.(OPS, year_id, team_id))
--   ;
-- 
-- DESCRIBE pl_best;
-- 
-- rmf                 $out_dir/pl_best;
-- STORE pl_best INTO '$out_dir/pl_best';
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Selecting Records Having the Top K Values in a Table
--


-- -- Find the top 20 seasons by OPS.  Pig is smart about eliminating records at
-- -- the map stage, dramatically decreasing the data size.
-- 
-- player_seasons = LOAD `player_seasons` AS (...);
-- qual_player_seasons = FILTER player_years BY plapp > what it should be;
-- player_season_stats = FOREACH qual_player_seasons GENERATE
--    player_id, name, games,
--    hits/ab AS batting_avg,
--    whatever AS slugging_avg,
--    whatever AS offensive_pct
--    ;
-- player_season_stats_ordered = ORDER player_season_stats BY (slugging_avg + offensive_pct) DESC;
-- STORE player_season_stats INTO '/tmp/baseball/player_season_stats';
-- 
-- -- A simple ORDER BY..LIMIT stanza may not be what you need, however. It will
-- -- always return K records exactly, even if there are ties for K'th place.








-- -- Making a leaderboard of records with say the top ten values for a field is
-- -- not as simple as saying `ORDER BY..LIMIT`, as there could be many records
-- -- tied for the final place on the list.
-- --
-- -- If you'd like to retain records tied with or above the Nth largest value, use
-- -- the windowed query functionality from Over.
-- -- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/Over.html
-- --
-- -- We limit within each group to the top `topk_window` (20) items, assuming
-- -- there are not 16 players tied for fourth in HR. We don't assume for too long
-- -- -- an `ASSERT` statement verifies there aren't so many records tied for 4th
-- -- place that it overflows the 20 highest records we retained for consideration.
-- --
-- %DEFAULT topk_window 20
-- %DEFAULT topk        4
-- DEFINE IOver                  org.apache.pig.piggybank.evaluation.Over('int');
-- ranked_HRs = FOREACH (GROUP bats BY year_id) {
--   bats_HR = ORDER bats BY HR DESC;
--   bats_N  = LIMIT bats_HR $topk_window; -- making a bet, asserted below
--   ranked  = Stitch(bats_N, IOver(bats_N, 'rank', -1, -1, 15)); -- beginning to end, rank on the 16th field (HR)
--   GENERATE
--     group   AS year_id,
--     ranked  AS ranked:{(player_id, year_id, team_id, lg_id, age, G, PA, AB, HBP, SH, BB, H, h1B, h2B, h3B, HR, R, RBI, OBP, SLG, rank_HR)}
--     ;
-- };
-- -- verify there aren't so many records tied for $topk'th place that it overflows
-- -- the $topk_window number of highest records we retained for consideration
-- ASSERT ranked_HRs BY MAX(ranked.rank_HR) > $topk; --  'LIMIT was too strong; more than $topk_window players were tied for $topk th place';
-- 
-- top_season_HRs = FOREACH ranked_HRs {
--   ranked_HRs = FILTER ranked BY rank_HR <= $topk;
--   GENERATE ranked_HRs;
--   };
-- 
-- STORE_TABLE('top_season_HRs', top_season_HRs);
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

park_teams = load_park_teams();
parks      = load_parks();
teams       = load_teams();

-- ***************************************************************************
--
-- === Eliminating Duplicate Records from a Table
--

-- Every distinct (team, home ballpark) pair:

tm_pk_pairs_many = FOREACH park_teams GENERATE team_id, park_id;

tm_pk_pairs_dist = DISTINCT tm_pk_pairs_many;

-- -- ALT     ALT01
-- -- ANA     ANA01
-- -- ARI     PHO01
-- -- ATL     ATL01
-- -- ATL     ATL02

--
-- Equivalent SQL: `SELECT DISTINCT player_id, team_id from batting;`
--
-- This gives the same result as, but is less efficient than
--
tm_pk_pairs_dont = FOREACH (GROUP park_teams BY (team_id, park_id)) 
  GENERATE group.team_id, group.park_id;
-- -- ALT     ALT01
-- -- ANA     ANA01
-- -- ARI     PHO01
-- -- ATL     ATL01
-- -- ATL     ATL02

--
-- the DISTINCT operation is able to use a combiner - to eliminate duplicates at
-- the mapper before shipping them to the reducer. This is a big win when there
-- are frequent duplicates, especially if duplicates are likely to occur near
-- each other. For example, duplicates in web logs (from refreshes, callbacks,
-- etc) will be sparse globally, but found often in the same log file. In the
-- case of very few or very sparse duplicates, the combiner may impose a minor
-- penalty. You should still use DISTINCT, but set `pig.exec.nocombiner=true`.

STORE_TABLE(tm_pk_pairs_dist, 'tm_pk_pairs_dist');
STORE_TABLE(tm_pk_pairs_dont, 'tm_pk_pairs_dont');

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- === Eliminating Duplicate Records from a Group
--

-- Eliminating duplicates from a group just requires using a nested
-- foreach. Instead of finding every distinct (team, home ballpark) pair as we
-- just did, let's find the list of distinct home ballparks for each team:

team_parkslist = FOREACH (GROUP park_teams BY team_id) {
  parks = DISTINCT park_teams.park_id;
  GENERATE group AS team_id, BagToString(parks, '|');
};

EXPLAIN team_parkslist;

STORE_TABLE(team_parkslist, 'team_parkslist');

-- -- CL1     CHI02|CIN01|CLE01                                          
-- -- CL2     CLE02                                                      
-- -- CL3     CLE03|CLE09|GEA01|NEW03                                    
-- -- CL4     CHI08|CLE03|CLE05|CLL01|DET01|IND06|PHI09|ROC02|ROC03|STL05

-- Same deal, but slap the stadium names on there first:
--
-- tm_pk_named_a = FOREACH (JOIN park_teams    BY team_id, teams BY team_id) GENERATE teams::team_id AS team_id, park_teams::park_id AS park_id, teams::team_name AS team_name;
-- tm_pk_named   = FOREACH (JOIN tm_pk_named_a BY park_id, parks BY park_id) GENERATE team_id,                tm_pk_named_a::park_id AS park_id, team_name,  park_name;
-- team_parkslist = FOREACH (GROUP tm_pk_named BY team_id) {
--   parks = DISTINCT tm_pk_named.(park_id, park_name);
--   GENERATE group AS team_id, FLATTEN(FirstTupleFromBag(tm_pk_named.team_name, (''))), BagToString(parks, '|');
-- };
-- DUMP team_parkslist;
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Selecting Records with Unique (or with Duplicate) Values for a Key
--

-- yclept /iˈklept/: by the name of; called.
uniquely_yclept_f = GROUP peeps BY name_first;

uniquely_yclept_g = FILTER uniquely_yclept_g BY SIZE(peeps) == 1;

uniquely_yclept   = FOREACH uniquely_yclept_f {
  GENERATE group AS name_first,
    FLATTEN(peeps.name_last), FLATTEN(peeps.player_id),
    FLATTEN(peeps.beg_date),  FLATTEN(peeps.end_date);
};

uniquely_yclept = ORDER uniquely_yclept BY name_first ASC;

STORE_TABLE(uniquely_yclept, 'uniquely_yclept');

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- SQL Equivalent:
--
-- SELECT name_first, name_last, COUNT(*) AS n_usages
--   FROM bat_career
--   WHERE    name_first IS NOT NULL
--   GROUP BY name_first
--   HAVING   n_usages = 1
--   ORDER BY name_first
--   ;


-- ===========================================================================
--
-- Some of our favorites:
--
-- -- Alamazoo        Jennings        jennial01       1878-08-15      1878-08-15
-- -- Ambiorix        Burgos          burgoam01       2005-04-23      2007-05-26
-- -- Arquimedez      Pozo            pozoar01        1995-09-12      1997-09-28
-- -- Asdrubal        Cabrera         cabreas01       2007-08-08
-- -- Astyanax        Douglass        douglas01       1921-07-30      1925-05-29
-- -- Atahualpa       Severino        severat01       2011-09-06
-- -- Baby Doll       Jacobson        jacobba01       1915-04-14      1927-09-22
-- -- Baldy           Louden          loudeba01       1907-09-13      1916-09-18
-- -- Beauty          McGowan         mcgowbe01       1922-04-12      1937-05-13
-- -- Bevo            LeBourveau      leboube01       1919-09-09      1929-10-05
-- -- Bid             McPhee          mcphebi01       1882-05-02      1899-10-15
-- -- Bing            Miller          millebi02       1921-04-16      1936-09-05
-- -- Binky           Jones           jonesbi03       1924-04-15      1924-04-27
-- -- Bip             Roberts         roberbi01       1986-04-07      1998-09-27
-- -- Bitsy           Mott            mottbi01        1945-04-17      1945-09-30
-- -- Blix            Donnelly        donnebl01       1944-05-06      1951-05-03
-- -- Blondie         Purcell         purcebl01       1879-05-01      1890-09-16
-- -- Blondy          Ryan            ryanbl01        1930-07-13      1938-07-31
-- -- Blue Moon       Odom            odombl01        1964-09-05      1976-08-17
-- -- Boardwalk       Brown           brownbo01       1911-09-27      1915-10-07
-- -- Boileryard      Clarke          clarkbo02       1893-05-01      1905-10-07
-- -- Bombo           Rivera          riverbo01       1975-04-17      1982-10-03
-- -- Boob            Fowler          fowlebo01       1923-05-06      1926-05-05
-- -- Boof            Bonser          bonsebo01       2006-05-21
-- -- Boog            Powell          powelbo01       1961-09-26      1977-08-24
-- -- Boom-Boom       Beck            beckbo01        1924-09-22      1945-09-26
-- -- Brick           Smith           smithbr02       1987-09-13      1988-04-23
-- -- Brickyard       Kennedy         kennebr01       1892-04-26      1903-09-26
-- -- Bris            Lord            lordbr01        1905-04-21      1913-10-03
-- -- Broadway        Jones           jonesbr01       1923-07-04      1923-07-13
-- -- Bubbles         Hargrave        hargrbu01       1913-09-18      1930-09-06
-- -- Buckshot        May             maybu01         1924-05-09      1924-05-09
-- -- Bug             Holliday        hollibu01       1889-04-17      1898-06-30
-- -- Bumpus          Jones           jonesbu01       1892-10-15      1893-07-14
-- -- Bunk            Congalton       congabu01       1902-04-17      1907-10-05
-- -- Bunky           Stewart         stewabu02       1952-05-04      1956-09-15
-- -- Buttercup       Dickerson       dickebu01       1878-07-15      1885-06-01
-- -- Callix          Crabbe          crabbca01       2008-04-03      2008-05-08
-- -- Choo Choo       Coleman         colemch01       1961-04-16      1966-04-23
-- -- Coot            Veal            vealco01        1958-07-30      1963-06-20
-- -- Crash           Davis           daviscr01       1940-06-15      1942-09-20
-- -- Crazy           Schmit          schmicr01       1890-04-21      1901-06-08
-- -- Creepy          Crespi          crespcr01       1938-09-14      1942-09-27
-- -- Cuckoo          Christensen     chriscu01       1926-04-13      1927-08-04
-- -- Cuddles         Marshall        marshcu01       1946-04-24      1950-09-30
-- -- Cuke            Barrows         barrocu01       1909-09-18      1912-09-10
-- -- Cupid           Childs          childcu01       1888-04-23      1901-09-26
-- -- Dazzy           Vance           vanceda01       1915-04-16      1935-08-14
-- -- Diomedes        Olivo           olivodi01       1960-09-05      1963-06-12
-- -- Dots            Miller          milledo02       1909-04-16      1921-09-27
-- -- Double Joe      Dwyer           dwyerdo01       1937-04-20      1937-05-17
-- -- Drungo          Hazewood        hazewdr01       1980-09-19      1980-10-04
-- -- Dude            Esterbrook      esterdu01       1880-05-01      1891-07-22
-- -- Duster          Mails           mailsdu01       1915-09-28      1926-04-29
-- -- Early           Wynn            wynnea01        1939-09-13      1963-09-13
-- -- El              Tappe           tappeel01       1954-04-24      1962-07-17
-- -- Epp             Sell            sellep01        1922-09-01      1923-05-29
-- -- Eppa            Rixey           rixeyep01       1912-06-21      1933-08-05
-- -- Fabio           Castro          castrfa01       2006-04-06      2007-09-17
-- -- Fats            Dantonio        dantofa01       1944-09-18      1945-09-20
-- -- Fatty           Briody          briodfa01       1880-06-16      1888-07-24
-- -- Finners         Quinlan         quinlfi01       1913-09-06      1915-07-15
-- -- Firpo           Marberry        marbefi01       1923-08-11      1936-06-10
-- -- Flame           Delhi           delhifl01       1912-04-16      1912-04-16
-- -- Flea            Clifton         cliftfl01       1934-04-29      1937-07-01
-- -- Fleet           Walker          walkefl01       1884-05-01      1884-09-04
-- -- Fletcher        Low             lowfl01         1915-10-07      1915-10-07
-- -- Fleury          Sullivan        sullifl01       1884-05-03      1884-10-15
-- -- Flint           Rhem            rhemfl01        1924-09-06      1936-08-26
-- -- Flip            Lafferty        laffefl01       1876-09-15
-- -- Foghorn         Bradley         bradlfo01       1876-08-23      1876-10-21
-- -- Footer          Johnson         johnsfo01       1958-06-22      1958-07-30
-- -- Footsie         Blair           blairfo01       1929-04-28      1931-09-27
-- -- Frosty          Thomas          thomafr01       1905-05-01      1905-05-06
-- -- Fu-Te           Ni              nifu01          2009-06-29
-- -- Fuzz            White           whitefu01       1940-09-17      1947-05-06
-- -- Gaylord         Perry           perryga01       1962-04-14      1983-09-21
-- -- Gomer           Hodge           hodgego01       1971-04-06      1971-09-26
-- -- Goody           Rosen           rosengo01       1937-09-14      1946-09-26
-- -- Goose           Goslin          gosligo01       1921-09-16      1938-09-25
-- -- Granny          Hamner          hamnegr01       1944-09-14      1962-08-01
-- -- Greasy          Neale           nealegr01       1916-04-12      1924-06-13
-- -- Greek           George          georggr01       1935-06-30      1945-09-03
-- -- Hansel          Izquierdo       izquiha02       2002-04-21      2002-06-24
-- -- Hanson          Horsey          horseha01       1912-04-27      1912-04-27
-- -- Hippo           Vaughn          vaughhi01       1908-06-19      1921-07-09
-- -- Hoot            Evers           eversho01       1941-09-16      1956-09-30
-- -- Hoyt            Wilhelm         wilheho01       1952-04-19      1972-07-10
-- -- Icehouse        Wilson          wilsoic01       1934-05-31      1934-05-31
-- -- Icicle          Reeder          reedeic01       1884-06-24      1884-08-05
-- -- Jewel           Ens             ensje01         1922-04-29      1925-06-15
-- -- Jigger          Statz           statzji01       1919-07-30      1928-09-30
-- -- Jot             Goar            goarjo01        1896-04-18      1898-05-01
-- -- Jung            Bong            bongju01        2002-04-23      2004-06-20
-- -- Kaiser          Wilhelm         wilheka01       1903-04-18      1921-08-26
-- -- Kermit          Wahl            wahlke01        1944-06-23      1951-07-29
-- -- Kewpie          Pennington      pennike01       1917-04-14      1917-04-14
-- -- Lady            Baldwin         baldwla01       1884-09-30      1890-06-26
-- -- Leech           Maskrey         maskrle01       1882-05-02      1886-07-07
-- -- Leonidas        Lee             leele01         1877-07-17
-- -- Lu              Blue            bluelu01        1921-04-14      1933-04-25
-- -- Lucky           Wright          wrighlu01       1909-04-18      1909-05-18
-- -- Merkin          Valdez          valdeme01       2004-08-01
-- -- Mert            Hackett         hackeme01       1883-05-02      1887-10-06
-- -- Mookie          Wilson          wilsomo01       1980-09-02      1991-10-06
-- -- Moonlight       Graham          grahamo01       1905-06-29      1905-06-29
-- -- Mother          Watson          watsomo01       1887-05-19      1887-05-27
-- -- Mox             McQuery         mcquemo01       1884-08-20      1891-07-25
-- -- Mudcat          Grant           grantmu01       1958-04-17      1971-09-29
-- -- Muddy           Ruel            ruelmu01        1915-05-29      1934-08-25
-- -- Mul             Holland         hollamu01       1926-05-25      1929-07-13
-- -- Mysterious      Walker          walkemy01       1910-06-28      1915-09-29
-- -- Nanny           Fernandez       fernana01       1942-04-14      1950-07-09
-- -- Nomar           Garciaparra     garcino01       1996-08-31
-- -- Noodles         Hahn            hahnno01        1899-04-18      1906-06-07
-- -- Nook            Logan           loganno01       2004-07-21      2007-09-30
-- -- Nub             Kleinke         kleinnu01       1935-04-25      1937-10-03
-- -- Oil Can         Boyd            boydoi01        1982-09-13      1991-10-01
-- -- Onan            Masaoka         masaoon01       1999-04-05      2000-09-30
-- -- Onix            Concepcion      conceon01       1980-08-30      1987-04-07
-- -- Oral            Hildebrand      hildeor01       1931-09-08      1940-07-28
-- -- Orator          Shaffer         shaffor01       1874-05-23      1890-09-13
-- -- Osiris          Matos           matosos01       2008-07-03
-- -- Pea Ridge       Day             daype01         1924-09-19      1931-09-21
-- -- Peanuts         Lowrey          lowrepe01       1942-04-14      1955-08-30
-- -- Phenomenal      Smith           smithph01       1884-04-18      1891-06-15
-- -- Pi              Schwert         schwepi01       1914-10-06      1915-10-07
-- -- Pickles         Dillhoefer      dillhpi01       1917-04-16      1921-10-01
-- -- Pie             Traynor         traynpi01       1920-09-15      1937-08-14
-- -- Piggy           Ward            wardpi01        1883-06-12      1894-09-30
-- -- Pinch           Thomas          thomapi01       1912-04-24      1921-06-19
-- -- Ping            Bodie           bodiepi01       1911-04-22      1921-07-24
-- -- Pink            Hawley          hawlepi01       1892-08-13      1901-08-20
-- -- Pip             Koehler         koehlpi01       1925-04-22      1925-09-12
-- -- Pit             Gilman          gilmapi01       1884-09-18      1884-09-20
-- -- Pokey           Reese           reesepo01       1997-04-01      2004-10-03
-- -- Pop-Boy         Smith           smithpo02       1913-04-19      1917-05-02
-- -- Preacher        Roe             roepr01         1938-08-22      1954-09-04
-- -- Prentice        Redman          redmapr01       2003-08-24      2003-09-28
-- -- Press           Cruthers        cruthpr01       1913-09-29      1914-10-03
-- -- Pud             Galvin          galvipu01       1875-05-22      1892-08-02
-- -- Pumpsie         Green           greenpu01       1959-07-21      1963-09-26
-- -- Punch           Knoll           knollpu01       1905-04-27      1905-10-04
-- -- Purnal          Goldy           goldypu01       1962-06-12      1963-09-28
-- -- Pussy           Tebeau          tebeapu01       1895-07-22      1895-07-24
-- -- Putsy           Caballero       cabalpu01       1944-09-14      1952-09-27
-- -- Queenie         O'Rourke        orourqu01       1908-08-15      1908-10-08
-- -- Quilvio         Veras           verasqu01       1995-04-25      2001-07-13
-- -- Quinton         McCracken       mccraqu01       1995-09-17      2006-07-05
-- -- Redleg          Snyder          snydere01       1876-04-25      1884-09-12
-- -- Ribs            Raney           raneyri01       1949-09-18      1950-04-22
-- -- Ripper          Collins         colliri02       1931-04-18      1941-09-28
-- -- Rit             Harrison        harriri01       1875-05-20      1875-05-20
-- -- Roosevelt       Brown           brownro01       1999-05-18      2002-09-29
-- -- Rugger          Ardizoia        ardizru01       1947-04-30      1947-04-30
-- -- Runelvys        Hernandez       hernaru03       2002-07-15      2008-07-21
-- -- Sailor          Stroud          strousa01       1910-04-29      1916-06-13
-- -- Sap             Randall         randasa01       1988-08-02      1988-08-06
-- -- Sarge           Connally        connasa01       1921-09-10      1934-07-18
-- -- Satchel         Paige           paigesa01       1948-07-09      1965-09-25
-- -- Satoru          Komiyama        komiysa01       2002-04-04      2002-09-11
-- -- Scarborough     Green           greensc01       1997-08-02      2000-10-01
-- -- Scat            Metha           methasc01       1940-04-22      1940-08-10
-- -- Schoolboy       Rowe            rowesc01        1933-04-15      1949-09-13
-- -- Scipio          Spinks          spinksc01       1969-09-16      1973-06-09
-- -- Scoops          Carey           careysc01       1895-04-26      1903-07-06
-- -- Seem            Studley         studlse01       1872-04-20      1872-05-08
-- -- Shadow          Pyle            pylesh01        1884-10-15      1887-05-13
-- -- Shags           Horan           horansh01       1924-07-14      1924-09-18
-- -- She             Donahue         donahsh01       1904-04-29      1904-10-03
-- -- Shea            Hillenbrand     hillesh02       2001-04-02      2007-09-20
-- -- Sheriff         Blake           blakesh01       1920-06-29      1937-09-26
-- -- Sixto           Lezcano         lezcasi01       1974-09-10      1985-09-29
-- -- Skel            Roach           roachsk01       1899-08-09      1899-08-09
-- -- Ski             Melillo         melilsk01       1926-04-18      1937-09-18
-- -- Skippy          Roberge         robersk02       1941-07-18      1946-06-15
-- -- Skyrocket       Smith           smithsk01       1888-04-18      1888-07-02
-- -- Slats           Jordan          jordasl01       1901-09-28      1902-09-27
-- -- Sled            Allen           allensl01       1910-05-04      1910-08-05
-- -- Sleeper         Sullivan        sullisl01       1881-05-03      1884-05-29
-- -- Slicker         Parks           parkssl01       1921-07-11      1921-09-04
-- -- Sloppy          Thurston        thurssl01       1923-04-19      1933-10-01
-- -- Slow Joe        Doyle           doylesl01       1906-08-25      1910-06-25
-- -- Snooks          Dowd            dowdsn01        1919-04-27      1926-04-17
-- -- Snuffy          Stirnweiss      stirnsn01       1943-04-22      1952-05-03
-- -- So              Taguchi         tagucso01       2002-06-10
-- -- Soup            Campbell        campbso01       1940-04-21      1941-09-28
-- -- Sport           McAllister      mcallsp01       1896-08-07      1903-09-29
-- -- Squanto         Wilson          wilsosq01       1911-10-02      1914-04-22
-- -- Squire          Potter          pottesq01       1923-08-07      1923-08-07
-- -- Squiz           Pillion         pillisq01       1915-08-20      1915-08-26
-- -- Steamer         Flanagan        flanast01       1905-09-25      1905-10-07
-- -- Stud            Bancker         banckst01       1875-04-19      1875-06-05
-- -- Suds            Sutherland      suthesu01       1921-04-14      1921-06-22
-- -- Sugar           Cain            cainsu01        1932-04-15      1938-05-28
-- -- Swat            McCabe          mccabsw01       1909-09-23      1910-05-20
-- -- Sweetbreads     Bailey          bailesw01       1919-05-23      1921-06-11
-- -- Sy              Sutcliffe       sutclsy01       1884-10-02      1892-10-06
-- -- Tack            Wilson          wilsota01       1983-04-09      1987-10-03
-- -- Tacks           Latimer         latimta01       1898-10-01      1902-09-08
-- -- The Only        Nolan           nolanth01       1878-05-01      1885-10-09
-- -- Tip             O'Neill         oneilti01       1883-05-05      1892-08-30
-- -- Tippy           Martinez        martiti01       1974-08-09      1988-04-18
-- -- Toad            Ramsey          ramseto01       1885-09-05      1890-09-17
-- -- Topsy           Hartsel         hartsto01       1898-09-14      1911-09-30
-- -- Tot             Pressnell       pressto01       1938-04-21      1942-08-30
-- -- Trench          Davis           davistr01       1985-06-04      1987-07-03
-- -- Trick           McSorley        mcsortr01       1875-05-06      1886-05-06
-- -- Tricky          Nichols         nichotr01       1875-04-19      1882-07-11
-- -- Tris            Speaker         speaktr01       1907-09-14      1928-08-30
-- -- Trot            Nixon           nixontr01       1996-09-21      2008-06-28
-- -- Tubby           Spencer         spenctu01       1905-07-23      1918-09-01
-- -- Tuffy           Stewart         stewatu01       1913-08-08      1914-04-25
-- -- Tully           Sparks          sparktu01       1897-09-15      1910-06-08
-- -- Tun             Berger          bergetu01       1890-05-09      1892-08-28
-- -- Twink           Twining         twinitw01       1916-07-09      1916-07-09
-- -- Ugueth          Urbina          urbinug01       1995-05-09      2005-10-02
-- -- Urban           Shocker         shockur01       1916-04-24      1928-05-30
-- -- Urbane          Pickering       pickeur01       1931-04-18      1932-09-25
-- -- Vada            Pinson          pinsova01       1958-04-15      1975-09-28
-- -- Vida            Blue            bluevi01        1969-07-20      1986-10-02
-- -- Vinegar Bend    Mizell          mizelvi01       1952-04-22      1962-07-25
-- -- War             Sanders         sandewa01       1903-04-18      1904-07-04
-- -- Welcome         Gaston          gastowe01       1898-10-06      1899-09-25
-- -- Whammy          Douglas         douglwh01       1957-07-29      1957-09-17
-- -- Wheezer         Dell            dellwh01        1912-04-22      1917-07-04
-- -- Whit            Wyatt           wyattwh01       1929-09-16      1945-07-18
-- -- Wib             Smith           smithwi01       1909-05-31      1909-09-29
-- -- Wish            Egan            eganwi01        1902-09-03      1906-07-23
-- -- Yogi            Berra           berrayo01       1946-09-22      1965-05-09
-- -- Yorvit          Torrealba       torreyo01       2001-09-05
-- -- Yu              Darvish         darviyu01       2012-04-09
-- -- Zaza            Harvey          harveza01       1900-05-03      1902-05-04
-- -- Ziggy           Hasbrook        hasbrzi01       1916-09-06      1917-09-27
-- -- Zinn            Beck            beckzi01        1913-09-14      1918-07-22
-- -- Zoilo           Versalles       versazo01       1959-08-01      1971-09-28
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
parks       = load_parks();
big_cities  = load_us_city_pops();

bat_seasons = FILTER bat_seasons BY PA      >= 450;
parks       = FILTER parks       BY n_games >=  50;

-- === Set Operations

bball_cities = FOREACH parks GENERATE park_id, city;

combined     = COGROUP big_cities BY city, bball_cities BY city;
-- output (note: in execution Pig will project out the rest of the fields besides city)
-- -- (Tucson,{(Tucson,Arizona,525796)},{})
-- -- (Anaheim,{(Anaheim,California,341361)},{(ANA01,Anaheim)})
-- -- (Atlanta,{(Atlanta,Georgia,432427)},{(ATL01,Atlanta),(ATL02,Atlanta)})
-- -- (Buffalo,{},{(BUF02,Buffalo),(BUF01,Buffalo),(BUF04,Buffalo),(BUF03,Buffalo)})

-- ==== Distinct Union
big_or_bball    = FOREACH combined
  GENERATE group AS city;

-- ==== Set Intersection
big_and_bball   = FOREACH (FILTER combined BY
  (NOT IsEmpty(big_cities)) AND (NOT IsEmpty(bball_cities)))
  GENERATE group AS city;

-- ==== Set Difference
big_minus_bball = FOREACH (FILTER combined BY
  (IsEmpty(bball_cities)))
  GENERATE group AS city;

-- ==== Set Equality
bball_minus_big = FOREACH (FILTER combined BY
  (IsEmpty(big_cities)))
  GENERATE group AS city;

-- ==== Symmetric Set Difference
big_xor_bball   = FOREACH (FILTER combined BY
  (IsEmpty(big_cities)) OR (IsEmpty(bball_cities)))
  GENERATE group AS city;

STORE_TABLE(big_or_bball,    'big_or_bball');
STORE_TABLE(big_and_bball,   'big_and_bball');
STORE_TABLE(big_minus_bball, 'big_minus_bball');
STORE_TABLE(bball_minus_big, 'bball_minus_big');
STORE_TABLE(big_xor_bball,   'big_xor_bball');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();


-- ***************************************************************************
--
-- === Set Operations
--
-- * Distinct Union; 
-- * Set Intersection
-- * Set Difference
-- * Set Equality
-- * Symmetric Set Difference

y1      = FOREACH bat_seasons GENERATE player_id, team_id, year_id, G, PA;
y2      = FOREACH bat_seasons GENERATE player_id, team_id, year_id, G, PA;
rosters = FOREACH (COGROUP y1 BY (team_id, year_id), y2 BY (team_id, year_id-1)) GENERATE
  group.team_id AS team_id, group.year_id AS year_id,
  y1.player_id AS pl1, y2.player_id AS pl2
  ;

rosters = FILTER rosters BY NOT (IsEmpty(pl1) OR IsEmpty(pl2));
roster_changes_y2y = FOREACH rosters {

  -- Distinct Union: the players in each two-year span (given year or the next). SetUnion accepts two or more bags:
  either_year   = SetUnion(pl1, pl2);

  -- the other set operations require sorted inputs. Keep in mind that an ORDER BY within the nested block of a FOREACH (GROUP BY) is efficient, as it makes use of the secondary sort Hadoop provides.
  opl1 = ORDER pl1 BY player_id;
  opl2 = ORDER pl2 BY player_id;

  -- Intersect: for each team-year, the players that stayed for the next year (given year and the next). Requires sorted input. With
  both_years    = SetIntersect(opl1, opl2);

  -- Difference: for each team-year, the players that did not stay for next year (A minus B). Requires sorted input. With multiple bags of input, the result is everything that is in the first but not in any other set.
  y1_left  = SetDifference(opl1, opl2);
  y2_came  = SetDifference(opl2, opl1);

  -- Symmetric Difference: for each team-year, the players that did not stay for next year (A minus B) plus (B minus A)
  non_both       = SetUnion(SetDifference(opl1,opl2), SetDifference(opl2,opl1));
  -- TODO is there nothing better?

  -- Set Equality: for each team-year, were the players the same?
  -- is_unchanged =
  -- if a has no dupes then the elements of a == elements of b if and only if (size(a intersect b) == size(a) == size(b));
  -- if a has no dupes then the elements of a == elements of b if and only if (size(a minus b) = 0 AND (size(a) == size(b)))

  GENERATE
    year_id, team_id,
    SIZE(pl1)                     AS n_pl1,
    SIZE(pl2)                     AS n_pl2,
    SIZE(either_year)             AS n_union,
    SIZE(both_years)              AS n_intersect,
    SIZE(y1_left)                 AS n_left,
    SIZE(y2_came)                 AS n_came,
    SIZE(non_both)                AS n_xor,
    -- either_year,
    -- both_years,
    y1_left,
    y2_came,
    -- non_both,
    (SIZE(non_both) == 0 ? 1 : 0) AS is_equal
    ;
};

roster_changes_y2y = ORDER roster_changes_y2y BY n_xor DESC, n_left DESC, n_came DESC, year_id ASC;
DUMP roster_changes_y2y;

-- === Co-Grouping Records Across Tables by Common Key
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

games = load_games();

-- ***************************************************************************
--
-- === Computing a Won-Loss Record
--

--
-- Using a COGROUP:
--

home_games = FOREACH games GENERATE
  home_team_id AS team_id, year_id,
  (home_runs_ct > away_runs_ct ? 1 : 0) AS win,
  (home_runs_ct < away_runs_ct ? 1 : 0) AS loss
  ;
-- (BAL,2004,1,0)
-- (BAL,2004,0,1)

away_games = FOREACH games GENERATE
  away_team_id AS team_id, year_id,
  (home_runs_ct > away_runs_ct ? 0 : 1) AS win,
  (home_runs_ct < away_runs_ct ? 0 : 1) AS loss
  ;
-- (BOS,2004,0,1)
-- (BOS,2004,1,0)

--
-- === Don't do this:
--
-- all_games = UNION home_games, away_games;
-- team_games = GROUP all_games BY team_id;
--

-- 
-- === Instead, use a COGROUP.
--

team_games = COGROUP
  home_games BY (team_id, year_id),
  away_games BY (team_id, year_id);

-- ((BOS,2004),  {(BOS,2004,1,0),(BOS,2004,1,0),...}, {(BOS,2004,0,1),(BOS,2004,1,0),...})

team_yr_win_loss_v1 = FOREACH team_games {
  wins   = SUM(home_games.win)    + SUM(away_games.win);
  losses = SUM(home_games.loss)   + SUM(away_games.loss);
  G      = COUNT_STAR(home_games) + COUNT_STAR(away_games);
  G_home = COUNT_STAR(home_games);
  ties   = G - (wins + losses);
  GENERATE group.team_id, group.year_id, G, G_home, wins, losses, ties;
  };
--- (BOS,2004,162,81,98,64,0)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Generate both halves with a FLATTEN
--

--
-- Use the summable trick:
--

game_wls = FOREACH games {
  home_win   = (home_runs_ct > away_runs_ct ? 1 : 0);
  home_loss  = (home_runs_ct < away_runs_ct ? 1 : 0);
  summables  = {
    (home_team_id, home_win,  home_loss, 1),
    (away_team_id, home_loss, home_win,  0)   };
  
  GENERATE
    year_id, FLATTEN(summables) AS (team_id:chararray, win:int, loss:int, is_home:int);
};
-- (2004,BAL,1,0,1)
-- (2004,BOS,0,1,0)
-- (2004,BAL,0,1,1)
-- (2004,BOS,1,0,0)

team_yr_win_loss_v2 = FOREACH (GROUP game_wls BY (team_id, year_id)) {
  wins   = SUM(game_wls.win);
  losses = SUM(game_wls.loss);
  G_home = SUM(game_wls.is_home);
  G      = COUNT_STAR(game_wls);
  ties   = G - (wins + losses);
  GENERATE group.team_id, group.year_id, G, G_home, wins, losses, ties;
};
--- (BOS,2004,162,81,98,64,0)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(team_yr_win_loss_v1, 'team_yr_win_loss_v1');
STORE_TABLE(team_yr_win_loss_v2, 'team_yr_win_loss_v2');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams  = load_park_teams();

-- ***************************************************************************
--
-- === Cumulative Sums and Other Iterative Functions on Groups
--

-- * Rank
-- * 

-- * Lead
-- * Lag

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Generating a Running Total (Cumulative Sum / Cumulative Difference)


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Generating a Running Product


player_seasons = GROUP bats BY player_id;


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Iterating Lead/Lag Values in an Ordered Bag


--
-- Produce for each stat the running total by season, and the next season's value
-- 
running_seasons = FOREACH player_seasons {
  seasons = ORDER bats BY year_id;
  GENERATE
    group AS player_id,
    FLATTEN(Stitch(
      seasons.year_id,
      seasons.G,  Over(seasons.G,  'SUM(int)'), Over(seasons.G,  'lead', 0, 1, 1, -1), 
      seasons.H,  Over(seasons.H,  'SUM(int)'), Over(seasons.H,  'lead', 0, 1, 1, -1), 
      seasons.HR, Over(seasons.HR, 'SUM(int)'), Over(seasons.HR, 'lead', 0, 1, 1, -1)
      ))
    AS (year_id, G, next_G, cume_G, H, next_H, cume_H, HR, next_HR, cume_HR);
};

STORE_TABLE(running_seasons, 'running_seasons');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

%DEFAULT beg_year 1993
%DEFAULT end_year 2010

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams  = load_park_teams();

-- ***************************************************************************
--
-- === Computing a Win-Expectancy Table

--
-- Here are Tangotiger's results for comparison, giving the average runs scored,
-- from given base/out state to end of inning (for completed innings through the
-- 8th inning); uses Retrosheet 1950-2010 data as of 2010.
-- http://www.tangotiger.net/re24.html
-- 
--                   1993-2010            1969-1992           1950-1968
-- bases \ outs 0_out 1_out 2_out   0_out 1_out 2_out   0_out 1_out 2_out
--
-- -  -   -     0.544 0.291 0.112   0.477 0.252 0.094   0.476 0.256 0.098
-- -  -   3B    1.433 0.989 0.385   1.340 0.943 0.373   1.342 0.926 0.378
-- -  2B  -     1.170 0.721 0.348   1.102 0.678 0.325   1.094 0.680 0.330
-- -  2B  3B    2.050 1.447 0.626   1.967 1.380 0.594   1.977 1.385 0.620
-- 1B -   -     0.941 0.562 0.245   0.853 0.504 0.216   0.837 0.507 0.216
-- 1B -   3B    1.853 1.211 0.530   1.715 1.149 0.484   1.696 1.151 0.504
-- 1B 2B  -     1.556 0.963 0.471   1.476 0.902 0.435   1.472 0.927 0.441
-- 1B 2B  3B    2.390 1.631 0.814   2.343 1.545 0.752   2.315 1.540 0.747
--
--               1993-2010               1969-1992           1950-1968              1950-2010
-- -  -   -     0.539 0.287 0.111   0.471 0.248 0.092   0.471 0.252 0.096     0.4957  0.2634  0.0998  
-- -  -   3B    1.442 0.981 0.382   1.299 0.92  0.368   1.285 0.904 0.373     1.3408  0.9393  0.374   
-- -  2B  -     1.172 0.715 0.339   1.081 0.663 0.316   1.055 0.662 0.322     1.1121  0.682   0.3257  
-- -  2B  3B    2.046 1.428 0.599   1.927 1.341 0.56    1.936 1.338 0.59      1.9754  1.3732  0.5814  
-- 1B -   -     0.932 0.554 0.239   0.843 0.496 0.21    0.828 0.5   0.211     0.8721  0.5181  0.2211  
-- 1B -   3B    1.841 1.196 0.517   1.699 1.131 0.47    1.688 1.132 0.491     1.7478  1.1552  0.4922  
-- 1B 2B  -     1.543 0.949 0.456   1.461 0.886 0.42    1.456 0.912 0.426     1.4921  0.9157  0.4349  
-- 1B 2B  3B    2.374 1.61  0.787   2.325 1.522 0.721   2.297 1.513 0.724     2.3392  1.5547  0.7482  

  
-- load the right range of years and extract stats to be used if needed
events      = load_events($beg_year, $end_year);
event_stats = FOREACH (GROUP events ALL) GENERATE COUNT_STAR(events) AS ct;

--
-- Get the game state (inning + top/bottom; number of outs; bases occupied;
-- score differential), and summable-trick fields for finding the score at the
-- end of the inning and at the end of the game.
--
-- Only one record per inning will have a value for end_inn_sc_maybe, and only
-- one per game for end_game_sc_maybe: so taking the 'MAX' gives only the value
-- of that entry.
--
-- Only innings of 3 full outs are useful for the run expectancy table;
-- otherwise no end_inn_sc is calculated.
-- 
evs_summable = FOREACH events {
  beg_sc  = (home_score - away_score);
  end_sc  = beg_sc + ev_runs_ct;
  GENERATE
    game_id                   AS game_id,
    inn                       AS inn,
    (inn_home == 1 ? 1 : -1)  AS inn_sign:int,
    beg_outs_ct               AS beg_outs_ct,
    (run1_id != '' ? 1 : 0)   AS occ1:int,
    (run2_id != '' ? 1 : 0)   AS occ2:int,
    (run3_id != '' ? 1 : 0)   AS occ3:int,
    beg_sc                    AS beg_sc:int,
    ((is_end_inn  == 1) AND (beg_outs_ct + ev_outs_ct == 3) ? end_sc : NULL) AS end_inn_sc_maybe:int,
    (is_end_game == 1 ? end_sc : NULL)                                       AS end_game_sc_maybe:int
    -- , away_score, home_score, ev_runs_ct, ev_outs_ct, is_end_inn, is_end_game, event_seq
    ;
  };

--
-- Decorate each game's records with the end-of-game score, then partially
-- flatten by inning+half. The result is as if we had initially grouped on
-- (game_id, inn, inn_sign) -- but since each (game) group strictly contains
-- each (game, inn, inn_sign) subgroup, we don't have to do another reduce!
--
evs_by_inning = FOREACH (GROUP evs_summable BY game_id) {
  GENERATE
    MAX(evs_summable.end_game_sc_maybe) AS end_game_sc,
    FLATTEN(BagGroup(evs_summable, evs_summable.(inn, inn_sign)))
    ;
  };

--
-- Flatten further back into single-event records, but now decorated with the
-- end-game and end-inning scores and won/loss/tie status:
--
-- * Decorate each inning's records with the end-of-inning score
-- * Figure out if the game was a win / loss / tie
-- * Convert end-of-* score differentials from (home-away) to (batting-fielding)
-- * Flatten back into individual events.
-- * Decorate each inning's records with the gain-to-end-of-inning. note that
--   this is a batting-fielding differential, not home-away differential
--
-- Must use two steps because end_inn_sc is used to find inn_gain, and you can't
-- iterate inside flatten.
--
evs_decorated = FOREACH evs_by_inning {
  is_win  = ((group.inn_sign*end_game_sc >  0) ? 1 : 0);
  is_loss = ((group.inn_sign*end_game_sc <  0) ? 1 : 0);
  is_tie  = ((group.inn_sign*end_game_sc == 0) ? 1 : 0);
  end_inn_sc = MAX(evs_summable.end_inn_sc_maybe);
  GENERATE
    group.inn, group.inn_sign,
    FLATTEN(evs_summable.(beg_outs_ct, occ1, occ2, occ3, beg_sc
    -- , away_score, home_score, ev_runs_ct, ev_outs_ct, is_end_inn, is_end_game, event_seq, game_id
    )) AS (beg_outs_ct, occ1, occ2, occ3, beg_sc),
    end_game_sc AS end_game_sc,
    end_inn_sc AS end_inn_sc,
    is_win, is_loss, is_tie
    ;
  };
evs_decorated = FOREACH evs_decorated GENERATE
    inn, inn_sign, beg_outs_ct, occ1, occ2, occ3, beg_sc,
  -- away_score, home_score, ev_runs_ct, ev_outs_ct, is_end_inn, is_end_game, event_seq, game_id,
    inn_sign*(end_inn_sc - beg_sc) AS inn_gain,
    end_inn_sc, end_game_sc, is_win, is_loss, is_tie
    ;

-- -- for debugging; make sure to add back the away_score...game_id fields in FOREACH's above
-- DESCRIBE evs_decorated;
-- evs_decorated = ORDER evs_decorated BY game_id, event_seq;
STORE_TABLE('evs_decorated-$beg_year-$end_year', evs_decorated);


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Run Expectancy
-- 
-- How many runs is a game state worth from the perspective of any inning?
-- Bases are cleared away at inning finish, so the average number of runs scored
-- from an event to the end of its inning is the dominant factor.
-- 

-- Only want non-walkoff and full innings
re_evs      = FILTER evs_decorated BY (inn <= 8) AND (end_inn_sc IS NOT NULL);
re_ev_stats = FOREACH (GROUP re_evs ALL) {
  re_ev_ct = COUNT_STAR(re_evs);
  GENERATE re_ev_ct AS ct, ((double)re_ev_ct / (double)event_stats.ct) AS re_ev_fraction;
  };

-- Group on game state in inning (outs and bases occupied),
-- and find the average score gain
run_expectancy = FOREACH (GROUP re_evs BY (beg_outs_ct, occ1, occ2, occ3)) {
  GENERATE
    FLATTEN(group)       AS (beg_outs_ct, occ1, occ2, occ3),
    AVG(re_evs.inn_gain) AS avg_inn_gain,
    COUNT_STAR(re_evs)   AS ct,
    (long)re_ev_stats.ct AS tot_ct,
    (long)event_stats.ct AS tot_unfiltered_ct;
  };

STORE_TABLE('run_expectancy-$beg_year-$end_year', run_expectancy);
-- run_expectancy = LOAD '/tmp/run_expectancy-$beg_year-$end_year' AS (
--   beg_outs_ct:int, occ1:int, occ2:int, occ3:int, avg_inn_gain:float, ct:int, tot_ct:int);

--
-- Baseball Researchers usually format run expectancy tables with rows as bases
-- and columns as outs.  The summable trick will let us create a pivot table of
-- bases vs. runs.

re_summable = FOREACH run_expectancy GENERATE
  CONCAT((occ1 IS NULL ? '-  ' : '1B '), (occ2 IS NULL ? '-  ' : '2B '), (occ3 IS NULL ? '-  ' : '3B ')) AS bases:chararray,
  (beg_outs_ct == 0 ? avg_inn_gain : 0) AS outs_0_col,
  (beg_outs_ct == 1 ? avg_inn_gain : 0) AS outs_1_col,
  (beg_outs_ct == 2 ? avg_inn_gain : 0) AS outs_2_col
  ;
re_pretty = FOREACH (GROUP re_summable BY bases) GENERATE
  group AS bases,
  ROUND_TO(MAX(re_summable.outs_0_col), 3) AS outs_0_col,
  ROUND_TO(MAX(re_summable.outs_1_col), 3) AS outs_1_col,
  ROUND_TO(MAX(re_summable.outs_2_col), 3) AS outs_2_col,
  $beg_year AS beg_year, $end_year AS end_year
  ;

STORE_TABLE('run_expectancy-$beg_year-$end_year-pretty', re_pretty);

