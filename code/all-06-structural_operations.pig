IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- (work into the chapter introduction)
-- The overriding focus here is to equip you with the toolkit of analytic patterns.
-- The most meaningful way to introduce these patterns is to demonstrate their use in service of a question of real interest.
-- the main storyline of these chapters will be to find quantitative indicators of exceptional performance, and we'll pick that thread up repeatedly.
-- But where a pattern has no natural demonstration in service of that primary story, we non-sequitur into questions that could form a necessary piece of some other investigation:
-- "here's how you'd track changes in each team's roster over time", "is the stereotypical picture of the big brawny home-run hitter true." (TODO-qem please replace with what you found to be the most interesting one-offs (ie side-roads we didn't explore)).
-- And at several points, immediately on peeking down a side road the data comes forth with a story of its own, and so there are also a few brief side trips to follow such a tale.
-- But as we revisit the player-performance exploration, you should recognize not just a way for fantasy baseball players to get an edge, but strategies for quantifying the behavior of any sort of outlier. Here, it's baseball players, but similar questions will apply when examining agents posing security threats, factors causing manufacturing defects, cell strains with a significantly positive response, and many other topics of importance.
--
-- Although
-- in some cases, it's not wo



-- ***************************************************************************
--
-- === Grouping Records into a Bag by Key
--

-- The GROUP BY operation is at the heart of every structural operation. It's a
-- one-liner in Pig to collect all the stadiums each team has played for:
--
park_tm_yr_g = GROUP park_tm_yr BY team_id;

-- The result of a group is always a field called 'group', having the schema of
-- the key (atom) or keys (tuple); and then one field per grouped table, each
-- named for the table it came from. Notice that the name we used to refer to
-- the _table_ is now also the name for a _field_. This will confuse you at
-- first, but soon become natural. Until then, use `DESCRIBE` liberally.
--
-- DESCRIBE park_tm_yr_g;
-- -- park_tm_yr_g: {
-- --    group: chararray,
-- --    park_tm_yr: {
-- --        ( park_id: chararray, team_id: chararray, year_id: long,
-- --          beg_date: chararray, end_date: chararray, n_games: long ) } }

-- Notice that the _full record_ is kept, even including the keys:
--
-- => LIMIT park_tm_yr_g 2 ; DUMP @;
-- (ALT,{(ALT01,ALT,1884,1884-04-30,1884-05-31,18)})
-- (ANA,{(ANA01,ANA,2001,2001-04-10,2001-10-07,81),(ANA01,ANA,2010,2010-04-05,2010-09-29,81),...})

-- Because of this redundancy, it's pretty common to immediately project using a
-- FOREACH, .
--
-- This means it's pretty common to immediately project using a FOREACH, and we
-- can even put the `GROUP BY` statement inline:

-- We want to keep the team_id
team_py_pairs = FOREACH (GROUP park_tm_yr BY team_id) GENERATE
  group AS team_id, park_tm_yr.(park_id,year_id);
-- -- (ALT,{(ALT01,1884)})
-- -- (ANA,{(ANA01,2001),(ANA01,2010),(ANA01,2002),...})

-- Notice the `park_tm_yr.(park_id,year_id)` form, which gives us a bag of
-- (park_id,year_id) pairs. Using `park_tm_yr.park_id, park_tm_yr.year_id`
-- instead gives two bags, one with park_id tuples and one with year_id tuples:
team_py_bags = FOREACH (GROUP park_tm_yr BY team_id) GENERATE
  group AS team_id, park_tm_yr.park_id, park_tm_yr.year_id;

-- Notice the `park_tm_yr.(park_id,year_id)` form, which gives us a bag of
-- (park_id,year_id) pairs. Using `park_tm_yr.park_id, park_tm_yr.year_id`
-- instead gives two bags, one with park_id tuples and one with year_id tuples:

------
team_py_bags = FOREACH (GROUP park_tm_yr BY team_id)
  GENERATE group AS team_id, park_tm_yr.park_id, park_tm_yr.year_id;
-- -- (ALT, {(ALT01)}, {(1884)})
-- -- (ANA, {(ANA01),(ANA01),(ANA01),...}, {(2001),(2010),(2002),...})

DESCRIBE team_py_pairs;
-- -- team_parks: { team_id: chararray, { (park_id: chararray, year_id: long) } }

DESCRIBE team_py_bags;
-- -- team_parks: { team_id: chararray, { (park_id: chararray) }, { (year_id: long) } }

-- You can group on multiple fields.  For each park and team, find all the years
-- that the park hosted that team:

-- (Notice the which you can do cleanly with an inline GROUP BY statement
-- QEM: reword

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

-- The first field is still called 'group', but it's now a tuple
DESCRIBE park_team_g;
-- -- park_team_g: {
-- --   group: (park_id: chararray, team_id: chararray),
-- --   park_tm_yr: { (park_id: chararray, team_id: chararray, year_id: long, ...) } }

-- ====


-- The first field is still called 'group', but it's now a tuple, and so our `FOREACH` statement looks a bit different:

-- And so we have to dereference into group:
park_team_occupied = FOREACH(GROUP park_tm_yr BY (park_id, team_id)) GENERATE
  group.park_id, group.team_id, park_tm_yr.year_id;
--
-- => LIMIT park_team_occupied 3 ; DUMP @;
-- -- (ALB01,TRN,{(1882),(1880),(1881)})
-- -- (ALT01,ALT,{(1884)})
-- -- (ANA01,ANA,{(2009),(2008),(1997)...})

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== FOREACH with GROUP BY lets you summarize and
--
-- Operations that summarize the grouped value: This finds all teams that called
-- more than one stadium "home" during a year:
--
-- The typical reason to do a group is to operate on it, and that's how we'll
-- spend much of this chapter. For example, sometimes a team has more than one
-- "home" stadium in a season, typically due to stadium repairs or late-season
-- makeups for cancelled games; for publicity MLB has opened the season with a
-- series in Japan or Mexico a few times.
--
-- team_n_parks = FOREACH (GROUP park_tm_yr BY (team_id,year_id)) GENERATE
--   group.team_id,
--   group.year_id,
--   COUNT_STAR(park_tm_yr) AS n_parks;
-- vagabonds = FILTER team_n_parks BY n_parks > 1;
--
-- => LIMIT (ORDER vagabonds BY n_parks DESC) 4; DUMP @;
-- -- (CL4,1898,7)
-- -- (CLE,1902,5)
-- -- (WS3,1871,4)
-- -- (BSN,1894,3)
-- -- ...
--
-- Always, always look through the data and seek 'second stories'. In this case
-- you'll notice that the 1898 Cleveland Spiders used seven(!) stadiums as home
-- field.
--
-- === How a group works
--
-- mapper(array_fields_of: ParkTeamYear) do |park_id, team_id, year_id, beg_date, end_date, n_games|
--  yield [team_id, year_id]
-- end
--
-- # In effect, what is happening in Java:
-- reducer do |(team_id, year_id), stream|
--   n_parks = 0
--   stream.each do |*_|
--     n_parks += 1
--   end
--   yield [team_id, year_id, n_parks] if n_parks > 1
-- end
--
-- # (ln actual practice, the ruby version would call stream.size rather than iterating:
-- #  n_parks = stream.size ; yield [team_id, year_id, n_parks] if n_parks > 1

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
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Summarizing Aggregate Statistics of a Full Table
--

-- QEM: needs prose (perhaps able to draw from prose file)

bat_seasons = FOREACH bat_seasons GENERATE *, (float)HR*HR AS HRsq:float;

hr_info = FOREACH (GROUP bat_seasons ALL) {
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
    COUNT_STAR(hrs_distinct) AS hr_card
    ;
  }

-- Note the syntax of the full-table group statement. There's no I in TEAM, and no BY in GROUP ALL.

STORE_TABLE(hr_info, 'hr_info');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons   = load_bat_seasons();

--
-- === Group and Aggregate
--
-- Some of the happiest moments you can have analyzing a massive data set come
-- when you are able to make it a slightly less-massive data set. Statistical
-- aggregations let you summarize the essential characteristics of a table.
--
-- ===== Aggregate Statistics of a Group
--
-- In the previous chapter, we used each player's seasonal counting stats --
-- hits, home runs, and so forth -- to estimate seasonal rate stats -- how well
-- they get on base (OPS), how well they clear the bases (SLG) and an overall
-- estimate of offensive performance (OBP). We can use a group-and-aggregate on
-- the seasonal stats to find each player's career stats.
--
bat_careers = FOREACH (GROUP bat_seasons BY player_id) {
  team_ids = DISTINCT bat_seasons.team_id;
  totG   = SUM(bat_seasons.G);   totPA  = SUM(bat_seasons.PA);  totAB  = SUM(bat_seasons.AB);
  totH   = SUM(bat_seasons.H);   totBB  = SUM(bat_seasons.BB);  totHBP = SUM(bat_seasons.HBP); totR   = SUM(bat_seasons.R);
  toth1B = SUM(bat_seasons.h1B); toth2B = SUM(bat_seasons.h2B); toth3B = SUM(bat_seasons.h3B); totHR  = SUM(bat_seasons.HR);
  OBP    = 1.0*(totH + totBB + totHBP) / totPA;
  SLG    = 1.0*(toth1B + 2*toth2B + 3*toth3B + 4*totHR) / totAB;
  GENERATE
    group                          AS player_id,
    COUNT_STAR(bat_seasons)        AS n_seasons,
    COUNT_STAR(team_ids)           AS n_distinct_teams,
    MIN(bat_seasons.year_id)	     AS beg_year,
    MAX(bat_seasons.year_id)       AS end_year,
    totG   AS G,   totPA  AS PA,  totAB  AS AB,
    totH   AS H,   totBB  AS BB,  totHBP AS HBP,
    toth1B AS h1B, toth2B AS h2B, toth3B AS h3B, totHR AS HR,
    OBP AS OBP, SLG AS SLG, (OBP + SLG) AS OPS
    ;
};

-- We've used some aggregate functions to create an output table with similar structure to the input table, but at a coarser-grained relational level: career rather than season. It's good manners to put the fields in a recognizable order as the original field as we have here.

DESCRIBE bat_seasons;
DESCRIBE bat_careers;

--
-- ==== Completely Summarizing a Field
--

-- The following functions are built in to Pig:
--
-- * Count of all values: `COUNT_STAR(bag)`
-- * Count of non-Null values: `COUNT(bag)`
-- * Cardinality (i.e. the count of distinct values): combine the `DISTINCT` operation and the `COUNT_STAR` function as demonstrated below.
-- * Minimum / Maximum non-Null value: `MIN(bag)` / `MAX(bag)`
-- * Sum of non-Null values: `SUM(bag)`
-- * Average of non-Null values: `AVG(bag)`
--
-- There are a few additional summary functions that aren't native features of
-- Pig, but are offered by Linkedin's might-as-well-be-native DataFu
-- package. footnote:[If you've forgotten/never quite learned what those
-- functions mean, hang on for just a bit and we'll demonstrate them in
-- context. If that still doesn't do it, set a copy of
-- http://www.amazon.com/dp/039334777X[Naked Statistics] or
-- http://www.amazon.com/Head-First-Statistics-Dawn-Griffiths/dp/0596527586[Head
-- First Statistics] next to this book. Both do a good job of efficiently
-- imparting what these functions mean and how to use them without assuming
-- prior expertise or interest in mathematics. This is important material
-- though. Every painter of landscapes must know how to convey the essence of a
-- https://www.youtube.com/watch?v=YLO7tCdBVrA[happy little tree] using a few
-- deft strokes and not the prickly minutae of its 500 branches; the above
-- functions are your brushes footnote:[Artist/Educator Bob Ross: "Anyone can
-- paint, all you need is a dream in your heart and a little bit of practice" --
-- hopefully you're feeling the same way about Big Data analysis.].
--
-- * Variance of non-Null values: `VAR(bag)`, using the `datafu.pig.stats.VAR` UDF
-- * Standard Deviation of non-Null values: `SQRT(VAR(bag))`
-- * Quantiles: `Quantile(bag)` or `StreamingQuantile(bag)`
-- * Median (50th Percentile Value) of a Bag: `Median(bag)` or `StreamingMedian(bag)`
--
-- The previous chapter (REF) has details on how to use UDFs, and so we're going
-- to leave the details of that to the sample code. You'll also notice we list
-- two functions for quantile and for median.  Finding the exact median or other
-- quantiles (as the Median/Quantile UDFs do) is costly at large scale, and so a
-- good approximate algorithm (StreamingMedian/StreamingQuantile) is well
-- appreciated. Since the point of this stanza is to characterize the values for
-- our own sense-making, the approximate algorithms are appropriate. We'll have
-- much more to say about why finding quantiles is costly, why finding averages
-- isn't, and what to do about it in the Statistics chapter (REF).
--

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
--     COUNT_STAR(dist)                     AS cardinality,
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
--     AVG(bat_seasons.weight)        AS avg_val,
--     SQRT(VAR(bat_seasons.weight))  AS stddev_val,
--     MIN(bat_seasons.weight)        AS min_val,
--     FLATTEN(SortedEdgeile(sorted)) AS (p01, p05, p50, p95, p99),
--     MAX(bat_seasons.weight)        AS max_val,
--     --
--     n_recs                         AS n_recs,
--     n_recs - n_notnulls            AS n_nulls,
--     COUNT_STAR(dist)               AS cardinality,
--     SUM(bat_seasons.weight)        AS sum_val,
--     BagToString(some, '^')         AS some_vals
--     ;
-- };
--
-- DESCRIBE     weight_yr_stats;
-- STORE_TABLE('weight_yr_stats', weight_yr_stats);
-- cat $out_dir/weight_yr_stats;


-- H_summary_base = FOREACH (GROUP bat_seasons ALL) {
--   dist       = DISTINCT bat_seasons.H;
--   examples   = LIMIT    dist.H 5;
--   n_recs     = COUNT_STAR(bat_seasons);
--   n_notnulls = COUNT(bat_seasons.H);
--   GENERATE
--     group,
--     'H'                       AS var:chararray,
--     MIN(bat_seasons.H)             AS minval,
--     MAX(bat_seasons.H)             AS maxval,
--     --
--     AVG(bat_seasons.H)             AS avgval,
--     SQRT(VAR(bat_seasons.H))       AS stddev,
--     SUM(bat_seasons.H)             AS sumval,
--     --
--     n_recs                         AS n_recs,
--     n_recs - n_notnulls            AS n_nulls,
--     COUNT_STAR(dist)               AS cardinality,
--     BagToString(examples, '^')     AS examples
--     ;
-- };
-- -- (all,H,46.838027175098475,56.05447208643693,0,262,77939,0,250,3650509,0^1^2^3^4)
--
-- H_summary = FOREACH (GROUP bat_seasons ALL) {
--   dist       = DISTINCT bat_seasons.H;
--   non_nulls  = FILTER   bat_seasons.H BY H IS NOT NULL;
--   sorted     = ORDER    non_nulls BY H;
--   examples   = LIMIT    dist.H 5;
--   n_recs     = COUNT_STAR(bat_seasons);
--   n_notnulls = COUNT(bat_seasons.H);
--   GENERATE
--     group,
--     'H'                       AS var:chararray,
--     MIN(bat_seasons.H)             AS minval,
--     FLATTEN(SortedEdgeile(sorted)) AS (p01, p05, p10, p50, p90, p95, p99),
--     MAX(bat_seasons.H)             AS maxval,
--     --
--     AVG(bat_seasons.H)             AS avgval,
--     SQRT(VAR(bat_seasons.H))       AS stddev,
--     SUM(bat_seasons.H)             AS sumval,
--     --
--     n_recs                         AS n_recs,
--     n_recs - n_notnulls            AS n_nulls,
--     COUNT_STAR(dist)               AS cardinality,
--     BagToString(examples, '^')     AS examples
--     ;
-- };
-- -- (all,H,46.838027175098475,56.05447208643693,0,0.0,0.0,0.0,17.0,141.0,163.0,193.0,262,77939,0,250,3650509,0^1^2^3^4)
--
-- -- ***************************************************************************
-- --
-- -- === Completely Summarizing the Values of a String Field
-- --
--
-- name_first_summary_0 = FOREACH (GROUP bat_seasons ALL) {
--   dist       = DISTINCT bat_seasons.name_first;
--   lens       = FOREACH  bat_seasons GENERATE SIZE(name_first) AS len; -- Coalesce(name_first,'')
--   --
--   n_recs     = COUNT_STAR(bat_seasons);
--   n_notnulls = COUNT(bat_seasons.name_first);
--   --
--   examples   = LIMIT    dist.name_first 5;
--   snippets   = FOREACH  examples GENERATE (SIZE(name_first) > 15 ? CONCAT(SUBSTRING(name_first, 0, 15),'…') : name_first) AS val;
--   GENERATE
--     group,
--     'name_first'                   AS var:chararray,
--     MIN(lens.len)                  AS minlen,
--     MAX(lens.len)                  AS maxlen,
--     --
--     AVG(lens.len)                  AS avglen,
--     SQRT(VAR(lens.len))            AS stdvlen,
--     SUM(lens.len)                  AS sumlen,
--     --
--     n_recs                         AS n_recs,
--     n_recs - n_notnulls            AS n_nulls,
--     COUNT_STAR(dist)               AS cardinality,
--     MIN(bat_seasons.name_first)    AS minval,
--     MAX(bat_seasons.name_first)    AS maxval,
--     BagToString(snippets, '^')     AS examples,
--     lens  AS lens
--     ;
-- };
--
-- name_first_summary = FOREACH name_first_summary_0 {
--   sortlens   = ORDER lens  BY len;
--   pctiles    = SortedEdgeile(sortlens);
--   GENERATE
--     var,
--     minlen, FLATTEN(pctiles) AS (p01, p05, p10, p50, p90, p95, p99), maxlen,
--     avglen, stdvlen, sumlen,
--     n_recs, n_nulls, cardinality,
--     minval, maxval, examples
--     ;
-- };

STORE_TABLE('bat_careers', bat_careers);
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

sig_seasons = load_sig_seasons();


-- ***************************************************************************
--
-- === Calculating a Histogram Within a Group
--

-- As long as the groups in question do not rival the available memory, counting how often each value occurs within a group is easily done using the DataFu `CountEach` UDF. There's been a trend over baseball's history for increased specialization

-- http://datafu.incubator.apache.org/docs/datafu/guide/bag-operations.html

-- You'll see the

DEFINE CountVals              datafu.pig.bags.CountEach('flatten');

binned = FOREACH sig_seasons GENERATE
  ( 5 * ROUND(year_id/ 5.0f)) AS year_bin,
  (20 * ROUND(H      /20.0f)) AS H_bin;

-- hist_by_year_bags = FOREACH (GROUP binned BY year_bin) {
--   H_hist_cts = CountVals(binned.H_bin);
--   GENERATE group AS year_bin, H_hist_cts AS H_hist_cts;
-- };

-- We want to normalize this to be a relative-fraction histogram, so that we can
-- make comparisons across eras even as the number of active players grows.
-- Finding the total count to divide by is a straightforward COUNT_STAR on the
-- group, but a peccadillo of Pig's syntax makes using it a bit frustrating.
-- Annoyingly, a nested FOREACH can only "see" values from the bag it's
-- operating on, so there's no natural way to reference the calculated total
-- from the FOREACH statement.
--
-- -- Won't work:
-- hist_by_year_bags = FOREACH (GROUP binned BY year_bin) {
--   H_hist_cts = CountVals(binned.H_bin);
--   tot        = 1.0f*COUNT_STAR(binned);
--   H_hist_rel = FOREACH H_hist_cts GENERATE H_bin, (float)count/tot;
--   GENERATE group AS year_bin, H_hist_cts AS H_hist_cts, tot AS tot;
-- };

--
-- The best current workaround is to generate the whole-group total in the form
-- of a bag having just that one value. Then we use the CROSS operator to graft
-- it onto each (bin,count) tuple, giving us a bag with (bin,count,total) tuples
-- -- yes, every tuple in the bag will have the same group-wide value. Finally,
-- This lets us iterate across those tuples to find the relative frequency.
--
-- It's more verbose than we'd like, but the performance hit is limited to the
-- CPU and GC overhead of creating three bags (`{(result,count)}`,
-- `{(result,count,total)}`, `{(result,count,freq)}`) in quick order.
--
hist_by_year_bags = FOREACH (GROUP binned BY year_bin) {
  H_hist_cts = CountVals(binned.H_bin);
  tot        = COUNT_STAR(binned);
  GENERATE
    group      AS year_bin,
    H_hist_cts AS H_hist,
    {(tot)}    AS info:bag{(tot:long)}; -- single-tuple bag we can feed to CROSS
};

hist_by_year = FOREACH hist_by_year_bags {
  -- Combines H_hist bag {(100,93),(120,198)...} and dummy tot bag {(882.0)}
  -- to make new (bin,count,total) bag: {(100,93,882.0),(120,198,882.0)...}
  H_hist_with_tot = CROSS   H_hist, info;
  -- Then turn the (bin,count,total) bag into the (bin,count,freq) bag we want
  H_hist_rel      = FOREACH H_hist_with_tot
    GENERATE H_bin, count AS ct, count/((float)tot) AS freq;
  GENERATE year_bin, H_hist_rel;
};

DESCRIBE hist_by_year;

STORE_TABLE(hist_by_year, 'hist_by_year');

--
-- Exercise: generate histograms-by-year
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Calculating a Relative Distribution Histogram
--


-- ==== Calculating Percent Relative to Total
--
-- The histograms we've calculated have results in terms of counts. The results do a better general job of enforcing comparisons if express them as relative frequencies: as fractions of the total count. You know how to find the total:
--
-- ------
-- HR_stats = FOREACH (GROUP bats BY ALL) GENERATE COUNT_STAR(bats) AS n_players;
-- ------
--
-- The problem is that HR_stats is a single-row table, and so not something we can use directly in a FOREACH expression. Pig gives you a piece of syntactic sugar for this specific case of a one-row table footnote:[called 'scalar projection' in Pig terminology]: project the value as tablename.field as if it were an inner bag, but slap the field's type (in parentheses) in front of it like a typecast expression:
--
-- ------
-- HR_stats = FOREACH (GROUP bats BY ALL) GENERATE COUNT_STAR(bats) AS n_total;
-- HR_hist  = FOREACH (GROUP bats BY HR) {
--   ct = COUNT_STAR(bats);
--   GENERATE HR as val,
--     ct/( (long)HR_stats.n_total ) AS freq,
--     ct;
-- };
-- ------
--
-- Typecasting the projected field as if you were simply converting the schema of a field from one scalar type to another acts as a promise to Pig  that what looks like column of possibly many values will turn out to have only row. In return, Pig will understand that you want a sort of über-typecast of the projected column into what is effectively its literal value.
--


-- ***************************************************************************
--
-- === Re-injecting Global Values
--

-- ==== Re-injecting global totals
--
-- Sometimes things are more complicated, and what you'd like to do is perform light synthesis of the results of some initial Hadoop jobs, then bring them back into your script as if they were some sort of "global variable". But a pig script just orchestrates the top-level motion of data: there's no good intrinsic ways to bring the result of a step into the declaration of following steps. You can use a backhoe to tear open the trunk of your car, but it's not really set up to push the trunk latch button. The proper recourse is to split the script into two parts, and run it within a workflow tool like Rake, Drake or Oozie. The workflow layer can fish those values out of the HDFS and inject them as runtime parameters into the next stage of the script.
--
-- In the case of global counts, it would be so much faster if we could sum the group counts to get the global totals; but that would mean a job to get the counts, a job to get the totals, and a job to get the relative frequencies. Ugh.
--
-- If the global statistic is relatively static, there are occasions where we prefer to cheat. Write the portion of the script that finds the global count and stores it, then comment that part out and inject the values statically -- the sample code shows you how to do it with with a templating runner, as runtime parameters, by copy/pasting, or using the `cat` Grunt shell statement. Then, to ensure your time-traveling shenanigans remain valid, add an `ASSERT` statement comparing the memoized values to the actual totals. Pig will not only run the little checkup stage in parallel if possible, it will realize that the data size is small enough to run as a local mode job -- cutting the turnaround time of a tiny job like that in half or better.
--
-- ------
-- -- cheat mode:
-- -- HR_stats = FOREACH (GROUP bats BY ALL) GENERATE COUNT_STAR(bats) AS n_total;
-- SET HR_stats_n_total = `cat $out_dir/HR_stats_n_total`;
--
-- HR_hist  = FOREACH (GROUP bats BY HR) {
--   ct = COUNT_STAR(bats);
--   GENERATE HR as val, ct AS ct,
--     -- ct/( (long)HR_stats.n_total ) AS freq,
--     ct/( (long)HR_stats_n_total) AS freq,
--     ct;
-- };
-- -- the much-much-smaller histogram is used to find the total after the fact
-- --
-- ASSERT (GROUP HR_hist ALL)
--   IsEqualish( SUM(freq), 1.0 ),
--   (HR_stats_n_total == SUM(ct);
-- ------
--
-- As we said, this is a cheat-to-win scenario: using it to knock three minutes off an eight minute job is canny when used to make better use of a human data scientist's time, foolish when applied as a production performance optimization.

IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
numbers     = load_numbers_10k();

bat_careers = LOAD_RESULT('bat_careers');

-- ***************************************************************************
--
-- === Calculating the Distribution of Numeric Values with a Histogram


-- One of the most common uses of a group-and-aggregate is to create a histogram
-- showing how often each value (or range of values) of a field occur. This
-- calculates the distribution of seasons played -- that is, it counts the
-- number of players whose career lasted only a single season; who played for
-- two seasons; and so forth, up

vals = FOREACH bat_careers GENERATE n_seasons AS bin;
seasons_hist = FOREACH (GROUP vals BY bin) GENERATE
  group AS bin, COUNT_STAR(vals) AS ct;

vals = FOREACH (GROUP bat_seasons BY (player_id, name_first, name_last)) GENERATE
  COUNT_STAR(bat_seasons) AS bin, flatten(group);
seasons_hist = FOREACH (GROUP vals BY bin) {
  some_vals = LIMIT vals 3;
  GENERATE group AS bin, COUNT_STAR(vals) AS ct, BagToString(some_vals, '|');
};

-- So the pattern here is to
--
-- * project only the values,
-- * Group by the values,
-- * Produce the group as key and the count as value.


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Binning Data for a Histogram
--

H_vals = FOREACH bat_seasons GENERATE H;
H_hist = FOREACH (GROUP H_vals BY H) GENERATE
  group AS val, COUNT_STAR(H_vals) AS ct;

-- QEM: needs prose (perhaps able to draw from prose file)

--
-- Note: the above snippet is what's in the book. We're actually going to steal
-- a topic from later ("Filling Gaps in a List") because it makes it much easier
-- to import into excel.
--
all_bins = FILTER numbers BY (num0 < 280);
H_hist = FOREACH (COGROUP H_vals BY H, all_bins BY num0) GENERATE
  group AS val, (COUNT_STAR(H_vals) == 0L ? Null : COUNT_STAR(H_vals)) AS ct;


-- What binsize? These zoom in on the tail -- more than 2000 games played. A bin size of 200 is too coarse; it washes out the legitimate gaps. The bin size of 2 is too fine -- the counts are small and there are many trivial gaps. We chose a bin size of 50 games; it's meaningful (50 games represents about 1/3 of a season), it gives meaty counts per bin even when the population starts to become sparse, while preserving the gaps that demonstrate the epic scope of the career of Pete Rose (our 3,562-game outlier).


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Interpreting Histograms and Quantiles
--

-- Different underlying mechanics will give different distributions.

DEFINE histogram(table, key) RETURNS dist {
  vals = FOREACH $table GENERATE $key;
  $dist = FOREACH (GROUP vals BY $key) GENERATE
    group AS val, COUNT_STAR(vals) AS ct;
};

DEFINE binned_histogram(table, key, binsize, maxval) RETURNS dist {
  numbers = load_numbers_10k();
  vals = FOREACH $table GENERATE (ROUND($key / $binsize) * $binsize) AS bin;
  all_bins = FOREACH numbers GENERATE (num0 * $binsize) AS bin;
  all_bins = FILTER  all_bins BY (bin <= $maxval);
  $dist = FOREACH (COGROUP vals BY bin, all_bins BY bin) GENERATE
    group AS bin, (COUNT_STAR(vals) == 0L ? Null : COUNT_STAR(vals)) AS ct;
};

season_G_hist = histogram(bat_seasons, 'G');
career_G_hist = binned_histogram(bat_careers, 'G', 50, 3600);

career_G_hist_2   = binned_histogram(bat_careers, 'G', 2, 3600);
career_G_hist_200 = binned_histogram(bat_careers, 'G', 200, 3600);

career_HR_hist = binned_histogram(bat_careers, 'HR', 10, 800);


-- Distribution of Games Played

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Extreme Populations and Confounding Factors

-- To reach the major leagues, a player must possess multiple extreme
-- attributes: ones that are easy to measure, like being tall or being born in a
-- country where baseball is popular; and ones that are not, like field vision,
-- clutch performance, the drive to put in outlandishly many hours practicing
-- skills. Any time you are working with extremes as we are, you must be very
-- careful to assume their characteristics resemble the overall population's.

-- Here again are the graphs for players' height and weight, but now graphed
-- against (in light blue) the distribution of height/weight for US males aged
-- 20-29 footnote:[US Census Department, Statistical Abstract of the United States.
-- Tables 206 and 209, Cumulative Percent Distribution of Population by
-- (Weight/Height) and Sex, 2007-2008; uses data from the U.S. National Center
-- for Health Statistics].
--
-- The overall-population distribution is shown with light blue bars, overlaid
-- with a normal distribution curve for illustrative purposes. The population of
-- baseball players deviates predictably from the overall population: it's an
-- advantage to The distribution of player weights, meanwhile, is shifted
-- somewhat but with a dramatically smaller spread.


-- Surely at least baseball players are born and die like the rest of us, though?

-- Distribution of Birth and Death day of year

vitals = FOREACH peeps GENERATE
  height_in,
  10*CEIL(weight_lb/10.0) AS weight_lb,
  birth_month,
  death_month;

birth_month_hist = histogram(vitals, 'birth_month');
death_month_hist = histogram(vitals, 'death_month');
height_hist = histogram(vitals, 'height_in');
weight_hist = histogram(vitals, 'weight_lb');

attr_vals = FOREACH vitals GENERATE
  FLATTEN(Transpose(height, weight, birth_month, death_month)) AS (attr, val);

attr_vals_nn = FILTER attr_vals BY val IS NOT NULL;

-- peep_stats   = FOREACH (GROUP attr_vals_nn BY attr) GENERATE
--   group                        AS attr,
--   COUNT_STAR(attr_vals_nn)     AS ct_all,
--   COUNT_STAR(attr_vals_nn.val) AS ct;

peep_stats = FOREACH (GROUP attr_vals_nn ALL) GENERATE
  BagToMap(CountVals(attr_vals_nn.attr)) AS cts:map[long];

peep_hist = FOREACH (GROUP attr_vals BY (attr, val)) {
  ct = COUNT_STAR(attr_vals);
  GENERATE
    FLATTEN(group) AS (attr, val),
    ct             AS ct
    -- , (float)ct / ((float)peep_stats.ct) AS freq
    ;
};
peep_hist = ORDER peep_hist BY attr, val;

one = LOAD '$data_dir/stats/numbers/one.tsv' AS (num:int);
ht = FOREACH one GENERATE peep_stats.cts#'height';

-- A lot of big data analyses explore population extremes: manufacturing
-- defects, security threats, disease carriers, peak performers.  Elements
-- arrive into these extremes exactly because multiple causative features drive
-- them there (such as an advantageous height or birth month); and a host of
-- other conflated features follow from those deviations (such as those stemming
-- from the level of fitness athletes maintain).
--
-- So whenever you are examining populations of outliers, you cannot depend on
-- their behavior resembling the universal population. Normal distributions may
-- not remain normal and may not even retain a central tendency; independent
-- features in the general population may become tightly coupled in the outlier
-- group; and a host of other easy assumptions become invalid. Stay alert.
--


STORE_TABLE(seasons_hist, 'seasons_hist');
-- STORE_TABLE(career_G_hist,     'career_G_hist');
-- STORE_TABLE(career_G_hist_2,   'career_G_hist_2');
-- STORE_TABLE(career_G_hist_200, 'career_G_hist_200');
-- STORE_TABLE(career_HR_hist,    'career_HR_hist');

-- STORE_TABLE(peep_hist, 'peep_hist');
-- STORE_TABLE(birth_month_hist, 'birth_month_hist');
-- STORE_TABLE(death_month_hist, 'death_month_hist');
-- STORE_TABLE(height_hist, 'height_hist');
-- STORE_TABLE(weight_hist, 'weight_hist');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
mod_seasons = load_mod_seasons(); -- modern (post-1900) seasons of any number of PA only

-- ***************************************************************************
--
-- === The Summing Trick
--

-- ***************************************************************************
--
-- === Counting Conditional Subsets of a Group -- The Summing Trick
--

--
-- Whenever you are exploring a dataset, you should determine figures of merit
-- for each of the key statistics -- easy-to-remember values that separate
-- qualitatively distinct behaviors. You probably have a feel for the way that
-- 30 C / 85 deg F reasonably divides a "warm" day from a "hot" one; and if I
-- tell you that a sub-three-hour marathon distinguishes "really impress your
-- friends" from "really impress other runners", you are equipped to recognize
-- how ludicrously fast a 2:15 (the pace of a world-class runner) marathon is.
--
-- For our purposes, we can adopt 180 hits (H), 30 home runs (HR), 100 runs
-- batted in (RBI), a 0.400 on-base percentage (OBP) and a 0.500 slugging
-- percentage (SLG) each as the dividing line between a good and a great
-- performance.
--
-- One reasonable way to define a great career is to ask how many great seasons
-- a player had. We can answer that by counting how often a player's season
-- totals exceeded each figure of merit. The obvious tactic would seem to
-- involve filtering and counting each bag of seasonal stats for a player's
-- career; that is cumbersome to write, brings most of the data down to the
-- reducer, and exerts GC pressure materializing multiple bags.
--
-- Instead, we will apply what we like to call the "Summing trick", a frequently
-- useful way to act on subsets of a group without having to perform multiple
-- GROUP BY or FILTER operations. Call it to mind every time you find yourself
-- thinking "gosh, this sure seems like a lot of reduce steps on the same key".
--
-- The summing trick involves projecting a new field whose value is based on
-- whether it's in the desired set, forming the desired groups, and aggregating
-- on those new fields. Irrelevant records are assigned a value that will be
-- ignored by the aggregate function (typically zero or NULL), and so although
-- we operate on the group as a whole, only the relevant records contribute.
--
-- In this case, instead of sending all the hit, home run, etc figures directly
-- to the reducer to be bagged and filtered, we send a `1` for seasons above the
-- threshold and `0` otherwise. After the group, we find the _count_ of values
-- meeting our condition by simply _summing_ the values in the indicator
-- field. This approach allows Pig to use combiners (and so less data to the
-- reducer); and more importantly it doesn't cause a bag of values to be
-- collected, only a running sum (and so way less garbage-collector pressure).

-- Create indicator fields on each figure of merit for the season
standards = FOREACH mod_seasons {
  OBP    = 1.0*(H + BB + HBP) / PA;
  SLG    = 1.0*(h1B + 2*h2B + 3*h3B + 4*HR) / AB;
  GENERATE
    player_id,
    (H   >=   180 ? 1 : 0) AS hi_H,
    (HR  >=    30 ? 1 : 0) AS hi_HR,
    (RBI >=   100 ? 1 : 0) AS hi_RBI,
    (OBP >= 0.400 ? 1 : 0) AS hi_OBP,
    (SLG >= 0.500 ? 1 : 0) AS hi_SLG
    ;
};

-- Count the seasons that pass the threshold by summing the indicator value
career_standards = FOREACH (GROUP standards BY player_id) GENERATE
    group AS player_id,
    COUNT_STAR(standards) AS n_seasons,
    SUM(standards.hi_H)   AS hi_H,
    SUM(standards.hi_HR)  AS hi_HR,
    SUM(standards.hi_RBI) AS hi_RBI,
    SUM(standards.hi_OBP) AS hi_OBP,
    SUM(standards.hi_SLG) AS hi_SLG
    ;

--
-- This isn't a terribly sophisticated analysis: the numbers were chosen to be
-- easy-to-remember, and not based on the data. Better bases for rigorous
-- comparison (we'll describe both later on) would be the z-score (REF) or
-- quantile (REF) figures. And yet, for the exploratory phase we prefer the
-- ad-hoc figures. A 0.400 OBP is a number you can hold in your hand and your
-- head; you can go click around
-- http://espn.go.com/mlb/stats/batting/_/sort/onBasePct/order/true[ESPN] and
-- see that it selects about the top 10-15 players in most seasons; you can use
-- paper-and-pencil to feed it to the run expectancy table (REF) we'll develop
-- later and see what it says a 0.400-on-base hitter would produce. We've shown
-- you how useful it is to identify exemplar records; learn to identify these
-- touchstone values as well.
--
-- Another example will help you see what we mean -- next, we'll use one GROUP
-- operation to summarize multiple subsets of a table at the same time.

-- ***************************************************************************
--
-- === Summarizing Multiple Subsets of a Group Simultaneously
--

--
-- We can use the summing trick to apply even more sophisticated aggregations to
-- conditional subsets. How did each player's career evolve -- a brief brilliant
-- flame? a rise to greatness? sustained quality? Let's classify a player's
-- seasons by whether they are "young" (age 21 and below), "prime" (22-29
-- inclusive) or "older" (30 and older). We can then tell the story of their
-- career by finding their OPS (our overall performance metric) both overall and
-- for the subsets of seasons in each age range footnote:[these breakpoints are
-- based on where www.fangraphs.com/blogs/how-do-star-hitters-age research by
-- fangraphs.com showed a performance drop-off by 10% from peak.].
--
-- The complication here over the previous exercise is that we are forming
-- compound aggregates on the group. To apply the formula `career SLG = (career
-- TB) / (career AB)`, we need to separately determine the career values for
-- `TB` and `AB` and then form the combined `SLG` statistic.
--
-- Project the numerator and denominator of each offensive stat into the field
-- for that age bucket. Only one of the subset fields will be filled in; as an
-- example, an age-25 season will have values for PA_all and PA_prime and zeros
-- for PA_young and PA_older.
--
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

--
-- After the group, we can sum across all the records to find the
-- plate-appearances-in-prime-seasons even though only some of the records
-- belong to the prime-seasons subset. The irrelevant seasons show a zero value
-- in the projected field and so don't contribute to the total.
--
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
    COUNT_STAR(age_seasons)   AS n_seasons,
    SUM(age_seasons.is_young) AS n_young,
    SUM(age_seasons.is_prime) AS n_prime,
    SUM(age_seasons.is_older) AS n_older
    ;
};

-- If you do a sort on the different OPS fields, you'll spot Ted Williams
-- (player ID willite01) as one of the top three young players, top three prime
-- players, and top three old players. He's pretty awesome.

-- ***************************************************************************
--
-- === Testing for Absence of a Value Within a Group
--

-- We don't need a trick to answer "which players have ever played for the Red
-- Sox" -- just select seasons with team id `BOS` and eliminate duplicate player
-- ids:

-- Players who were on the Red Sox at some time
onetime_sox_ids = FOREACH (FILTER bat_seasons BY (team_id == 'BOS')) GENERATE player_id;
onetime_sox     = DISTINCT onetime_sox_ids;

-- The summing trick is useful for the complement, "which players have _never_
-- played for the Red Sox?" You might think to repeat the above but filter for
-- `team_id != 'BOS'` instead, but what that gives you is "which players have
-- ever played for a non-Red Sox team?". The right approach is to generate a
-- field with the value `1` for a Red Sox season and the irrelevant value `0`
-- otherwise. The never-Sox are those with zeroes for every year.

player_soxness   = FOREACH bat_seasons GENERATE
  player_id, (team_id == 'BOS' ? 1 : 0) AS is_soxy;

player_soxness_g = FILTER (GROUP player_soxness BY player_id)
  BY MAX(is_soxy) == 0;

never_sox = FOREACH player_soxness_g GENERATE group AS player_id;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

career_standards = ORDER (FOREACH career_standards GENERATE
    player_id, (hi_H + hi_HR + hi_RBI + hi_OBP + hi_SLG) AS awesomeness, n_seasons..
  ) BY awesomeness DESC;
STORE_TABLE(career_standards, 'career_standards');

career_epochs = ORDER career_epochs BY OPS_all DESC, player_id;
STORE_TABLE(career_epochs, 'career_epochs');

STORE_TABLE(never_sox, 'never_sox');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

games = load_games();


-- ***************************************************************************
--
-- === Co-Grouping Records Across Tables by Common Key
--



-- ***************************************************************************
--
-- === Computing a Won-Loss Record
--

--
-- Using a COGROUP:
--

-- games:
-- (..., 2004, BAL, BOS, 5, 3, ...)
-- (..., 2004, BAL, BOS, 0, 7, ...)
-- (..., 2004, BOS, NYA, 4, 1, ...)
-- (..., 2004, CLE, BAL, 2, 1, ...)

home_games = FOREACH games GENERATE
  home_team_id AS team_id, year_id,
  (home_runs_ct > away_runs_ct ? 1 : 0) AS win,
  (home_runs_ct < away_runs_ct ? 1 : 0) AS loss
  ;
--   (BAL,2004,1,0)
--   (BAL,2004,0,1)
--   (BOS,2004,1,0)
--   (CLE,2004,1,0)

away_games = FOREACH games GENERATE
  away_team_id AS team_id, year_id,
  (home_runs_ct > away_runs_ct ? 0 : 1) AS win,
  (home_runs_ct < away_runs_ct ? 0 : 1) AS loss
  ;
--   (BOS,2004,0,1)
--   (BOS,2004,1,0)
--   (NYA,2004,0,1)
--   (BAL,2004,0,1)

team_games = COGROUP
  home_games BY (team_id, year_id),
  away_games BY (team_id, year_id)
  ;
--   (BAL,2004)  {(BAL,2004,1,0),(BAL,2004,0,1),...} {(BAL,2004,0,1),...}
--   (BOS,2004)  {(BOS,2004,1,0),(BOS,2004,1,0),...} {(BOS,2004,0,1),(BOS,2004,1,0),...})
--   ...

-- Recall that a GROUP operation produces records with two fields: the first
-- field is the grouping key, the second field is the bag of unchanged records
-- from the input table having that key.
--
-- The first field in a COGROUP operation is similarly the grouping key; the
-- second field is the bag of records from the leftmost-named table (home_games)
-- having that key; and the third field is the bag of records from the
-- next-named table (away_games) having that key. You can list as many tables in
-- the COGROUP statement as you like; their bags-of-records will be deposited in
-- the correspondingly subsequent slots of the output records.
--
-- The last step to forming the
--

team_yr_win_loss = FOREACH team_games {
  G           = COUNT_STAR(home_games) + COUNT_STAR(away_games);
  G_home      = COUNT_STAR(home_games);
  --
  home_wins   = SUM(home_games.win)
  home_losses = SUM(home_games.loss)
  --
  wins        = home_wins   + SUM(away_games.win);
  losses      = home_losses + SUM(away_games.loss);
  GENERATE group.team_id, group.year_id,
    G         AS G,         G_home AS G_home,
    wins      AS wins,      losses AS losses,
    home_wins AS home_wins, home_losses AS home_losses,
    ;
  };
--- (BOS,2004,162,81,98,64,0)






















-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- A bad alternate: UNION then GROUP
--

--
-- Don't do this:
--
-- all_games = UNION home_games, away_games;
-- team_games = GROUP all_games BY team_id;
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- A reasonable alternate: generate both halves with a FLATTEN
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
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

-- You will need to first generate the career stats by running
-- 06-structural_operations/b-summarizing_aggregate_statistics_of_a_group.pig
bat_careers = LOAD_RESULT('bat_careers');
peeps       = load_people();

-- ***************************************************************************
--
-- === Joining Records in a Table with Matching Records in Another (Inner Join)
--
-- // alternate title??: Matching Records Between Tables (Inner Join)

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Joining Records in a Table with Directly Matching Records from Another Table (Direct Inner Join)
--

-- There is a stereotypical picture in baseball of a "slugger": a big fat man
-- who comes to plate challenging your notion of what an athlete looks like, and
-- challenging the pitcher to prevent him from knocking the ball for multiple
-- bases (or at least far enough away to lumber up to first base). To examine
-- the correspondence from body type to ability to hit for power (i.e. high
-- SLG), we will need to join the `people` table (listing height and weight)
-- with their hitting stats.
--
--
--
fatness = FOREACH peeps GENERATE
  player_id, name_first, name_last,
  height_in, weight_lb;
-- lightly filter out players without statistically significant careers:
-- (1000 PA is about two seasons worth of regular play. (TODO check, and make choice uniform)
slugging_stats = FOREACH (FILTER bat_careers BY (PA > 1000))
  GENERATE player_id, SLG;

-- The syntax of the join statement itself shouldn't be much of a surprise:
slugging_fatness_join = JOIN
  fatness        BY player_id,
  slugging_stats BY player_id;

LIMIT slugging_fatness_join 20; DUMP @;
-- ...

-- Each output record from a JOIN simply consist of all the fields from the first table, in their original order, followed by the fields from a matching record in the second table, all in their original order. If you held up a piece of paper covering the right part of your screen you'd think you were looking at the original table.
-- (This is in contrast to the records from a COGROUP: records from each table become elements in a corresponding bag, and so we would use `parks.park_name` to get the values of the park_name field from the parks bag.
-- one thing you'll notice in the snippet is the notation `bat_careers::player_id`.

DESCRIBE slugging_fatness_join;
-- {...}

-- as a consequence of flattening records from the fatness table next to records from the slugging_stats table, the two tables each contribute a field named `player_id`. Although _we_ privately know that both fields have the same value, Pig is right to insist on an unambiguous reference. The schema helpfully carries a prefix on each field disambiguating its table of origin.

So having done the join, we finish by preparing the output:

FOREACH(JOIN fatness BY player_id, slugging_stats BY player_id) {
  BMI = ROUND_TO(703.0*weight_lb/(height_in*height_in),1) AS BMI;
  GENERATE bat_careers::player_id, name_first, name_last,
    SLG, height_in, weight_lb, BMI;
};

-- We added a field for BMI (Body Mass Index), a simple measure of body type found by diving a person's weight by their height squared (and, since we're stuck with english units, multiplying by 703 to convert to metric). Though BMI
-- can't distinguish between 180 pounds of muscle and 180 pounds of flab, it reasonably controls for weight-due-to-tallness vs weight-due-to-bulkiness:
-- beanpole Randy Johnson (6'10"/2.1m, 225lb/102kg) and pocket rocket Tim Raines (5'8"/1.7m, 160lb/73kb) both have a low BMI of 23; Babe Ruth (who in his later days was 6'2"/1.88m 260lb/118kb) and Cecil Fielder (of whom Bill James wrote "...his reported weight of 261 leaves unanswered the question of what he might weigh if he put his other foot on the scale") both have high BMIs well above 30 footnote:[The dataset we're using unfortunately only records players' weights at the start of their career, so you will see different values listed for Mr. Fielder and Mr. Ruth.]


-- ------
-- SELECT bat.player_id, peep.nameCommon, begYear,
--     peep.weight, peep.height,
--     703*peep.weight/(peep.height*peep.height) AS BMI, -- measure of body type
--     PA, OPS, ISO
--   FROM bat_career bat
--   JOIN people peep ON bat.player_id = peep.player_id
--   WHERE PA > 500 AND begYear > 1910
--   ORDER BY BMI DESC
--   ;
-- ------

-- === How a Join Works

So that you can effectively reason about the behavior of a JOIN, it's important that you have the following two-and-a-half ways to think about its operation: (a) as the equivalent of a COGROUP-and-FLATTEN; and (b) as the underlying map-reduce job it produces.

-- ==== A Join is a COGROUP+FLATTEN

-- ==== A Join is a Map/Reduce Job with a secondary sort on the Table Name

The way to perform a join in map-reduce is similarly a particular application of the COGROUP we stepped through above. Even still, we'll walk through it mostly on its own --

The mapper receives its set of input splits either from the bat_careers table or from the peep table and makes the appropriate transformations. Just as above (REF), the mapper knows which file it is receiving via either framework metadata or environment variable in Hadoop Streaming. The records it emits follow the COGROUP pattern: the join fields, anointed as the partition fields; then the index labeling the origin file, anointed as the secondary sort fields; then the remainder of the fields. So far this is just a transform (FOREACH) inlined into a cogroup.

------
mapper do
  self.processes_models
  config.partition_fields 1 # player_id
  config.sort_fields      2 # player_id, origin_key
RECORD_ORIGINS = [
  /bat_careers/ => ['A', Baseball::BatCareer],
  /players/     => ['B', Baseball::Player],
]
def set_record_origin!
  RECORD_ORIGINS.each do |origin_name_re, (origin_index, record_klass)|
    if config[:input_file]
      [@origin_key, @record_klass] = [origin_index, record_klass]
      return
    end
  end
  # no match, fail
  raise RuntimeError, "The input file name #{config[:input_file]} must match one of #{RECORD_ORIGINS.keys} so we can recognize how to handle it."
end
def start(*) set_record_origin! ; end
def recordize(vals) @record_klass.receive(vals)
def process(record)
  case record
  when CareerStats
    yield [rec.player_id, @origin_idx, rec.slg]
  when Player
    yield [rec.player_id, @origin_key, rec.height_in, rec.weight_lb]
  else raise "Impossible record type #{rec.class}"
  end
end
end

reducer do
  def gather_records(group, origin_key)
    records = []
    group.each do |*vals|
      if vals[1] != origin_key # We hit start of next table's keys
        group.shift(vals)      # put it back before Mom notices
        break                  # and stop gathering records
      end
      records << vals
    end
    return records
  end


  BMI_ENGLISH_TO_METRIC = 0.453592 / (0.0254 * 0.254)
  def bmi(ht, wt)
    BMI_ENGLISH_TO_METRIC * wt / (ht * ht)
  end

  def process_group(group)
    players = gather_records(group, 'A'
    # remainder are slugging stats
    group.each do |player_id, _, slg|
      players.each do |player_id,_, height_in, weight_lb|
        # Pig would output all the fields from the JOIN,
        # but we're inlining the follow-on FOREACH as well
        yield [player_id, slg, height_in, weight_lb, bmi(height_in, weight_lb)]
      end
    end
  end
end

-- TODO-qem should I show the version that has just the naked join-like output ie. All the fields from each table, not including the BMI, as per slugging_fatness_join? And if so do I show it as well or instead?

-- The output of the Join job will have one record for each discrete combination of A and B. As you will notice in our Wukong version of the Join, the secondary sort ensures that for each key the reducer receives all the records for table A strictly followed by all records for table B. We gather all the A records in to an array, then on each B record emit the A records stapled to the B records. All the A records have to be held in memory at the same time, while all the B records simply flutter by; this means that if you have two datasets of wildly different sizes or distribution, it is worth ensuring the Reducer receives the smaller group first. In map/reduce, the table with the largest number of records per key should be assigned the last-occurring field group label; in Pig, that table should be named last in the JOIN statement.
--

stats_and_fatness = FOREACH (JOIN fatness BY player_id, stats BY player_id)
  GENERATE fatness::player_id..BMI, stats::n_seasons..OPS;

STORE_TABLE(stats_and_fatness, 'stats_and_fatness');

-- ===== Exercise
--
-- Exercise: Explore the correspondence of weight, height and BMI to SLG using a
-- medium-data tool such as R, Pandas or Excel. Spoiler alert: the stereotypes
-- of the big fat slugger is quire true.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Disambiguating Field Names With `::`
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Handling Nulls in Joins
--

-- (add note) Joins on null values are dropped even when both are null. Filter nulls. (I can't come up with a good example of this)
-- (add note) in contrast, all elements with null in a group _will_ be grouped as null. This can be dangerous when large number of nulls: all go to same reducer

-- Other topics in JOIN-land:
--
-- * See advanced joins: bag left outer join from DataFu
-- * See advanced joins: Left outer join on three tables: http://datafu.incubator.apache.org/docs/datafu/guide/more-tips-and-tricks.html
-- * See Time-series: Range query using cross
-- * See Time-series: Range query using prefix and UDFs (the ip-to-geo example)
-- * See advanced joins: Sparse joins for filtering, with a HashMap (replicated)
-- * Out of scope: Bitmap index
-- * Out of scope: Bloom filter joins
-- * See time-series: Self-join for successive row differences
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

SET pig.auto.local.enabled true;

bat_seasons = load_bat_seasons();
park_teams  = load_park_teams();

-- ***************************************************************************
--
-- === Enumerating a Many-to-Many Relationship
--
-- In the previous examples there's been a direct pairing of each line in the
-- main table with the unique line from the other table that decorates it.
-- Therefore, there output had exactly the same number of rows as the larger
-- input table. When there are multiple records per key, however, the the output
-- will have one row for each _pairing_ of records from each table. A key with
-- two records from the left table and 3 records from the right table yields six
-- output records.

player_team_years = FOREACH bat_seasons GENERATE year_id, team_id, player_id;
park_team_years   = FOREACH park_teams  GENERATE year_id, team_id, park_id;

player_stadia = FOREACH (JOIN
  player_team_years BY (year_id, team_id),
  park_team_years   BY (year_id, team_id)
  ) GENERATE
  player_team_years::year_id AS year_id, player_team_years::team_id AS team_id,
  player_id,  park_id;

--
-- By consulting the Jobtracker counters (map input records vs reduce output
-- records) or by explicitly using Pig to count records, you'll see that the
-- 77939 batting_seasons became 80565 home stadium-player pairings. The
-- cross-product behavior didn't cause a big explosion in counts -- as opposed
-- to our next example, which will generate much more data.
--
bat_seasons_info   = FOREACH (GROUP bat_seasons   ALL) GENERATE 'batting seasons count', COUNT_STAR(bat_seasons)   AS ct;
player_stadia_info = FOREACH (GROUP player_stadia ALL) GENERATE 'player_stadia count',   COUNT_STAR(player_stadia) AS ct;

STORE_TABLE(player_stadia, 'player_stadia');
DUMP bat_seasons_info;
DUMP player_stadia_info;


IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
IMPORT 'summarizer_bot_9000.pig';

SET pig.auto.local.enabled true
  ;

bat_seasons = load_bat_seasons();
one_line    = load_one_line();

-- ***************************************************************************
--
-- === Joining a Table with Itself (self-join)
--

-- Joining a table with itself is very common when you are analyzing relationships of elements within the table (when analyzing graphs or working with datasets represented as attribute-value lists it becomes predominant.) Our example here will be to identify all teammates pairs: players listed as having played for the same team in the same year. The only annoying part about doing a self-join in Pig is that you can't, at least not directly. Pig won't let you list the same table in multiple slots of a JOIN statement, and also won't let you just write something like `"mytable_dup = mytable;"` to assign a new alias footnote:[If it didn't cause such a surprisingly hairy set of internal complications, it would have long ago been fixed]. Instead you have to use a FOREACH or somesuch to create a duplicate representative. If you don't have any other excuse, use a project-star expression: `p2 = FOREACH p1 GENERATE *;`. In this case, we already need to do a projection; we feel the most readable choice is to repeat the statement twice.

-- -- Pig disallows self-joins so this won't work:
-- wont_work = JOIN bat_seasons BY (team_id, year_id), bat_seasons BY (team_id, year_id);
-- "ERROR ... Pig does not accept same alias as input for JOIN operation : bat_seasons"

-- That's OK, we didn't want all those stupid fields anyway; we'll just make two copies.
p1 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;
    p2 = FOREACH bat_seasons GENERATE player_id, team_id, year_id;

--
-- Now we join the table copies to find all teammate pairs. We're going to say a player isn't their their own teammate, and so we also reject the self-pairs.
--

teammate_pairs = FOREACH (JOIN
    p1 BY (team_id, year_id),
    p2 by (team_id, year_id)
  ) GENERATE
    p1::player_id AS pl1,
    p2::player_id AS pl2;
teammate_pairs = FILTER teammate_pairs BY NOT (pl1 == pl2);

-- As opposed to the previous section's slight many-to-many expansion, there are on average ZZZ players per roster to be paired. The result set here is explosively larger: YYY pairings from the original XXX player seasons, an expansion of QQQ footnote:[See the example code for details]. Now you might have reasonably expected the expansion factor to be very close to the average number of players per team, thinking "QQQ average players per team, so QQQ times as many pairings as players." But a join creates as many rows as the product of the records in each tables' bag -- the square of the roster size in this case -- and the sum of the squares necessarily exceeds the direct sum.

-- The 78,000 player seasons we joined onto the team-parks-years table In
-- contrast, a similar JOIN expression turned 78,000 seasons into 2,292,658
-- player-player pairs, an expansion of nearly thirty times

teammates = FOREACH (GROUP teammate_pairs BY pl1) {
  mates = DISTINCT teammate_pairs.pl2;
  GENERATE group AS player_id,
    COUNT_STAR(mates) AS n_mates,
    BagToString(mates,';') AS mates;
  };
teammates = ORDER teammates BY n_mates ASC;

-- STORE_TABLE(teammates, 'teammates');
-- teammates = LOAD_RESULT('teammates');

-- (A simplification was made) footnote:[(or, what started as a footnote but should probably become a sidebar or section in the timeseries chapter -- QEM advice please) Our bat_seasons table ignores mid-season trades and only lists a single team the player played the most games for, so in infrequent cases this will identify some teammate pairs that didn't actually overlap. There's no simple option that lets you join on players' intervals of service on a team: joins must be based on testing key equality, and we would need an "overlaps" test. In the time-series chapter you'll meet tools for handling such cases, but it's a big jump in complexity for a small number of renegades. You'd be better off handling it by first listing every stint on a team for each player in a season, with separate fields for the year and for the start/end dates. Doing the self-join on the season (just as we have here) would then give you every _possible_ teammate pair, with some fraction of false pairings. Lastly, use a FILTER to reject the cases where they don't overlap. Any time you're looking at a situation where 5% of records are causing 150% of complexity, look to see whether this approach of "handle the regular case, then fix up the edge cases" can apply.]



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

stats_info    = FOREACH (GROUP p1 ALL) GENERATE
  COUNT_STAR(p1)             AS n_seasons;
tm_pair_info  = FOREACH (GROUP teammate_pairs ALL) GENERATE
  COUNT_STAR(teammate_pairs) AS n_mates_all;
teammate_info = FOREACH (GROUP teammates      ALL) GENERATE
  COUNT_STAR(teammates)      AS n_players,
  SUM(teammates.n_mates)     AS n_mates_dist;

roster_sizes  = FOREACH (GROUP p1 BY (team_id, year_id)) GENERATE COUNT_STAR(p1) AS n_players;

roster_info   = summarize_numeric(roster_sizes, 'n_players', 'ALL');

-- -- roster_info   = FOREACH (GROUP roster_sizes ALL) GENERATE
-- --   SUM(roster_sizes.n_players) AS n_players,
-- --   AVG(roster_sizes.n_players) AS roster_size_avg,
-- --   SQRT(VAR(roster_sizes.n_players)) AS roster_size_stdv,
-- --   MIN(roster_sizes.n_players) AS roster_size_min,
-- --   MAX(roster_sizes.n_players) AS roster_size_max;
--
-- --
-- -- The one_line.tsv table is a nice trick for accumulating several scalar
-- -- projections.
-- --
-- teammates_summary = FOREACH one_line GENERATE
--   -- 'n_players',   (long)teammate_info.n_players    AS n_players,
--   -- 'n_seasons',   (long)stats_info.n_seasons       AS n_seasons,
--   -- 'n_pairs',     (long)tm_pair_info.n_mates_all   AS n_mates_all,
--   -- 'n_teammates', (long)teammate_info.n_mates_dist AS n_mates_dist,
--   (long)roster_info.minval,
--   (long)roster_info.maxval,
--   (long)roster_info.avgval,
--   (long)roster_info.stddev
--   ;
-- STORE_TABLE(teammates_summary, 'teammates_summary');
-- cat $out_dir/teammates_summary/part-m-00000;
-- -- --
-- -- -- n_players       16151   n_seasons       77939   n_pairs 2292658 n_teammates     1520460
-- -- --
--
-- EXPLAIN teammates_summary;


-- teammate_pairs = FOREACH (JOIN
--     p1 BY (team_id, year_id),
--     p2 by (team_id, year_id)
--   ) GENERATE
--     p1::player_id AS pl1,        p2::player_id AS pl2,
--     p1::team_id   AS p1_team_id, p1::year_id   AS p1_year_id;
-- teammate_pairs = FILTER teammate_pairs BY NOT (pl1 == pl2);
--
-- teammates = FOREACH (GROUP teammate_pairs BY pl1) {
--   years = DISTINCT teammate_pairs.p1_year_id;
--   mates = DISTINCT teammate_pairs.pl2;
--   teams = DISTINCT teammate_pairs.p1_team_id;
--   GENERATE group AS player_id,
--     COUNT_STAR(mates) AS n_mates,    COUNT_STAR(years) AS n_seasons,
--     MIN(years)        AS beg_year,   MAX(years)        AS end_year,
--     BagToString(teams,';') AS teams,
--     BagToString(mates,';') AS mates;
--   };
--
-- teammates = ORDER teammates BY n_mates DESC;
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


-- If we prepare a histogram of career hits, similar to the one above for
-- seasons, you'll find that Pete Rose (4256 hits) and Ty Cobb (4189 hits) have
-- so many more hits than the third-most player (Hank Aaron, 3771 hits) there
-- are gaps in the output bins. To make it so that every bin has an entry, do an
-- outer join on the integer table. (See, we told you the integers table was
-- surprisingly useful.)

-- SET @H_binsize = 10;
-- SELECT bin, H, IFNULL(n_H,0)
--   FROM      (SELECT @H_binsize * idx AS bin FROM numbers WHERE idx <= 430) nums
--   LEFT JOIN (SELECT @H_binsize*CEIL(H/@H_binsize) AS H, COUNT(*) AS n_H
--     FROM bat_career bat GROUP BY H) hist
--   ON hist.H = nums.bin
--   ORDER BY bin DESC
-- ;


--
-- Regular old histogram of career hits, bin size 100
--
H_vals = FOREACH (GROUP bat_seasons BY player_id) GENERATE
  100*ROUND(SUM(bat_seasons.H)/100.0) AS bin;
H_hist_0 = FOREACH (GROUP H_vals BY bin) GENERATE
  group AS bin, COUNT_STAR(H_vals) AS ct;

--
-- Generate a list of all the bins we want to keep.
--
H_bins = FOREACH (FILTER numbers_10k BY num0 <= 43) GENERATE 100*num0  AS bin;

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
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_tm_yr();

-- NOTE move this after the self-join and many-to-many joins.

-- ***************************************************************************
--
-- === Joining Records Without Discarding Non-Matches (Outer Join)
--
-- QEM: needs prose (perhaps able to draw from prose file)

-- The Baseball Hall of Fame is meant to honor the very best in the game, and each year a very small number of players are added to its rolls. It's a significantly subjective indicator, which is its cardinal virtue and its cardinal flaw -- it represents the consensus judgement of experts, but colored to some small extent by emotion, nostalgia, and imperfect quantitative measures. But as you'll see over and over again, the best basis for decisions is the judgement of human experts backed by data-driven analysis. What we're assembling as we go along this tour of analytic patterns isn't a mathematical answer to who the highest performers are, it's a basis for centering discussion around the right mixture of objective measures based on evidence and human judgement where the data is imperfect.

-- So we'd like to augment the career stats table we assembled earlier with columns showing, for hall-of-famers, the year they were admitted, and a `Null` value for the rest. (This allows that column to also serve as a boolean indicator of whether the players were inducted). If you tried to use the JOIN operator in the form we have been, you'll find that it doesn't work. A plain JOIN operation keeps only rows that have a match in all tables, and so all of the non-hall-of-famers will be excluded from the result. (This differs from COGROUP, which retains rows even when some of its inputs lack a match for a key). The answer is to use an 'outer join'

-- (Import prose)

career_stats = FOREACH (
  JOIN
    bat_careers BY player_id LEFT OUTER,
    batting_hof BY player_id) GENERATE
  bat_careers::player_id..bat_careers::OPS, allstars::year_id AS hof_year;

-- Since the batting_hof table has exactly one row per player, the output has exactly as many rows as the career stats table, and exactly as many non-null rows as the hall of fame table.
--
-- footnote:[Please note that the `batting_hof` table excludes players admitted to the Hall of Fame based on their pitching record. With the exception of Babe Ruth -- who would likely have made the Hall of Fame as a pitcher if he hadn't been the most dominant hitter of all time -- most pitchers have very poor offensive skills and so are relegated back with the rest of the crowd]

-- -- (sample data)
-- -- (Hank Aaron)... Year

-- (Code to count records)

-- In this example, there will be some parks that have no direct match to location names and, of course, there will be many, many places that do not match a park. The first two JOINs we did were "inner" JOINs -- the output contains only rows that found a match. In this case, we want to keep all the parks, even if no places matched but we do not want to keep any places that lack a park. Since all rows from the left (first most dataset) will be retained, this is called a "left outer" JOIN. If, instead, we were trying to annotate all places with such parks as could be matched -- producing exactly one output row per place -- we would use a "right outer" JOIN instead. If we wanted to do the latter but (somewhat inefficiently) flag parks that failed to find a match, you would use a "full outer" JOIN. (Full JOINs are pretty rare.)
--
-- TODO: discuss use of left join for set intersection.
--
-- In a Pig JOIN it is important to order the tables by size -- putting the smallest table first and the largest table last. (You'll learn why in the "Map/Reduce Patterns" (TODO:  REF) chapter.) So while a right join is not terribly common in traditional SQL, it's quite valuable in Pig. If you look back at the previous examples, you will see we took care to always put the smaller table first. For small tables or tables of similar size, it is not a big deal -- but in some cases, it can have a huge impact, so get in the habit of always following this best practice.
--
-- ------
-- NOTE
-- A Pig join is outwardly similar to the join portion of a SQL SELECT statement, but notice that  although you can place simple expressions in the join expression, you can make no further manipulations to the data whatsoever in that statement. Pig's design philosophy is that each statement corresponds to a specific data transformation, making it very easy to reason about how the script will run; this makes the typical Pig script more long-winded than corresponding SQL statements but clearer for both human and robot to understand.
-- ------

-- (Note about join on null keys)
--
-- (Note about left-right and placement within the statement)

-- ==== Joining Tables that do not have a Foreign-Key Relationship

-- All of the joins we've done so far have been on nice clean values designed in advance to match records among tables. In SQL parlance, the career_stats and batting_hof tables both had player_id as a primary key (a column of unique, non-null values tied to each record's identity). The team_id field in the bat_seasons and park_team_years tables points into the teams table as a foreign key: an indexable column whose only values are primary keys in another table, and which may have nulls or duplicates. But sometimes you must match records among tables that do not have a polished mapping of values. In that case, it can be useful to use an outer join as the first pass to unify what records you can before you bring out the brass knuckles or big guns for what remains.

-- Suppose we wanted to plot where each major-league player grew up -- perhaps as an answer in itself as a browsable map, or to allocate territories for talent scouts, or to see whether the quiet wide spaces of country living or the fast competition of growing up in the city better fosters the future career of a high performer. While the people table lists the city, state and country of birth for most players, we must geolocate those place names -- determine their longitude and latitude -- in order to plot or analyze them.

-- There are geolocation services on the web, but they are imperfect, rate-limited and costly for commercial use footnote:[Put another way, "Accurate, cheap, fast: choose any two]. Meanwhile the freely-available geonames database gives geo-coordinates and other information on more than seven million points of interest across the globe, so for informal work it can make a lot of sense to opportunistically decorate whatever records match and then decide what to do with the rest.

geolocated_somewhat = JOIN
  people BY (birth_city, birth_state, birth_country),
  places BY (city, admin_1, country_id)

-- In the important sense, this worked quite well: XXX% of records found a match.
-- (Question do we talk about the problems of multiple matches on name here, or do we quietly handle it?)

--
-- Experienced database hands might now suggest doing a join using some sort of fuzzy-match
-- match or some sort of other fuzzy equality. However, in map-reduce the only kind of join you can do is an "equi-join" -- one that uses key equality to match records. Unless an operation is 'transitive' -- that is, unless `a joinsto b` and `b joinsto c` guarantees `a joinsto c`, a plain join won't work, which rules out approximate string matches; joins on range criteria (where keys are related through inequalities (x < y)); graph distance; geographic nearness; and edit distance. You also can't use a plain join on an 'OR' condition: "match stadiums and places if the placename and state are equal or the city and state are equal", "match records if the postal code from table A matches any of the component zip codes of place B". Much of the middle part of this book centers on what to do when there _is_ a clear way to group related records in context, but which is more complicated than key equality.

-- exercise: are either city dwellers or country folk over-represented among major leaguers? Selecting only places with very high or very low population in the geonames table might serve as a sufficient measure of urban-ness; or you could use census data and the methods we cover in the geographic data analysis chapter to form a more nuanced indicator. The hard part will be to baseline the data for population: the question is how the urban vs rural proportion of ballplayers compares to the proportion of the general populace, but that distribution has changed dramatically over our period of interest. The US has seen a steady increase from a rural majority pre-1920 to a four-fifths majority of city dwellers today.

IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
allstars    = load_allstars();

-- ***************************************************************************
--
-- === Selecting Records With No Match in Another Table (anti-join)
--
-- QEM: needs prose (perhaps able to draw from prose file)

-- Project just the fields we need
allstars_p  = FOREACH allstars GENERATE player_id, year_id;

-- An outer join of the two will leave both matches and non-matches.
scrub_seasons_jn = JOIN
  bat_seasons BY (player_id, year_id) LEFT OUTER,
  allstars_p  BY (player_id, year_id);

-- ...and the non-matches will have Nulls in all the allstars slots
scrub_seasons_jn_f = FILTER scrub_seasons_jn
  BY allstars_p::player_id IS NULL;

-- Once the matches have been eliminated, pick off the first table's fields.
-- The double-colon in 'bat_seasons::' makes clear which table's field we mean.
-- The fieldname-ellipsis 'bat_seasons::player_id..bat_seasons::RBI' selects all
-- the fields in bat_seasons from player_id to RBI, which is to say all of them.
scrub_seasons_jn   = FOREACH scrub_seasons_jn_f
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
-- (this part appears in book following the semi-join)

-- Players with no entry in the allstars_p table have an empty allstars_p bag
bats_ast_cg = COGROUP
  bat_seasons BY (player_id, year_id),
  allstars_p BY (player_id, year_id);

-- Select all cogrouped rows where there were no all-star records, and project
-- the batting table fields.
scrub_seasons_cg = FOREACH
  (FILTER bats_ast_cg BY (COUNT_STAR(allstars_p) == 0L))
  GENERATE FLATTEN(bat_seasons);

-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(scrub_seasons_jn, 'scrub_seasons_jn');
STORE_TABLE(scrub_seasons_cg, 'scrub_seasons_cg');

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
--   `allstars` and not `allstars_p`, you'll see that the extra fields are
--   present. The other way is to look at how much data comes to the reducer
--   with and without the projection. If there is less data using `allstars_p`
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

bat_seasons = load_bat_seasons();
allstars    = load_allstars();

-- ***************************************************************************
--
-- === Selecting Records Having a Match in Another Table (semi-join)
--

-- Semi-join: just care about the match, don't keep joined table; anti-join is where you keep the non-matches and also don't keep the joined table. Again, use left or right so that the small table occurs first in the list. Note that a semi-join has only one row per row in dominant table -- so needs to be a cogroup and sum or a join to distinct'ed table (extra reduce, but lets you do a fragment replicate join.)
--
-- Select player seasons where they made the all-star team.
-- You might think you could do this with a join:
--
-- ------
--   -- Don't do this... produces duplicates!
-- bats_g    = JOIN allstar BY (player_id, year_id), bats BY (player_id, year_id);
-- bats_as   = FOREACH bats_g GENERATE bats::player_id .. bats::HR;
-- ------

-- The result is wrong, and even a diligent spot-check will probably fail to
-- notice. You see, from 1959-1962 there were multiple All-Star games (!), and
-- so each singular row in the `bat_season` table became two rows in the result
-- for players in those years.


-- Project just the fields we need allstars_p = FOREACH allstars GENERATE
player_id, year_id;

--
-- !!! Don't use a join for this !!!
-- QEM: needs prose (perhaps able to draw from prose file)
--
-- From 1959-1962 there were _two_ all-star games, and so the allstar table has multiple entries;
-- this means that players will appear twice in the results!
--
-- Will not work: look for multiple duplicated rows in the 1959-1962 years
allstar_seasons_broken_j = JOIN
  bat_seasons BY (player_id, year_id) LEFT OUTER,
  allstars_p  BY (player_id, year_id);
allstar_seasons_broken   = FILTER allstar_seasons_broken_j
  BY allstars_p::player_id IS NOT NULL;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Instead, in this case you must use a COGROUP.
--

-- Players with no entry in the allstars_p table have an empty allstars_p bag
allstar_seasons_cg = COGROUP
  bat_seasons BY (player_id, year_id),
  allstars_p BY (player_id, year_id);

-- Select all cogrouped rows where there was an all-star record
-- Project the batting table fields.
--
-- One row in the batting table => One row in the result
allstar_seasons_cg = FOREACH
  (FILTER allstar_seasons_cg BY (COUNT_STAR(allstars_p) > 0L))
  GENERATE FLATTEN(bat_seasons);


-- -- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
STORE_TABLE(allstar_seasons_jn, 'allstar_seasons_jn');
STORE_TABLE(allstar_seasons_cg, 'allstar_seasons_cg');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

--
-- SET opt.multiquery            false;

-- Run the script 'f-summarizing_multiple_subsets_simultaneously.pig' beforehand
-- to get career stats broken up into young (age 21 and below), prime (22 to 29
-- inclusive), and older (30 and over).
--
career_epochs = LOAD_RESULT('career_epochs');

-- ***************************************************************************
--
-- === Sorting All Records in Total Order

-- We're only going to look at players able to make solid contributions over
-- several years, which we'll define as playing for five or more seasons and
-- 2000 or more plate appearances (enough to show statistical significance), and
-- a OPS of 0.650 (an acceptable-but-not-allstar level) or better.
career_epochs = FILTER career_epochs BY
  ((PA_all >= 2000) AND (n_seasons >= 5) AND (OPS_all >= 0.650));

career_young = ORDER career_epochs BY OPS_young DESC;
career_prime = ORDER career_epochs BY OPS_prime DESC;
career_older = ORDER career_epochs BY OPS_older DESC;

-- You'll spot Ted Williams (willite01) as one of the top three young players,
-- top three prime players, and top three old players. Ted Williams was pretty
-- awesome.
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Sorting by Multiple Fields
--

-- Sorting on Multiple fields is as easy as adding them in order with commas.
-- Sort by number of older seasons, breaking ties by number of prime seasons:
--
career_older = ORDER career_epochs
  BY n_older DESC, n_prime DESC;

-- Whereever reasonable, "stabilize" your sorts by adding enough columns to make
-- the ordering unique. This ensures the output will remain the same from run to
-- run, a best practice for testing and maintainability.
--
career_older = ORDER career_epochs
  BY n_older DESC, n_prime DESC, player_id ASC; -- makes sure that ties are always broken the same way.

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Sorting on an Expression (You Can't)
--

-- Which players have aged the best -- made the biggest leap in performance from
-- their prime years to their older years? You might thing the following would
-- work, but you cannot use an expression in an `ORDER..BY` statement:
--
-- -- by_diff_older = ORDER career_epochs BY (OPS_older-OPS_prime) DESC; -- fails!
--
-- Instead, generate a new field, sort on it, then project it away. Though it's
-- cumbersome to type, there's no significant performance impact.
by_diff_older = FOREACH career_epochs
  GENERATE OPS_older - OPS_prime AS diff, player_id..;
by_diff_older = FOREACH (ORDER by_diff_older BY diff DESC, player_id)
  GENERATE player_id..;

-- If you browse through that table, you'll get a sense that current-era players
-- seem to be over-represented. This is just a simple whiff of a question, but
-- http://j.mp/bd4c-baseball_age_vs_performance[more nuanced analyses] do show
-- an increase in longevity of peak performance.  Part of that is due to better
-- training, nutrition, and medical care -- and part of that is likely due to
-- systemic abuse of performance-enhancing drugs.
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Sorting Case-insensitive Strings
--

dict        = LOAD '/usr/share/dict/words' AS (word:chararray);

-- There's no intrinsic way to sort case-insensitive; instead, just force a
-- lower-case field to sort with:

sortable    = FOREACH dict GENERATE LOWER(word) AS key, *;
dict_nocase = FOREACH (ORDER sortable BY key DESC, word) GENERATE word;
zzz_nocase  = LIMIT dict_nocase 200;
--
dict_case   = ORDER dict BY word DESC;
zzz_case    = LIMIT dict_case   200;


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Dealing with Nulls When Sorting
--

-- When the sort field has nulls, Pig sorts them as least-most by default: they
-- will appear as the first rows for `DESC` order and as the last rows for `ASC`
-- order. To float Nulls to the front or back, project a dummy field having the
-- favoritism you want to impose, and name it first in the `ORDER..BY` clause.
--
nulls_sort_demo = FOREACH career_epochs
  GENERATE (OPS_older IS NULL ? 0 : 1) AS has_older_epoch, player_id..;

nulls_then_vals = FOREACH (ORDER nulls_sort_demo BY
  has_older_epoch ASC,  OPS_all DESC, player_id)
  GENERATE player_id..;

vals_then_nulls = FOREACH (ORDER nulls_sort_demo BY
  has_older_epoch DESC, OPS_all DESC, player_id)
  GENERATE player_id..;

-- ==== Floating Values to the Top or Bottom of the Sort Order
--
-- Use the dummy field trick any time you want to float records to the top or
-- bottom of the sort order based on a criterion. This moves all players whose
-- careers start in 1985 or later to the top, but otherwise sorts on number of
-- older seasons:

post1985_vs_earlier = FOREACH career_epochs
  GENERATE (beg_year >= 1985 ? 1 : 0) AS is_1985, player_id..;
post1985_vs_earlier = FOREACH (ORDER post1985_vs_earlier BY is_1985 DESC, n_older DESC, player_id)
  GENERATE player_id..;

STORE_TABLE(career_young, 'career_young');
STORE_TABLE(career_prime, 'career_prime');
STORE_TABLE(career_older, 'career_older');
--
STORE_TABLE(post1985_vs_earlier, 'post1985_vs_earlier');
STORE_TABLE(nulls_then_vals, 'nulls_then_vals');
STORE_TABLE(vals_then_nulls, 'vals_then_nulls');
--
STORE_TABLE(zzz_nocase, 'zzz_nocase');
STORE_TABLE(zzz_case,   'zzz_case');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Sorting Records within a Group

-- This operation is straightforward enough and so useful we've been applying it
-- all this chapter, but it's time to be properly introduced and clarify a
-- couple points.
--
-- Sort records within a group using ORDER BY within a nested FOREACH. Here's a
-- snippet to list the top four players for each team-season, in decreasing
-- order by plate appearances.
--
players_PA = FOREACH bat_seasons GENERATE team_id, year_id, player_id, name_first, name_last, PA;
team_playerslist_by_PA = FOREACH (GROUP players_PA BY (team_id, year_id)) {
  players_o_1 = ORDER players_PA BY PA DESC, player_id;
  players_o = LIMIT players_o_1 4;
  GENERATE group.team_id, group.year_id,
    players_o.(player_id, name_first, name_last, PA) AS players_o;
};
--
-- Ordering a group in the nested block immediately following a structural
-- operation does not require extra operations, since Pig is able to simply
-- specify those fields as secondary sort keys. Basically, as long as it happens
-- first in the reduce operation it's free (though if you're nervous, look for
-- the line "Secondary sort: true" in the output of EXPLAIN). Messing with a bag
-- before the `ORDER..BY` causes Pig to instead sort it in-memory using
-- quicksort, but will not cause another map-reduce job. That's good news unless
-- some bags are so huge they challenge available RAM or CPU, which won't be
-- subtle.
--
-- If you depend on having a certain sorting, specify it explicitly, even when
-- you notice that a `GROUP..BY` or some other operation seems to leave it in
-- that desired order. It gives a valuable signal to anyone reading your code,
-- and a necessary defense against some future optimization deranging that order
-- footnote:[That's not too hypothetical: there are cases where you could more
-- efficiently group by binning the items directly in a Map rather than sorting]
--
-- Once sorted, the bag's order is preserved by projections, by most functions
-- that iterate over a bag, and by the nested pipeline operations FILTER,
-- FOREACH, and LIMIT. The return values of nested structural operations CROSS,
-- ORDER..BY and DISTINCT do not follow the same order as their input; neither
-- do structural functions such as CountEach (in-bag histogram) or the set
-- operations (REF) described at the end of the chapter. (Note that though their
-- outputs are dis-arranged these of course don't mess with the order of their
-- inputs: everything in Pig is immutable once created.)
--
team_playerslist_by_PA_2 = FOREACH team_playerslist_by_PA {
  -- will not have same order, even though contents will be identical
  disordered    = DISTINCT players_o;
  -- this ORDER BY does _not_ come for free, though it's not terribly costly
  alt_order     = ORDER players_o BY player_id;
  -- these are all iterative and so will share the same order of descending PA
  still_ordered = FILTER players_o BY PA > 10;
  pa_only       = players_o.PA;
  pretty        = FOREACH players_o GENERATE
    CONCAT((chararray)PA, ':', name_first, ' ', name_last);
  GENERATE team_id, year_id,
    disordered, alt_order,
    still_ordered, pa_only, BagToString(pretty, '|');
};

-- Notice the lines 'Global sort: false // Secondary sort: true' in the explain output
EXPLAIN team_playerslist_by_PA_2;
STORE_TABLE(team_playerslist_by_PA_2, 'team_playerslist_by_PA_2');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

vals = LOAD 'us_city_pops.tsv' USING PigStorage('\t', '-tagMetadata')
  AS (metadata:map[], city:chararray, state:chararray, pop:int);

-- === Shuffle all Records in a Table
-- ==== Shuffle all Records in a Table Consistently

-- QEM: needs prose (perhaps able to draw from prose file)

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
--

-- If you supply only the name of the table, RANK acts as a pipeline operation, introducing no extra map/reduce stage. Each split is numbered as a unit: the third line of chunk `part-00000` gets rank 2, the third line of chunk `part-00001` gets rank 2, and so on.


-- When you give rank a field to act on, it




-- It's important to know that in current versions of Pig, the RANK operator sets parallelism one,
-- forcing all data to a single reducer. If your data is unacceptably large for this, you can use the method used in (REF) "Assigning a unique identifier to each line" to get a unique compound index that matches the total ordering, which might meet your needs. Otherwise, we can offer you no good workaround -- frankly your best option may be to pay someone to fix this

-- gift                 RANK       RANK gift    RANK gift DENSE
-- partridge            1          1            1
-- turtle dove          2          2            2
-- turtle dove          3          2            2
-- french hen           4          3            4
-- french hen           5          3            4
-- french hen           6          3            4
-- calling birds        7          4            7
-- calling birds        8          4            7
-- calling birds        9          4            7
-- calling birds       10          4            7
-- K golden rings      11          5           11


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


IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';
bat_seasons = load_bat_seasons();

-- -- You may need to disable partial aggregation in current versions of Pig.
-- SET pig.exec.mapPartAgg  false
-- Disabling multiquery just so we judge jobs independently
SET opt.multiquery          false
SET pig.exec.mapPartAgg.minReduction  8
;

DEFINE LastEventInBag org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('2', 'max');

-- === Selecting Records Associated with Maximum Values

-- As we learned at the start of the chapter, you can retrieve the maximum and
-- minimum values for a field using the `MAX(bag)` and `MIN(bag)` functions
-- respectively. These have no memory overhead to speak of and are efficient for
-- both bags within groups and for a full table with `GROUP..ALL`. (By the way:
-- from here out we're just going to talk about maxima -- unless we say
-- otherwise everything applies for minimums by substituting the word 'minimum'
-- or reversing the sort order as appropriate.)
--
-- But if you want to retrieve the record associated with a maximum value (this
-- section), or retrieve multiple values (the followin section), you will need a
-- different approach.

-- ==== Selecting a Single Maximal Record Within a Group, Ignoring Ties

-- events = LOAD '$data_dir/sports/baseball/events_evid' AS (
--   game_id:chararray, event_seq:int,
--   event_id: chararray, -- extra field we made for demonstration purposes
--   year_id:int,
--   game_date:chararray, game_seq:int, away_team_id:chararray,
--   home_team_id:chararray, inn:int, inn_home:int, beg_outs_ct:int,
--   away_score:int, home_score:int, event_desc:chararray, event_cd:int,
--   hit_cd:int, ev_outs_ct:int, ev_runs_ct:int, bat_dest:int, run1_dest:int,
--   run2_dest:int, run3_dest:int, is_end_bat:int, is_end_inn:int, is_end_game:int,
--   bat_team_id:chararray, fld_team_id:chararray, pit_id:chararray,
--   bat_id:chararray, run1_id:chararray, run2_id:chararray, run3_id:chararray
--   );
events = load_events();

-- events_most_runs = LIMIT (ORDER events BY ev_runs_ct DESC) 40;
--

events_most_runs_g = FOREACH (GROUP events ALL)
  GENERATE FLATTEN(TOP(40, 16, events));

-- Final event of the game footnote:[For the purposes of a good demonstration,
-- we're ignoring the fact that the table actually has a boolean flag identifying
-- that event]
--
events_final_event_top = FOREACH (GROUP events BY game_id)
  GENERATE FLATTEN(TOP(1, 1, events));

events_final_event_lastinbag = FOREACH (GROUP events BY game_id)
  GENERATE FLATTEN(LastEventInBag(events));

events_final_event_orderlimit = FOREACH (GROUP events BY game_id) {
  events_o = ORDER events BY event_seq DESC;
  events_last = LIMIT events_o 1;
  GENERATE FLATTEN(events_last);
  };

events_final_event_orderfirst = FOREACH (GROUP events BY game_id) {
  events_o = ORDER events BY event_seq DESC;
  GENERATE FLATTEN(FirstTupleFromBag(events_o, ('')));
  };


--
-- If you'll pardon a nonsensical question,
--
nonsense_final_event = FOREACH (GROUP events BY event_desc)
  GENERATE FLATTEN(LastEventInBag(events));

-- For example, we may want to identify the team each player spent the most
-- games with. Right from the start you have to decide how to handle ties. In
-- this case, you're probably looking for a _single_ primary team; the cases
-- where a player had exactly the same number of games for two teams is not
-- worth the hassle of turning a single-valued field into a collection.
--
-- That decision simplifies our

-- -- -- How we made the events_evid table:
-- events = load_events();
-- events_evid = FOREACH events GENERATE game_id, event_seq, SPRINTF('%s-%03d', game_id, event_seq) AS event_id, year_id..;
-- STORE events_evid INTO '$data_dir/sports/baseball/events_evid';

-- ORDER BY on a full table: N
--

-- Consulting the jobtracker console for the events_final_event_1 job shows
-- combine input records: 124205; combine output records: 124169 That's a pretty
-- poor showing. We know something pig doesn't: since all the events for a game
-- are adjacent in the file, the maximal record chosen by each mapper is almost
-- certainly the overall maximal record for that group.
--
-- Running it again with `SET pig.exec.nocombiner true` improved
-- the run time dramatically.
--
-- In contrast, if we

-- events = load_events();
-- events_evid = FOREACH events GENERATE game_id, event_seq, SPRINTF('%s-%03d', game_id, event_seq) AS event_id, year_id..;
-- team_season_final_event = FOREACH (GROUP events BY (home_team_id, year_id))
--   GENERATE FLATTEN(TOP(1, 2, events));

team_season_final_event = FOREACH (GROUP events BY (home_team_id, year_id)) {
  evs = FOREACH events GENERATE (game_id, event_seq) AS ev_id, *;
  GENERATE FLATTEN(TOP(1, 0, evs));
};

-- SET pig.cachedbag.memusage       0.10
-- SET pig.spill.size.threshold       20100100
-- SET pig.spill.gc.activation.size 9100100100
-- -- ;

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

-- SELECT bat.player_id, bat.year_id, bat.team_id, MAX(batmax.Gmax), MAX(batmax.stints), MAX(team_ids), MAX(Gs)
--   FROM       batting bat
--   INNER JOIN (SELECT player_id, year_id, COUNT(*) AS stints, MAX(G) AS Gmax, GROUP_CONCAT(team_id) AS team_ids, GROUP_CONCAT(G) AS Gs FROM batting bat GROUP BY player_id, year_id) batmax
--   ON bat.player_id = batmax.player_id AND bat.year_id = batmax.year_id AND bat.G = batmax.Gmax
--   GROUP BY player_id, year_id
--   -- WHERE stints > 1
--   ;
--
-- -- About 7% of seasons have more than one stint; only about 2% of seasons have
-- -- more than one stint and more than a half-season's worth of games
-- SELECT COUNT(*), SUM(mt1stint), SUM(mt1stint)/COUNT(*) FROM (SELECT player_id, year_id, IF(COUNT(*) > 1 AND SUM(G) > 77, 1, 0) AS mt1stint FROM batting GROUP BY player_id, year_id) bat
--
-- --
-- -- Earlier in the chapter we annotated each player's season by whether they were
-- -- the league leader in Home Runs (HR):
--
-- bats_with_max_hr = FOREACH (GROUP bat_seasons BY year_id) GENERATE
--   MAX(bat_seasons.HR) as max_HR,
--   FLATTEN(bat_seasons);
--
-- -- Find the desired result:
-- bats_with_l_cg = FOREACH bats_with_max_hr GENERATE
--   player_id.., (HR == max_HR ? 1 : 0);
-- bats_with_l_cg = ORDER bats_with_l_cg BY player_id, year_id;
--
--
-- -- We can also do this using a join:
--
-- -- Find the max_HR for each season
-- HR_by_year     = FOREACH bat_seasons GENERATE year_id, HR;
-- max_HR_by_year = FOREACH (GROUP HR_by_year BY year_id) GENERATE
--   group AS year_id, MAX(HR_by_year.HR) AS max_HR;
--
-- -- Join it with the original table to put records in full-season context:
-- bats_with_max_hr_jn = JOIN
--   bat_seasons    BY year_id, -- large table comes *first* in a replicated join
--   max_HR_by_year BY year_id  USING 'replicated';
-- -- Find the desired result:
-- bats_with_l_jn = FOREACH bats_with_max_hr_jn GENERATE
--   player_id..RBI, (HR == max_HR ? 1 : 0);
--
-- -- The COGROUP version has only one reduce step, but it requires sending the
-- -- full contents of the table to the reducer: its cost is two full-table scans
-- -- and one full-table group+sort. The JOIN version first requires effectively
-- -- that same group step, but with only the group key and the field of interest
-- -- sent to the reducer. It then requires a JOIN step to bring the records into
-- -- context, and a final pass to use it. If we can use a replicated join, the
-- -- cost is a full-table scan and a fractional group+sort for preparing the list,
-- -- plus two full-table scans for the replicated join. If we can't use a
-- -- replicated join, the cogroup version is undoubtedly superior.
-- --
-- -- So if a replicated join is possible, and the projected table is much smaller
-- -- than the original, go with the join version. However, if you are going to
-- -- decorate with multiple aggregations, or if the projected table is large, use
-- -- the GROUP/DECORATE/FLATTEN pattern.


-- STORE_TABLE(bats_with_l_cg, 'bats_with_l_cg');
-- STORE_TABLE(bats_with_l_jn, 'bats_with_l_jn');


-- STORE_TABLE(events_most_runs,              'events_most_runs');
-- STORE_TABLE(events_most_runs_g,            'events_most_runs_g');
-- STORE_TABLE(events_final_event_top,        'events_final_event_top');
-- STORE_TABLE(events_final_event_lastinbag,  'events_final_event_lastinbag');
-- STORE_TABLE(events_final_event_orderlimit, 'events_final_event_orderlimit');
-- STORE_TABLE(events_final_event_orderfirst, 'events_final_event_orderfirst');
-- STORE_TABLE(nonsense_final_event,             'nonsense_final_event');
-- STORE_TABLE(team_season_final_event,       'team_season_final_event');
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

%DEFAULT topk_window 60
%DEFAULT topk        40
DEFINE IOver                  org.apache.pig.piggybank.evaluation.Over('int');


H_seasons = FOREACH bat_seasons GENERATE
  H, year_id, player_id;
H_seasons = FILTER H_seasons BY year_id >= 2000;

top_H_season_c = FOREACH (GROUP H_seasons BY year_id) {
  candidates = TOP(25, 0, H_seasons.(H, player_id));
  GENERATE group AS year_id, candidates AS candidates;
};

top_H_season_r = FOREACH top_H_season_c {
  candidates_o = ORDER candidates BY H DESC;
  ranked = Stitch(IOver(candidates_o, 'rank', -1, 0, 0), candidates_o); -- from first (-1) to last (-1), rank on H (0th field)
  is_ok = AssertUDF((MAX(ranked.result) > 10 ? 1 : 0),
    'All candidates for topk were accepted, so we cannot be sure that all candidates were found');
  GENERATE year_id, ranked AS candidates:bag{t:(rk:int, H:int, player_id:chararray)}, is_ok;
};

top_H_season = FOREACH top_H_season_r {
  topk = FILTER candidates BY rk <= 10;
  topk_str = FOREACH topk GENERATE SPRINTF('%2d %3d %-9s', rk, H, player_id) AS str;
  GENERATE year_id, MIN(topk.H), MIN(candidates.H), BagToString(topk_str, ' | ');
};

-- top_H_season_groupie = FOREACH (GROUP H_seasons BY year_id) {
--   candidates = TOP(25, 0, H_seasons.(H, player_id));
--   topk       = TOP(10, 0, H_seasons.H);
--   GENERATE
--     group AS year_id,
--     MIN(topk) AS topk_threshold,
--     FLATTEN(candidates) AS (H:int, player_id:chararray);
-- };
-- top_H_season_groupie = GROUP (FILTER top_H_season_groupie BY H >= topk_threshold) BY year_id;

DESCRIBE top_H_season_c;
DESCRIBE top_H_season_r;
DESCRIBE top_H_season;

DUMP     top_H_season;
-- DUMP     top_H_season_groupie;
-- STORE_TABLE(top_H_season, 'top_H_season');
-- STORE_TABLE(t2, 't2');


-- DEFINE MostHits org.apache.pig.piggybank.evaluation.ExtremalTupleByNthField('1', 'max');
-- top_H_season = FOREACH (GROUP H_seasons BY year_id) {
--   top_k     = TOP(10, 0, H_seasons);
--   top_1     = MostHits(H_seasons);
--   top_1_bag = TOP(1,  0, H_seasons);
--   GENERATE
--     group                 AS year_id,
--     MAX(top_k.H)         AS max_H,
--     -- FLATTEN(top_1.H)      AS max_H_2,
--     -- top_1_bag.H           AS max_H_3,
--     -- top_1                 AS top_1,
--     -- FLATTEN(top_1_bag)    AS (H:int, year_id:int, player_id:chararray),
--     -- top_1_bag             AS top_1_bag:bag{t:(H:int, year_id:int, player_id:chararray)},
--     -- top_1_bag.H AS tH, -- :bag{t:(t1H:int)},
--     top_k.(player_id, H) AS top_k;
-- };
--
-- top_H_season_2 = FOREACH top_H_season {
--   top_k_o = FILTER top_k BY (H >= max_H);
--   -- firsties = CROSS top_k, tH;
--   -- top_k_o = ORDER top_k BY H DESC;
--   GENERATE year_id, max_H, top_k_o;
-- };
--
-- DESCRIBE top_H_season;
-- DESCRIBE top_H_season_2;
--
-- -- DUMP top_H_season;
-- DUMP top_H_season_2;

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

sig_seasons = load_sig_seasons();

-- ***************************************************************************
--
-- === Selecting Records Having the Top K Values in a Table
--

-- Find the top 40 seasons by hits.  Pig is smart about eliminating records at
-- the map stage, dramatically decreasing the data size.

top_H_seasons = LIMIT (ORDER sig_seasons BY H DESC, player_id ASC) 40;
-- top_H_seasons = RANK top_H_seasons;

-- A simple ORDER BY..LIMIT stanza may not be what you need, however. It will
-- always return K records exactly, even if there are ties for K'th place.
-- (Strangely enough, that is the case for the number we've chosen.)

-- The standard SQL trick is to identify the key for the K'th element (here,
-- it's Jim Bottomley's 227 hits in 1925) and then filter for records matching
-- or exceeding it. Unless K is so large that the top-k starts to rival
-- available memory, we're better off doing it in-reducer using a nested
-- FOREACH, just like we

--
-- http://pig.apache.org/docs/r0.12.0/api/org/apache/pig/piggybank/evaluation/Over.html[Piggybank's Over UDF]
-- allows us to
--
-- We limit within each group to the top `topk_window` (60) items, assuming
-- there are not 16 players tied for fourth in H. We don't assume for too long
-- -- an `ASSERT` statement verifies there aren't so many records tied for 4th
-- place that it overflows the 20 highest records we retained for consideration.


%DEFAULT topk_window 60
%DEFAULT topk        40
DEFINE IOver                  org.apache.pig.piggybank.evaluation.Over('int');
ranked_Hs = FOREACH (GROUP bats BY year_id) {
  bats_H  = ORDER bats BY H DESC;
  bats_N  = LIMIT bats_H $topk_window; -- making a bet, asserted below
  ranked  = Stitch(bats_N, IOver(bats_N, 'rank', -1, -1, 15)); -- beginning to end, rank on the 16th field (H)
  GENERATE
    group   AS year_id,
    ranked  AS ranked:{(player_id, year_id, team_id, lg_id, age, G, PA, AB, HBP, SH, BB, H, h1B, h2B, h3B, H, R, RBI, OBP, SLG, rank_H)}
    ;
};
-- verify there aren't so many records tied for $topk'th place that it overflows
-- the $topk_window number of highest records we retained for consideration
ASSERT ranked_Hs BY MAX(ranked.rank_H) > $topk; --  'LIMIT was too strong; more than $topk_window players were tied for $topk th place';

top_season_Hs = FOREACH ranked_Hs {
  ranked_Hs = FILTER ranked BY rank_H <= $topk;
  GENERATE ranked_Hs;
  };

STORE_TABLE(top_H_seasons, 'top_H_seasons');
-- STORE_TABLE('top_season_Hs', top_season_Hs);
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

park_teams = load_park_teams();
parks      = load_parks();
teams      = load_teams();

--
-- === Finding Duplicate and Unique Records
--

-- ***************************************************************************
--
-- ==== Eliminating Duplicate Records from a Table
--

-- The park_teams table has a row for every season. To find every distinct pair
-- of team and home ballpark, use the DISTINCT operator. This is equivalent to
-- the SQL statement `SELECT DISTINCT player_id, team_id from batting;`.

tm_pk_pairs_many = FOREACH park_teams GENERATE team_id, park_id;
tm_pk_pairs = DISTINCT tm_pk_pairs_many;

-- -- ALT     ALT01
-- -- ANA     ANA01
-- -- ARI     PHO01
-- -- ATL     ATL01
-- -- ATL     ATL02

-- Don't fall in the trap of using a GROUP statement to find distinct values:
--
dont_do_this = FOREACH (GROUP tm_pk_pairs_many BY (team_id, park_id)) GENERATE
  group.team_id, group.park_id;
--
-- the DISTINCT operation is able to use a combiner, eliminating duplicates at
-- the mapper before shipping them to the reducer. This is a big win when there
-- are frequent duplicates, especially if duplicates are likely to occur near
-- each other. For example, duplicates in web logs (from refreshes, callbacks,
-- etc) will be sparse globally, but found often in the same log file.
--
-- The combiner may impose a minor penalty when there are very few or very
-- sparse duplicates. In that case, you should still use DISTINCT, but disable
-- combiners with the `pig.exec.nocombiner=true` setting.




-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Eliminating Duplicate Records from a Group
--

-- Eliminate duplicates from a group with the DISTINCT operator inside a nested
-- foreach. Instead of finding every distinct (team, home ballpark) pair as we
-- just did, let's find the list of distinct home ballparks for each team:

team_parkslist = FOREACH (GROUP park_teams BY team_id) {
  parks = DISTINCT park_teams.park_id;
  GENERATE group AS team_id, BagToString(parks, '|');
};

EXPLAIN team_parkslist;

-- -- CL1     CHI02|CIN01|CLE01
-- -- CL2     CLE02
-- -- CL3     CLE03|CLE09|GEA01|NEW03
-- -- CL4     CHI08|CLE03|CLE05|CLL01|DET01|IND06|PHI09|ROC02|ROC03|STL05


-- SELECT team_id, GROUP_CONCAT(DISTINCT park_id ORDER BY park_id) AS park_ids
--   FROM park_team_years
--   GROUP BY team_id
--   ORDER BY team_id, park_id DESC
--   ;


-- (omit from book) The output is a bit more meaningful if we add the team name
-- and park names to the list:
--
tm_pk_named_a = FOREACH (JOIN park_teams    BY team_id, teams BY team_id) GENERATE teams::team_id AS team_id, park_teams::park_id    AS park_id, teams::team_name AS team_name;
tm_pk_named   = FOREACH (JOIN tm_pk_named_a BY park_id, parks BY park_id) GENERATE team_id,                   tm_pk_named_a::park_id AS park_id, team_name,  park_name;
team_parksnamed = FOREACH (GROUP tm_pk_named BY team_id) {
  parks = DISTINCT tm_pk_named.(park_id, park_name);
  GENERATE group AS team_id, FLATTEN(FirstTupleFromBag(tm_pk_named.team_name, (''))), BagToString(parks, '|');
};

-- ==== Eliminating All But One Duplicate Based on a Key

The DataFu `DistinctBy` UDF selects a single record for each key in a bag.
.
It has the nice feature of being order-preserving: only the first record for a key is output, and all records that make it to the output follow the same relative ordering they had in the input bag,

This gives us a clean way to retrieve the distinct teams a player served in, along with the first and last year of their tenure:define DistinctBy

DEFINE DistinctByYear datafu.pig.bags.DistinctBy('0');

pltmyrs = FOREACH bat_seasons GENERATE player_id, year_id, team_id;
player_teams = FOREACH (GROUP pltmyrs BY player_id) {
  pltmyrs_o = ORDER pltmyrs.(team_id, year_id) BY team_id; -- TODO does this use secondary sort, or cause a POSort?
  pltmyrs = DistinctByYear(pltmyrs);
  GENERATE player_id, BagToString(pltmyrs, '|');
};

The key is specified with a string argument in the DEFINE statement, naming the positional index(es) of the key's fields as a comma-separated list.






STORE_TABLE(tm_pk_pairs,     'tm_pk_pairs');
STORE_TABLE(team_parkslist,  'team_parkslist');
STORE_TABLE(team_parksnamed, 'team_parksnamed');
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

peeps       = load_people();

-- ***************************************************************************
--
-- ==== Selecting Records with Unique (or with Duplicate) Values for a Key
--

-- The DISTINCT operation is useful when you want to eliminate duplicates based
-- on the whole record. If you instead want to find only rows with a unique
-- record for its key, or only rows with multiple records for its key, do a
-- GROUP BY and then filter on the size of the resulting bag.
--

-- Distinct: players with a unique first name (once again we urge you: crawl
-- through your data. Big data is a collection of stories; the power of its
-- unusual effectiveness mode comes from the comprehensiveness of those
-- stories. even if you aren't into baseball this celebration of the diversity
-- of our human race and the exuberance of identity should fill you with
-- wonder.)
--
-- But have you heard recounted the storied diamond exploits of Firpo Mayberry,
-- Zoilo Versalles, Pi Schwert or Bevo LeBourveau?  OK, then how about
-- Mysterious Walker, The Only Nolan, or Phenomenal Smith?  Mul Holland, Sixto
-- Lezcano, Welcome Gaston or Mox McQuery?  Try asking your spouse to that your
-- next child be named for Urban Shocker, Twink Twining, Pussy Tebeau, Bris
-- Lord, Boob Fowler, Crazy Schmit, Creepy Crespi, Cuddles Marshall, Vinegar
-- Bend Mizell, or Buttercup Dickerson.
--
--
-- SELECT nameFirst, nameLast, COUNT(*) AS n_usages
--   FROM bat_career
--   WHERE    nameFirst IS NOT NULL
--   GROUP BY nameFirst
--   HAVING   n_usages = 1
--   ORDER BY nameFirst
--   ;
--

uniquely_yclept_g = GROUP peeps BY name_first; -- yclept /iˈklept/: by the name of; called.
uniquely_yclept_f = FILTER uniquely_yclept_g BY COUNT_STAR(peeps) == 1;
uniquely_yclept   = FOREACH uniquely_yclept_f {
  GENERATE group AS name_first,
    FLATTEN(peeps.(name_last, player_id, beg_date, end_date)) AS (name_last, player_id, beg_date, end_date);
};

uniquely_yclept = ORDER uniquely_yclept BY name_first ASC;
STORE_TABLE(uniquely_yclept, 'uniquely_yclept');


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

parks        = load_parks();
major_cities = load_us_city_pops();

-- === Set Operations on Full Tables

-- To demonstrate full-table set operations, we can relate the locations of
-- baseball stadiums with the set of major US cities footnote:[We'll take "major
-- city" to mean one of the top 60 incorporated places in the United States or
-- Puerto Rico; see the "Overview of Datasets" (REF) for source information].

-- We've actually met most of the set operations at this point, but it's worth
-- calling them out specifically. Set operations on groups are particularly
-- straightforward thanks to the Datafu package, which offers Intersect,
-- Difference (...)

-- Limit our attention to prominent US stadiums:
main_parks   = FILTER parks       BY n_games >=  50 AND country_id == 'US';

-- ==== Distinct Union
--
-- If the only contents of the tables are the set membership keys, finding the
-- distinct union of two tables is done just how it's spelled: apply union, then
-- distinct.
--
bball_city_names = FOREACH main_parks   GENERATE city;
major_city_names = FOREACH major_cities GENERATE city;
major_or_bball    = DISTINCT (UNION bball_city_names, major_city_names);

--
-- For all the other set operations, or when you want to base the distinct union
-- on keys (rather than the full record), simply do a COGROUP and accept or
-- reject rows based on what showed up in the relevant groups.
--
-- Two notes. First, since COUNT_STAR returns a value of type long, we do the
-- comparison against `0L` (a long) and not `0` (an int). Second, we test
-- against `COUNT_STAR(bag)`, and not `SIZE(bag)` or `IsEmpty(bag)`. Those
-- latter two require actually materializing the bag -- all the data is sent to
-- the reducer, and no combiners can be used.
--
combined     = COGROUP major_cities BY city, main_parks BY city;

-- ==== Distinct Union (alternative method)
--
-- Every row in combined comes from one table or the other, so we don't need to
-- filter.  To prove the point about doing the set operation on a key (rather
-- than the full record) let's keep around the state, population, and all
-- park_ids from the city.
major_or_parks    = FOREACH combined
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Intersection
--
-- Records lie in the set intersection when neither bag is empty.
--
major_and_parks   = FOREACH (FILTER combined BY (COUNT_STAR(major_cities) > 0L) AND (COUNT_STAR(main_parks) > 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Difference
--
-- Records lie in A-B when the second bag is empty.
--
major_minus_parks = FOREACH (FILTER combined BY (COUNT_STAR(main_parks) == 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

parks_minus_major = FOREACH (FILTER combined BY (COUNT_STAR(major_cities) == 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Symmetric Set Difference: (A-B)+(B-A)
--
-- Records lie in the symmetric difference when one or the other bag is
-- empty. (We don't have to test for them both being empty -- there wouldn't be
-- a row if that were the case)
--
major_xor_parks   = FOREACH (FILTER combined BY (COUNT_STAR(major_cities) == 0L) OR (COUNT_STAR(main_parks) == 0L))
  GENERATE group AS city, FLATTEN(FirstTupleFromBag(major_cities.(state, pop_2011), ('',0))), main_parks.park_id AS park_ids;

-- ==== Set Equality
--
-- Any of the tests described under "Set Operations within Groups" (REF) will
-- work to determine set equality, but unless you're already calculating one of
-- the set operations above you should use the "symmetric difference is empty"
-- test. Doing so is a bit more fiddly than you'd think.
--
-- To illustrate the problem, we'll use a pair of trivially equal tables:
major_city_names_also = FOREACH major_cities GENERATE city;
major_xor_major = FILTER (COGROUP major_city_names BY city, major_city_names_also BY city)
  BY ((COUNT_STAR(major_city_names) == 0L) OR (COUNT_STAR(major_city_names_also) == 0L));

-- Now you'd think that counting the elements of `major_xor_major` would work.
-- But since `major_xor_major` is empty, _the FOREACH has no lines to operate
-- on_. When the two sets of keys are equal, the output file is not a `1` as
-- you'd expect, it's an empty file.

-- Does not work: file is empty when sets are equal
major_equals_major_fail = FOREACH (GROUP major_xor_major ALL) GENERATE
   (COUNT_STAR(major_xor_major) == 0L ? 1 : 0) AS is_equal;

-- Our integer table to the rescue! We keep around a one-record version called
-- 'one_line.tsv' having fields uno (value `1`) and zilch (value `0`)
one_line = LOAD '$data_dir/stats/numbers/one_line.tsv' AS (uno:int, zilch:int);

-- Now do a COGROUP with our one_line friend and the constant value `1`. Since
-- there is exactly one possible value for the group key, there will only be one
-- row in the output.

-- will be `1` (true)
major_equals_major = FOREACH (COGROUP one_line BY uno, major_xor_major BY 1)
  GENERATE (COUNT_STAR(major_xor_major) == 0L ? 1 : 0) AS is_equal;

-- will be `0` (false)
major_equals_parks = FOREACH (COGROUP one_line BY uno, major_xor_parks BY 1)
  GENERATE (COUNT_STAR(major_xor_parks) == 0L ? 1 : 0) AS is_equal;

STORE_TABLE(major_or_parks,     'major_or_parks');
STORE_TABLE(major_and_parks,    'major_and_parks');
STORE_TABLE(major_minus_parks,  'major_minus_parks');
STORE_TABLE(parks_minus_major,  'parks_minus_major');
STORE_TABLE(major_xor_parks,    'major_xor_parks');
STORE_TABLE(major_equals_parks, 'major_equals_parks');
STORE_TABLE(major_equals_major, 'major_equals_major');

-- .Set Operation Membership
--
-- 		   A	 B	A∪B	A∩B	a-b	b-a	a^b	 ∅
-- 	A B	 T	 T	 T	 T	 F	 F	 F	 F
-- 	A -	 T	 F	 T	 F	 T	 F	 T	 F
-- 	- B	 F	 T	 T	 F	 F	 T	 T	 F
-- 	- -	 F	 F	 F	 F	 F	 F	 F	 F
IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

sig_seasons = load_sig_seasons();

-- ***************************************************************************
--
-- === Set Operations
--
-- * Distinct Union;
-- * Set Intersection
-- * Set Difference
-- * Set Equality
-- * Symmetric Set Difference

-- To demonstrate set operations on grouped records, let's look at the
-- year-to-year churn of mainstay players footnote:[using our definition of a
-- significant season: post-1900 and 450 or more plate appearances] on each
-- team.
--
-- Other applications of the procedure we follow here would include analyzing
-- how the top-10 products on a website change over time, or identifying sensors
-- that report values over threshold in N consecutive hours (by using an N-way
-- COGROUP).
--

-- ==== Constructing a Sequence of Sets

-- To construct a sequence of sets, perform a self-cogroup that collects the
-- elements from each sequence key into one bag and the elements from the next
-- key into another bag. Here, we group together the roster of players for a
-- team's season (that is, players with a particular `team_id` and `year_id`)
-- together with the roster of players from the following season (players with
-- the same `team_id` and the subsequent `year_id`).

-- Since it's a self-cogroup, we must do a dummy projection to make new aliases
-- (see the earlier section on self-join for details).
y1 = FOREACH sig_seasons GENERATE player_id, team_id, year_id;
y2 = FOREACH sig_seasons GENERATE player_id, team_id, year_id;

-- Put each team of players in context with the next year's team of players
year_to_year_players = COGROUP
  y1 BY (team_id, year_id),
  y2 BY (team_id, year_id-1)
  ;
-- Clear away the grouped-on fields
rosters = FOREACH year_to_year_players GENERATE
  group.team_id AS team_id,
  group.year_id AS year_id,
  y1.player_id  AS pl1,
  y2.player_id  AS pl2
  ;
-- The first and last years of existence don't have anything interesting to
-- compare, so reject them.
rosters = FILTER rosters BY (COUNT_STAR(pl1) == 0L OR COUNT_STAR(pl2) == 0L);

-- ==== Set operations within group

-- The content of `rosters` is a table with two key columns: team and year; and
-- two bags: the set of players from that year and the set of players from the
-- following year.
--
-- Applying the set operations lets us describe the evolution of the team from
-- year to year:
--

roster_changes_y2y = FOREACH rosters {

  -- The Distinct Union (A union B, which we'll find using the DataFu `SetUnion`
  -- UDF) describes players on the roster in either year of our two-year span.
  --
  either_year  = SetUnion(pl1, pl2);

  --
  -- All the DataFu set operations here tolerate inputs containing duplicates,
  -- and all of them return bags that contain no duplicates. They also each
  -- accept two or more bags, enabling you to track sequences longer than two
  -- adjacent elements.
  --
  -- As opposed to SetUnion, the other set operations require sorted
  -- inputs. That's not as big a deal as if we were operating on a full table,
  -- since a nested ORDER BY makes use of Hadoop's secondary sort. As long as
  -- the input and output bags fit efficiently in memory, these operations are
  -- efficient.
  pl1_o = ORDER pl1 BY player_id;
  pl2_o = ORDER pl2 BY player_id;

  -- The Set Intersection (A intersect B, which we'll find using the DataFu
  -- SetIntersect UDF) describes the players that played in the first year and
  -- also stayed to play in the second year.
  stayed      = SetIntersect(pl1_o, pl2_o);

  -- The Set Difference (A minus B, using the SetDifference UDF) contains the
  -- elements in the first bag that are not present in the remaining bags.  The
  -- first line therefore describes players that did _not_ stay for the next
  -- year, and the second describes players that newly arrived in the next year.
  y1_departed = SetDifference(pl1_o, pl2_o);
  y2_arrived  = SetDifference(pl2_o, pl1_o);

  -- The Symmetric Difference contains all elements that are in one set or the
  -- other but not both.  You can find this using either `(A minus B) union (B
  -- minus A)` -- players who either departed after the first year or newly
  -- arrived in the next year -- or `((A union B) minus (A intersect B))` --
  -- players who were present in either season but not both seasons.
  non_stayed  = SetUnion(y1_departed, y2_arrived);

  -- Set Equality indicates whether the elements of each set are identical --
  -- here, it selects seasons where the core set of players remained the
  -- same. There's no direct function for set equality, but you can repurpose
  -- any of the set operations to serve.
  --
  -- If A and B each have no duplicate records, then A and B are equal if and only if
  --
  -- * `size(A) == size(B) AND size(A union B) == size(A)`
  -- * `size(A) == size(B) AND size(A intersect B) == size(A)`
  -- * `size(A) == size(B) AND size(A minus B) == 0`
  -- * `size(symmetric difference(A,B)) == 0`
  --
  -- For multiple sets of distinct elements, `A, B, C...` are equal if and only
  -- if all the sets and their intersection have the same size:
  -- `size(intersect(A,B,C,...)) == size(A) == size(B) == size(C) == ...`
  --
  -- If you're already calculating one of the functions, use the test that
  -- reuses its result. Otherwise, prefer the A minus B test if most rows will
  -- have equal sets, and the A intersect B test if most will not or if there
  -- are multiple sets.
  --

  n_pl1         = SIZE(pl1);
  n_pl2         = SIZE(pl2);
  n_union       = SIZE(either_year);
  n_intersect   = SIZE(stayed);
  n_y1_minus_y2 = SIZE(y1_departed);
  n_y2_minus_y1 = SIZE(y2_arrived);
  n_xor         = SIZE(non_stayed);
  is_equal_via_union     = ( ((n_pl1 == n_pl2) AND (n_union       == n_pl1)) ? 1 : 0);
  is_equal_via_intersect = ( ((n_pl1 == n_pl2) AND (n_intersect   == n_pl1)) ? 1 : 0);
  is_equal_via_minus     = ( ((n_pl1 == n_pl2) AND (n_y1_minus_y2 == 0L))    ? 1 : 0);
  is_equal_via_xor       = ( (n_xor == 0L) ? 1 : 0);

  -- -- (omit from book)
  -- -- For your amusement, some invariants that hold for any sets
  -- world_makes_sense = AssertUDF( ((
  --   is_equal_via_union == is_equal_via_intersect AND
  --   is_equal_via_union == is_equal_via_minus     AND
  --   is_equal_via_union == is_equal_via_xor       AND
  --   (n_union           == n_intersect + n_xor)   AND
  --   (n_union           == n_pl1 + n_pl2 - n_intersect) AND
  --   (n_xor             == n_y1_minus_y2 + n_y2_minus_y1)
  --   ) ? 1 : 0) );

  GENERATE
    year_id, team_id,
    n_pl1            AS n_pl1,
    n_pl2            AS n_pl2,
    --
    n_union          AS n_union,
    n_intersect      AS n_intersect,
    n_y1_minus_y2    AS n_y1_minus_y2,
    n_y2_minus_y1    AS n_y2_minus_y1,
    n_xor            AS n_xor,
    --
    either_year      AS either_year,
    stayed           AS stayed,
    y1_departed      AS y1_departed,
    y2_arrived       AS y2_arrived,
    non_stayed       AS non_stayed,
    --
    is_equal_via_xor AS is_equal
    ;
};

roster_changes_y2y = ORDER roster_changes_y2y BY is_equal ASC, team_id, year_id;
STORE_TABLE(roster_changes_y2y, 'roster_changes_y2y');

--
-- ==== Exercises
--
-- * Implement a set equality UDF and submit it as an open-source contribution to
--   the DataFu project. Suggestions:
--
--   - Modify the datafu.pig.sets.SetIntersect UDF to return boolean false
--   - It should return immediately on finding an element that does not lie
--     within the intersection.
--   - Set the contract to require that each input bag is distinct (contains no
--     duplicate elements). This will let you quickly reject as not equal any
--     bags of different size.
--
-- * Modify the set operations UDFs to meet the accumulator interface (see
--   chapter on Advanced Pig for details)
--
-- * Using the waxy.org web logs dataset, identify how the top 10 pages by
--   visits change over time.
--
-- * Identify possibly abusive visitors in the waxy.org web logs:
--   - Calculate the amount of data transferred to each IP address in each
--     six-hour period
--   - Select heavy downloaders using either the z-score or percentile ranking
--     of their data volume, as described in the "identifying outliers" section.
--   - Use the procedure in the "set operations within groups" section to find
--     IP addresses that exceed your heavy-downloader threshold for four
--     consecutive six-hour blocks.
--   This sequence of actions is particularly useful for analysis of security or
--   sensor logs, where you are looking for things that are over threshold for
--   extended durations but not enough to trigger alarms.
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

-- === Group-Decorate-Flatten

-- When there

-- footnote:[The fancy term is "transitive dependency"; it makes the difference
-- between second and third normal form. Unless you already know what those
-- mean, forget this paragraph exists.]

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

