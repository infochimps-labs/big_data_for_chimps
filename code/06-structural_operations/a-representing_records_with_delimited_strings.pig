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

-- Always, always look through the data and seek 'second stories'. A good
-- sifting reveals that the 1898 Cleveland Spiders called seven stadiums their
-- home field, an improbably high figure. We should look deeper.
--

-- Let's start by listing off the parks themselves for each team-year, and while
-- we're at it also introduce a very useful pattern: denormalizing a collection
-- of values into a single delimited field. The format Pig uses to dump bags and
-- tuples to disk uses more characters than are necessary and is not safe to use
-- in general: any string containing a comma or bracket will cause its record to
-- be mis-interpreted. For very simple data structures, we are better off
-- concatenating all the values together using a delimiter -- a character
-- guaranteed to have no other meaning and to not appear in any of the
-- values. This preserves a rows-and-columns representation of the table, which
-- lets us keep using the oh-so-simple TSV format and is friendly to Excel,
-- `cut` and other commandline tools, and back into Pig itself. We will have to
-- pack and unpack the value ourselves, but often as not that's a feature, as it
-- lets us move the field around as a simple string and only pay the cost of
-- constructing a full data structure when it's used.

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
    BagToString(park_tm_yr.park_id,'|') AS park_ids;
  };
-- => LIMIT team_year_w_parks 4 ; DUMP @;
-- (ALT,1884,1,ALT01)
-- (ANA,1997,1,ANA01)
-- ...
-- (CL4,1898,7,CHI08|CLE05|CLL01|PHI09|ROC02|ROC03|STL05)

-- This script ouputs four fields -- park_id, year, count of stadiums, and the
-- names of the stadiums used separated by a `^` caret delimiter. Like colon
-- ':', comma `,`, and slash '/' it doesn't need to be escaped at the
-- commandline; like those and semicolon `;`, pipe `|`, and bang `!`, it is
-- visually lightweight and can be avoided within a value.  Don't use the wrong
-- delimiter for addresses ("Fargo, ND"), dates ("2014-08-08T12:34:56+00:00"),
-- paths (`/tmp/foo`) or unsanitized free text (`It's a girl! ^_^ \m/ |:-)`).

--
-- Besides the two stadiums in Cleveland, there are "home" stadiums in
-- Philadelphia, Rochester, St. Louis, and Chicago -- not close enough to be
-- likely alternatives in case of repairs, and 1898 baseball did not call for
-- publicity tours. Is it simply an unusual number of makeup games? Let's see
-- how many were played at each stadium.
--
-- Instead of a simple list of values, we're now serializing a bag of tuples. We
-- can do this using two delimiters. First use an inner `FOREACH` to staple each
-- park onto the number of games at that park using a colon. Then join all those
-- pairs in the `GENERATE` statement using pipes:

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
  pk_ng_pairs     = FOREACH pty_ordered GENERATE
    CONCAT(park_id, ':', (chararray)n_games) AS pk_ng_pair;
  --
  GENERATE group.team_id, group.year_id,
    COUNT_STAR(park_tm_yr) AS n_parks,
    BagToString(pk_ng_pairs,'|') AS pk_ngs;
  };
-- => LIMIT team_year_w_pkgms 4 ; DUMP @;
-- (ALT,1884,ALT01:18)
-- (ANA,1997,ANA01:82)
-- ...
-- (CL4,1898,CLE05:40|PHI09:9|STL05:2|ROC02:2|CLL01:2|CHI08:1|ROC03:1)

vagabonds   = FILTER team_year_w_pkgms BY n_parks > 1;
nparks_hist = FOREACH (GROUP vagabonds BY year_id)
  GENERATE group AS year_id, CountVals(vagabonds.n_parks) AS hist_u;
