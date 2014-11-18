IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';
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


