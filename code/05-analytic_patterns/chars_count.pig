%declare dsfp_dir         '/Users/flip/ics/data_science_fun_pack';
register    '$dsfp_dir/pig/pigsy/target/pigsy-2.1.0-SNAPSHOT.jar';
register    '$dsfp_dir/pig/datafu/dist/datafu-1.2.1-SNAPSHOT.jar';

DEFINE TransposeTupleToBag datafu.pig.util.TransposeTupleToBag();
DEFINE STRSPLITBAG         pigsy.text.STRSPLITBAG();

people = LOAD '/data/rawd/sports/baseball/baseball_databank/csv/Master.csv' USING PigStorage(',') AS (
        playerID:chararray,
        birthYear:int,        birthMonth:int,       birthDay: int,
        birthCtry: chararray, birthState:chararray, birthCity:chararray,
        deathYear:int,        deathMonth:int,       deathDay: int,
        deathCtry: chararray, deathState:chararray, deathCity:chararray,
        nameFirst:chararray,  nameLast:chararray,   nameGiven:chararray,
        weight:float,         height:float,
        bats:chararray,       throws:chararray,
        debut:chararray,      finalGame:chararray,
        retroID:chararray,    bbrefID:chararray );
people = LIMIT people 1;

typed_strings = FOREACH people {
  fields_bag = {('fn', nameFirst), ('ln', nameLast), ('ct', birthCity), ('ct', deathCity)};
  GENERATE FLATTEN(fields_bag) AS (type:chararray, str:chararray);
  };
typed_strings = FILTER typed_strings BY str != '';

typed_chars = FOREACH typed_strings {
  chars_bag = STRSPLITBAG(LOWER(str), '(?!^)');
  GENERATE type, FLATTEN(chars_bag) AS token;
  };
DESCRIBE typed_chars;
DESCRIBE typed_chars;

chars_g  = GROUP typed_chars BY (type, token);
chars_ct = FOREACH chars_g GENERATE group.type, group.token, COUNT(typed_chars) AS ct;

chars_type_g = GROUP chars_ct BY type;
DESCRIBE chars_type_g;

chars_freq = FOREACH chars_type_g {
  tot = SUM(chars_ct.ct);
  GENERATE group AS type, tot, FLATTEN(chars_ct.(token, ct));
};

DESCRIBE chars_freq;
DUMP     chars_freq;
