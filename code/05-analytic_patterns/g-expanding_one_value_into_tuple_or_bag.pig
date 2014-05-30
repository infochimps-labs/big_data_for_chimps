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
-- ==== Tokenizing a String into Words
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- ==== Generate a Record for Each Word in a String
--


-- The TOKENIZE command
-- is a fast-and-dirty way to break a string into words
-- (We'll demonstrate a much better tokenizer in the chapter on text data (REF)).
-- The return schema of tokenize is a bag of tuples each holding one word:
-- FLATTEN turns that into one record per word.
-- 
-- Washington's bad habit of losing franchises makes it the most common token. 

tn_toks    = FOREACH franchises
  GENERATE FLATTEN(TOKENIZE(franchName)) AS token;
tn_toks_ct = FOREACH (GROUP tn_toks BY token)
  GENERATE group AS token,
  COUNT(tn_toks.token) AS tok_ct;

team_toks  = ORDER tn_toks_ct BY tok_ct ASC;

rmf                   $out_dir/team_toks;
STORE team_toks INTO '$out_dir/team_toks';



