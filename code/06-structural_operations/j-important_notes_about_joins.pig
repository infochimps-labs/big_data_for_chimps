IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/gold'; %DEFAULT out_dir '/data/outd/baseball';

seed = LOAD '06-structural_operations/j-important_notes_about_joins.tsv' AS (
  row:int,
  num:int,
  has_nulls:int,
  bag_wempty:bag{t:tuple(val:int)},
  bag_wnulls:bag{t:tuple(val:int)}
  );


aa = FOREACH seed {
  new_wnulls = FOREACH bag_wnulls GENERATE val + 1;
  new_wempty = FOREACH bag_wempty GENERATE val + 1;
  GENERATE
    'aa'                     AS tbl,
    row                      AS row,
    num + 1                  AS num,
    has_nulls + 1            AS has_nulls,
    (chararray)(has_nulls+1) AS str_nulls,
    (row == 16 ? Null : new_wnulls) AS bag_wnulls,
    (row == 16 ? Null : new_wempty) AS bag_wempty;
};

bb = FOREACH seed GENERATE
    'bb'                     AS tbl,
    row                      AS row,
    num                      AS num,
    has_nulls                AS has_nulls,
    (chararray)(has_nulls)   AS str_nulls,
    bag_wnulls               AS bag_wnulls,
    bag_wempty               AS bag_wempty
  ;

-- * Adding 1 to has_nulls produced a null (and not an error) when value was null
-- * Pig dumps an empty bag as `{}`, a bag with a tuple holding Null as `{()}`
-- * A bag with a tuple holding null is not empty and is not null
-- * A bag field can also be null (row 16)
-- * IsEmpty returned Null, not false, on the null bag
whats_null_or_empty = FOREACH aa {
  GENERATE
    tbl,
    row,
    'has_nulls',  has_nulls,  (has_nulls  IS NULL ? '~' : '!null'),
    'str_nulls',  str_nulls,  (str_nulls  IS NULL ? '~' : '!null'),
    'bag_wnulls', bag_wnulls, (bag_wnulls IS NULL ? '~' : '!null'), (IsEmpty(bag_wnulls) ? '-' : '!empt'),
    'bag_wempty', bag_wempty, (bag_wempty IS NULL ? '~' : '!null'), (IsEmpty(bag_wempty) ? '-' : '!empt')
    ;
};

what_happens_to_null = FOREACH aa {
  bool = (has_nulls > 3 ? true : false);
  GENERATE
    row,
    has_nulls,
    bool                           AS boolean_val,
    'booleans',
    (has_nulls > 3  ? 'true' : '~') AS ternary_on_null_is_null,
    (bool AND true  ? 'true' : '~') AS null_and_true_is_null,
    (bool OR  true  ? 'true' : '~') AS wow_null_or_true_is_true,
    (bool AND false ? 'true' : '~') AS wow_null_and_false_is_false,
    (bool IS NULL   ? 'null' : '~') AS false_is_not_null,
    'funcs',
    has_nulls + 1                  AS null_plus_val_is_null,
    (has_nulls == has_nulls ? 'true' : '~') AS null_equals_null_is_null,
    (has_nulls == Null      ? 'null' : '~') AS no_really_its_null,
    (has_nulls != Null      ? 'true' : '~') AS null_notequals_null_is_null,
    'empties',
    IsEmpty(bag_wempty)            AS isempty_on_null_value_is_null,
    IsEmpty(bag_wnulls)            AS isempty_on_bag_with_nulls_is_false,
    '' AS z;
};

-- * Flattening a bag with a tuple holding null _does_ result in a row. Flattening an empty bag _does not_.
flatten_keeps_nulls = FOREACH aa GENERATE FLATTEN(bag_wnulls) AS wnulls_num, * ;
-- * Flattening an empty bag _does not_ result in a row.
flatten_drops_empty = FOREACH aa GENERATE FLATTEN(bag_wempty) AS wempty_num, * ;

aa1 = FOREACH aa GENERATE tbl, row, has_nulls;
bb1 = FOREACH bb GENERATE tbl, row, has_nulls;


-- Join on a column with nulls ~> no rows for those keys
join_drops_nulls     = JOIN aa1 BY has_nulls, bb1 BY has_nulls;

-- cannot join on a bag value
-- aa_join_bb_on_bag = JOIN aa1 BY bag_wnulls, bb1 BY bag_wnulls;

-- cannot join on a map value
-- aa_join_bb = JOIN aa BY TOMAP(bag_wnulls), bb BY TOMAP(bag_wnulls);

-- A tuple join key is "null" if any of its values is null
aa_join_bb           = JOIN    aa1 BY (has_nulls, 1), bb1 BY (has_nulls, 1);

-- You can join on an expression
aa_join_bb_on_expr   = JOIN aa1 BY (has_nulls-1, row), bb1 BY (has_nulls, row+1);

-- Joining on a constant is like cross
aa_join_bb_on_const  = JOIN    aa1 BY 1, bb1 BY 1;

-- It's OK if values outside the key are null
aa_join_bb_on_nonull = JOIN aa1 BY row, bb1 BY row;

join_keeping_nulls   = JOIN
  aa1 BY ( (has_nulls IS NULL ? -999 : has_nulls), (has_nulls IS NULL ? 'null' : '~') ),
  bb1 BY ( (has_nulls IS NULL ? -999 : has_nulls), (has_nulls IS NULL ? 'null' : '~') )
;

-- COGROUP on a tuple with nulls _does_ keep null-keyed rows, but separate groups!
aa_cogr_bb_on_tuple  = COGROUP aa1 BY (has_nulls, 1), bb1 BY (has_nulls, 1);

cogr_keeping_nulls   = COGROUP
  aa1 BY ( (has_nulls IS NULL ? 0 : has_nulls), (has_nulls IS NULL ? 'null' : '~') ),
  bb1 BY ( (has_nulls IS NULL ? 0 : has_nulls), (has_nulls IS NULL ? 'null' : '~') )
;



-- STORE_TABLE(whats_null_or_empty, 'test-whats_null_or_empty');
-- STORE_TABLE(flatten_drops_empty, 'test-flatten_drops_empty');
-- STORE_TABLE(flatten_keeps_nulls, 'test-flatten_keeps_nulls');
-- STORE_TABLE(what_happens_to_null, 'test-what_happens_to_null');

STORE_TABLE(aa_join_bb,         'test-aa_join_bb');
STORE_TABLE(join_keeping_nulls, 'test-join_keeping_nulls');
STORE_TABLE(cogr_keeping_nulls, 'test-cogr_keeping_nulls');


