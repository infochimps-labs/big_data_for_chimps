export PIG_HOME=/Users/flip/ics/data_science_fun_pack/pig/pig ; for foo in flatten-chars_freq.pig ; do echo "  === $foo" ; echo -e "\n\n=== $foo\n`date`\n\n" >> /tmp/pig.log ; pig -4 ./log4j.properties -f $foo  ; done 

