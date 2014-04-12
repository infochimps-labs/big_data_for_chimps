%declare data_dir         '/data/rawd';
    
-- ==== Generate a Record for Each Word in a Text Field
-- 
-- The TOKENIZE command
-- is a fast-and-dirty way to break a string into words
-- (We'll demonstrate a much better tokenizer in the chapter on text data (REF)).
-- The return schema of tokenize is a bag of tuples each holding one word:
-- FLATTEN turns that into one record per word.
-- 
-- Washington's bad habit of losing franchises makes it the most common token. 

franchises = LOAD '$data_dir/sports/baseball/baseball_databank/csv/TeamsFranchises.csv' USING PigStorage(',') AS (
  franchID:chararray, franchName:chararray, active:chararray, NAassoc:chararray
);

tn_toks    = FOREACH franchises GENERATE FLATTEN(TOKENIZE(franchName)) AS token;
tn_toks_g  = GROUP tn_toks BY token;
tn_toks_ct = FOREACH tn_toks_g GENERATE group AS token, COUNT(tn_toks.token) AS ct;

tn_toks_ct = ORDER tn_toks_ct BY ct ASC;
DUMP tn_toks_ct;



