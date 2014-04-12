%declare data_dir         '/data/rawd';

franchises = LOAD '$data_dir/sports/baseball/baseball_databank/csv/TeamsFranchises.csv' USING PigStorage(',') AS (
  franchID:chararray, franchName:chararray, active:chararray, NAassoc:chararray
);

tn_toks = FOREACH franchises GENERATE FLATTEN(TOKENIZE(franchName)) AS token;

tn_toks_g = GROUP tn_toks BY token;
tn_toks_ct = FOREACH tn_toks_g GENERATE group AS token, COUNT(tn_toks.token) AS ct;

tn_toks_ct = ORDER tn_toks_ct BY ct ASC;

DUMP tn_toks_ct;

