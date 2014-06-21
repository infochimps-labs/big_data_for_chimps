IMPORT 'common_macros.pig'; %DEFAULT data_dir '/data/rawd'; %DEFAULT out_dir '/data/out/baseball';

bat_seasons = load_bat_seasons();

-- ***************************************************************************
--
-- === Selecting a Fixed Limit of Records
--

-- ====

-- The LIMIT statement
-- Without some preceding operation to set the records in a determined order, it's rarely used except to extract a snippet of data for development. Let's

-- Choose an arbitrary 25 sequential records. See chapter 6 for something more interesting.
some_players = LIMIT bat_seasons 25;

STORE_TABLE(some_players, 'some_players');

--
-- ==== LIMIT .. DUMP
--

-- The main use of a LIMIT statement, outside of an ORDER BY..LIMIT stanza, is
-- before dumping data

-- We hope that some day the DUMP command gains an intrinsic LIMIT
-- capability. Until then, you can try this:
=> LIMIT bat_seasons 25; DUMP @;

-- Keep in mind that the presence anywhere of a DUMP command has hidden
-- consequences, including disabling multi-query execution.


