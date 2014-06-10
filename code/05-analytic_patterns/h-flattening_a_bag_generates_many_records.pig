IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Flattening a Bag Generates Many Records
--


-- ***************************************************************************
--
-- === Flattening a Tuple Generates Many Columns

typed_strings = FOREACH people {
  fields_bag = {('fn', nameFirst), ('ln', nameLast), ('ct', birthCity), ('ct', deathCity)};
  GENERATE FLATTEN(fields_bag) AS (type:chararray, str:chararray);
  };
-- ('fn',Hank)
-- ('ln',Aaron)
-- ...

typed_chars = FOREACH (FILTER typed_strings BY str != '') {
  chars_bag = STRSPLITBAG(LOWER(str), '(?!^)');
  GENERATE type, FLATTEN(chars_bag) AS token;
  };
DESCRIBE typed_chars;

chars_ct   = FOREACH (GROUP typed_chars BY (type, token))
  GENERATE group.type, group.token, COUNT(typed_chars) AS ct
  ;

chars_freq = FOREACH (GROUP chars_ct BY type) {
  tot_ct = SUM(chars_ct.ct);
  GENERATE group AS type, tot_ct AS tot_ct, FLATTEN(chars_ct.(ct, token));
  };
chars_freq = FOREACH chars_freq GENERATE type, token, ct, (int)ROUND(1e6f*ct/tot_ct) AS freq:int;
DESCRIBE chars_freq;

rmf                    $out_dir/chars_freq;
STORE chars_freq INTO '$out_dir/chars_freq';


-- nf_chars = FOREACH bat_seasons GENERATE
--   FLATTEN(STRSPLITBAG(name_first, '(?!^)')) AS char;
-- chars_hist = FOREACH (GROUP nf_chars BY char) {
--   GENERATE group AS char, COUNT_STAR(nf_chars.char) AS ct;
-- };
-- chars_hist = ORDER chars_hist BY ct;
