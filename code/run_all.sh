#!/usr/bin/env bash

export PIG_HOME=$HOME/code/data_science_fun_pack/pig/pig

# agg-summary_stats.pig flatten-chars_freq.pig flatten-tokenize.pig foreach-case_example.pig group-histogram.pig group-running_seasons.pig
# group-win_loss_record.pig join-semijoin-all_star_seasons.pig

for foo in order-extremal_record.pig  ; do
  echo "  === $foo" ;
  echo -e "\n\n=== $foo\n`date`\n\n" >> /tmp/pig.log
  pig -4 ./log4j.properties -f $foo
done
