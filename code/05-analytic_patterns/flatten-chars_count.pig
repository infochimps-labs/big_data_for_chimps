IMPORT 'common_macros.pig';

people = load_people();
people = LIMIT people 1;

typed_strings = FOREACH people {
  fields_bag = {('fn', nameFirst), ('ln', nameLast), ('ct', birthCity), ('ct', deathCity)};
  GENERATE FLATTEN(fields_bag) AS (type:chararray, str:chararray),
    (deathCity IS NULL ? 'none' : deathCity)
    ;
  };

-- Output:
-- ('fn',Hank)
-- ('ln',Aaron)
-- ...

typed_chars = FOREACH (FILTER typed_strings BY str != '') {
  chars_bag = STRSPLITBAG(LOWER(str), '(?!^)');
  GENERATE type, FLATTEN(chars_bag) AS token;
  };
DESCRIBE typed_chars;

chars_ct = FOREACH (GROUP typed_chars BY (type, token)) GENERATE
  group.type, group.token, COUNT(typed_chars) AS ct;

chars_freq = FOREACH (GROUP chars_ct BY type) {
  tot = SUM(chars_ct.ct);
  GENERATE group AS type, tot, FLATTEN(chars_ct.(token, ct));
};

DESCRIBE chars_freq;
DUMP     chars_freq;
