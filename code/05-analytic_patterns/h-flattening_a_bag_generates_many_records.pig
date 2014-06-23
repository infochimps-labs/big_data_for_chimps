IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();

-- ***************************************************************************
--
-- === Expanding One Value Into a Tuple or Bag
--

typed_strings = FOREACH people {
  fields_bag = {('fn', nameFirst), ('ln', nameLast), ('ct', birthCity), ('ct', deathCity)};
  GENERATE FLATTEN(fields_bag) AS (type:chararray, str:chararray);
  };

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Splitting a String into its Characters
--

typed_chars = FOREACH typed_strings {
  chars_bag = STRSPLIT(str, '(?!^)');  -- works, but not as we want
  GENERATE type, FLATTEN(chars_bag) AS token;
  };

register    '/path/to/pigsy/target/pigsy-2.1.0-SNAPSHOT.jar';
DEFINE STRSPLITBAG         pigsy.text.STRSPLITBAG();
-- ...
typed_chars = FOREACH typed_strings {
  chars_bag = STRSPLITBAG(LOWER(str), '(?!^)');
  GENERATE type, FLATTEN(chars_bag) AS token;
  };


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Tokenizing the Words in a String
--

-- The TOKENIZE command
-- is a fast-and-dirty way to break a string into words.
-- (We'll demonstrate a much better tokenizer in the chapter on text data (REF)).
-- The return schema of tokenize is a bag of words footnote:[Technically, a bag of tuples each containing one word, as the direct contents of a bag are always tuples], which
-- FLATTEN turns into one record per word.
-- The follow-on code groups all words and produces the count of occurrences for each word; we'll explain how group and friends work in the next chapter

tn_toks    = FOREACH franchises
  GENERATE FLATTEN(TOKENIZE(franchName)) AS token;
tn_toks_ct = FOREACH (GROUP tn_toks BY token)
  GENERATE group AS token,
  COUNT_STAR(tn_toks.token) AS tok_ct;
-- Only retain the top million tokens
team_toks  = ORDER tn_toks_ct BY tok_ct DESC;
wp_toks    = LIMIT wp_toks 1000000;
rmf                   $out_dir/team_toks;
STORE team_toks INTO '$out_dir/team_toks';


-- ***************************************************************************
--
-- === Flattening a Bag Generates Many Records
--


-- ***************************************************************************
--
-- === Flattening a Tuple Generates Many Columns

attr_strings = FOREACH people {
  fields_bag = {('fn', nameFirst), ('ln', nameLast), ('ct', birthCity), ('ct', deathCity)};
  GENERATE FLATTEN(fields_bag) AS (type:chararray, str:chararray);
  };
-- ('fn',Hank)
-- ('ln',Aaron)
-- ...

attr_chars = FOREACH (FILTER attr_strings BY str != '') {
  chars_bag = STRSPLITBAG(LOWER(str), '(?!^)');
  GENERATE type, FLATTEN(chars_bag) AS token;
  };
DESCRIBE attr_chars;

chars_ct   = FOREACH (GROUP attr_chars BY (type, token))
  GENERATE group.type, group.token, COUNT_STAR(attr_chars) AS ct
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
