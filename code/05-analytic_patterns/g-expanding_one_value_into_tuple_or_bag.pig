IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();
peeps       = load_people();
teams       = load_teams();
park_teams   = load_park_teams();
franchises = load_franchises();

-- ***************************************************************************
--
-- === Expanding One Value Into a Tuple or Bag
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Splitting a String into its Characters
--



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