nparks_hist = FOREACH nparks_hist {
  hist_o     = ORDER   hist_u BY n_parks ASC;
  hist_pairs = FOREACH hist_o GENERATE CONCAT((chararray)count, ':', (chararray)n_parks);
  GENERATE year_id, BagToString(hist_pairs, ' | ');
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
    BagToString(pk_ng_pairs,'|') AS parks
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
    BagToString(city_pairs,'|')    AS cities,
    BagToString(pty2.parks,'|')    AS parks
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

-- QEM: needs prose (perhaps able to draw from prose file)

-- team_park_years = FOREACH pty GENERATE team_id, park_id, year_id, n_games;
-- team_park_years = ORDER team_park_years BY team_id ASC, year_id ASC, n_games ASC, park_id ASC;
-- STORE_TABLE('team_park_years', team_park_years);

parks = FOREACH parks GENERATE
  park_id, beg_date, end_date, n_games,
  lng, lat, country_id, state_id, city, park_name, comments;

STORE_TABLE('parks', parks);

-- team_year_w_pkgms = FOREACH (GROUP park_tm_yr BY (team_id,year_id)) {
--   pty_ordered     = ORDER park_tm_yr BY n_games DESC;
--   pk_ng_pairs     = FOREACH pty_ordered GENERATE CONCAT(park_id, ':', (chararray)n_games) AS pk_ng_pair;
--   --
--   GENERATE group.team_id, group.year_id,
--     COUNT_STAR(park_tm_yr) AS n_parks,
--     BagToString(pk_ng_pairs,'|');
--   };
-- -- -- ALT	1884	1	ALT01:18
-- -- -- ANA	1997	1	ANA01:82
-- -- -- ...
-- -- -- CL4	1898	7	CHI08:1|CLE05:40|CLL01:2|PHI09:9|ROC02:2|ROC03:1|STL05:2


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
-- team_parkyears_ugly = FOREACH (GROUP team_parks BY team_id) GENERATE
--   group AS team_id,
--   BagToString(team_parks.(park_id, years));
--
-- rmf                            /tmp/team_parkyears_ugly;
-- STORE team_parkyears_ugly INTO '/tmp/team_parkyears_ugly';
-- cat                            /tmp/team_parkyears_ugly;
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



-- Out of 156 games that season, the Spiders played only 42 in Cleveland. They held 15 "home games" in other cities, and played _ninety-nine_ away games -- in all, nearly three-quarters of their season on the road.
-- 
-- The Baseball Library Chronology sheds some light. It turns out that labor
-- problems prevented play at their home or any other stadium in Cleveland for a
-- stretch of time, and so they relocated to Philadelphia while that went
-- on. What's more, on June 19th police arrested the entire team _during_
-- footnote:[The Baseball Library Chronology does note that "not so
-- coincidentally‚ the Spiders had just scored to go ahead 4-3‚ so the arrests
-- assured Cleveland of a victory."  Sounds like the officers, not devoid of
-- hometown pride, might have enjoyed a few innings of the game first.] a home
-- game for violating the Sunday "blue laws" footnote:[As late as 1967, selling
-- a 'Corning Ware dish with lid' in Ohio was still enough to get you convicted
-- of "Engaging in common labor on Sunday":
-- www.leagle.com/decision/19675410OhioApp2d44_148]. Little wonder they decided
-- to take their talents elsewhere than Cleveland! The following year the
-- Spiders played 50 straight on the road, won fewer than 13% overall (20-134,
-- the worst single-season record ever) and then
-- disbanded. http://www.baseballlibrary.com/chronology/byyear.php?year=1898 /
-- http://www.baseball-reference.com/teams/CLV/1898.shtml /
-- http://www.leagle.com/decision/19675410OhioApp2d44_148
-- 
-- NOTE: In traditional analysis with sampled data, edge cases undermine the data -- they present the spectre of a non-representative sample or biased result. In big data analysis on comprehensive data, edge cases prove the data. Home-field advantage comes from a big on-field factor -- the home team plays the deciding half of the final inning -- and several psychological factors -- home-cooked meals, playing in front of fans, a stretch of time in one location. Since 1904, only a very few teams have multiple home stadiums, and no team has had more than two home stadiums in a season. In the example code, we poke at the data a little more and find there's only one other outlier that matters: in 2003 and 2004, les pauvres Montreal Expos were sentenced to play 22 "home" games in San Juan, Puerto Rico and 59 back in Montreal. How can we control for their circumstances? Having every season ever played means you can baseline the jet-powered computer-optimized schedules of the present against the night-train wanderjahr of Cleveland Spiders and other early teams.
-- 
-- Exercise: The table in `teams.tsv` has a column listing only the team's most frequent home stadium for each season; it would be nice to also list all of the ballparks used in a season. The delimited format of lets us keep the simplicity of a TSV format, and doesn't require us to unpack and repack the parks column on every load. 1: Use the JOIN operation introduced later in the chapter (REF) to add the concatenated park-n_game-pairs field to each row of the teams table. 2: Use the "denormalizing an internally-delimited field" (REF) to flatten into a table with one row per park team and year. Hint: you will need to use _both_ the `STRSPLIT` (tuple) and `STRSPLITBAG` (bag) functions, and both senses of `FLATTEN`.
-- 
-- === Denormalizing a collection or data structure into a single JSON-encoded field
-- 
-- With fields of numbers or constrained categorical values, stapling together delimited values is a fine approach. But if the fields are complex, or if there's any danger of stray delimiters sneaking into the record, you may be better off converting the record to JSON. It's a bit more heavyweight but nearly as portable, and it happy bundles complex structures and special characters to hide within TSV files. footnote:[And if nether JSON nor simple-delimiter is appropriate, use Parquet or Trevni, big-data optimized formats that support complex data structures. As we'll explain in chapter (REF), those are your three choices: TSV with delimited fields; TSV with JSON fields or JSON lines on their own; or Parquet/Trevni. We don't recommend anything further.]

-- mapper(array_fields_of: ParkTeamYear) do |park_id, team_id, year_id, beg_date, end_date, n_games|
--  yield [team_id, year_id, park_id, n_games]
-- end
-- 
-- reducer do |(team_id, year_id), stream|
--   parks   = stream. map{|park_id, n_games| [park_id, n_games.to_i] }
--   n_parks = stream.size
--   if n_parks > 1
--     yield [team_id, year_id.to_i, n_parks, parks.to_json]
--   end
-- end
-- 
-- # ALT	1884	[["ALT01",18]]
-- # ANA   1997    [["ANA01",82]]
-- # ...
-- # CL4   1898    [["CLE05",40],[PHI09,9],[STL05,2],[ROC02,2],[CLL01,2],[CHI08,1],[ROC03,1]]
