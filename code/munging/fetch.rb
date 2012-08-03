require 'swineherd/resource'

proj = Project.make(:access_logs, :ita) do

  p directory(path_to(:rawd_dir, "ita", "ita_epa"))

end

# parallel 'wget -nv -nc -np -a /data/log/access_logs_ita-wget-`datename`.log -r -l2 http://ita.ee.lbl.gov/html/contrib/{}.html' ::: NASA-HTTP WorldCup EPA-HTTP Sask-HTTP Calgary-HTTP ClarkNet-HTTP SDSC-HTTP
# mkdir /data/rawd/access_logs/{docs,ita_calgary,ita_clarknet,ita_epa,ita_nasa,ita_sdsc,ita_usask,ita_world_cup}
# # (copy files for all but world cup over)
# nohup parallel -j 4 'zcat {} | docs/ita_public_tools/bin/recreate docs/ita_public_tools/state/object_mappings.sort 2> /data/log/access_log/ita_world_cup/recreate-`datename`-{/.}.log | bzip2 -c > ita_world_cup/{/.}.log' ::: /data/ripd/ita.ee.lbl.gov/traces/WorldCup/*.gz &
# cd ita_world_cup
# for foo in 1 2 3 4 5 6 7 8 9 ; do mv wc_day{$foo}_1.log wc_day0{$foo}_1.log ; done
# parallel -j 8 bzip2 ::: *.log



# ## Preparation
#
# sudo mkdir /data
# sudo chown $USER /data
#
#     # modify to match
#
# export s3_bucket=s3://bigdata.chimpy.us log_dir=/data/log
# export this_az=us-east-1d this_instance=i-b8ca0ec1
#
# mkdir $log_dir /data/ripd
#
# ##
#
# mkdir -p /data/wikipedia/wikipedia_dumps-{v1,v2,v3}
#
# ec2-create-volume -z $this_az --snapshot snap-753dfc1c              # wikipedia_dumps-v1
# ec2-create-volume -z $this_az --snapshot snap-0c155c67              # wikipedia_dumps-v2
# ec2-create-volume -z $this_az --snapshot snap-f57dec9a              # wikipedia_dumps-v3
#
# ec2-attach-volume -d /dev/sdf -i $this_instance vol-9b9700f5        # wikipedia_dumps-v1
# ec2-attach-volume -d /dev/sdg -i $this_instance vol-d5e87fbb        # wikipedia_dumps-v2
# ec2-attach-volume -d /dev/sdh -i $this_instance vol-7b801715        # wikipedia_dumps-v3
# sudo mount          /dev/xvdf    /data/wikipedia/wikipedia_dumps-v1
# sudo mount          /dev/xvdg    /data/wikipedia/wikipedia_dumps-v2
# sudo mount          /dev/xvdh1   /data/wikipedia/wikipedia_dumps-v3
#
# mkdir -p /data/graph/marvel_universe
# ec2-attach-volume -d /dev/sdk -i $this_instance vol-839502ed
# sudo mount          /dev/xvdk    /data/graph/marvel_universe
#
# mkdir -p /data/geo/weather_daily
# ec2-attach-volume -d /dev/sdl -i $this_instance vol-b39007dd
# sudo mount          /dev/xvdl    /data/geo/weather_daily
#
# ## Obtaining the wikipedia pageview stats
#
# *see above for getting the first parts from the AWS Public Dataset wikipedia dumps.*
#
#     # organize the files
# for year in 2007 2008 2009 2010 2011 2012 ; do for mo in 01 02 03 04 05 06 07 08 09 10 11 12 ; do echo $year $mo ; dir=$year/$year-$mo ; mkdir -p $dir ; mv pagecounts-${year}${mo}* $dir/ ; done  ; done
#
#     # make the organized directories
# for year in 2007 2008 2009 2010 2011 2012 ; do for mo in 01 02 03 04 05 06 07 08 09 10 11 12 ; do echo $year $mo ; dir=$year/$year-$mo ; mkdir -p /data/ripd/dumps.wikimedia.org/other/pagecounts-raw/$dir ; done ; done
#
#
# cd /data/ripd ; nohup wget -r -l3 -np -nc http://dumps.wikimedia.org/other/pagecounts-raw/2011/ -nv >> $log_dir/wget-wikipedia_pageview_stats-2011-`datename`.log 2>&1 &
# cd /data/ripd ; nohup wget -r -l3 -np -nc http://dumps.wikimedia.org/other/pagecounts-raw/2012/ -nv >> $log_dir/wget-wikipedia_pageview_stats-2012-`datename`.log 2>&1 &
#
# nohup s3cmd sync /data/wikipedia/wikipedia_dumps-v1/wikistats/pagecounts/ $s3_bucket/wikipedia/wikipedia_pageview_stats/ >> $log_dir/s3sync-wikipedia_pageview_stats-v1-`datename`.log 2>&1 &
# nohup s3cmd sync /data/wikipedia/wikipedia_dumps-v1/wikistats/pagecounts/ $s3_bucket/wikipedia/wikipedia_pageview_stats/ >> $log_dir/s3sync-wikipedia_pageview_stats-v2-`datename`.log 2>&1 &
# nohup s3cmd sync /data/ripd/wikipedia_dumps-v2/wikistats/pagecounts/2009/ $s3_bucket/wikipedia/wikipedia_pageview_stats/2009/ >> $log_dir/s3sync-wikipedia_pageview_stats-v2-2009-`datename`.log 2>&1 &
#
# # graph/marvel_universe
#
# cat=graph dataset=marvel_universe ; nohup s3cmd sync /data/$cat/$dataset/*.tsv $s3_bucket/$cat/$dataset/ >> $log_dir/$dataset-s3sync-`datename`.log 2>&1 &
#
# ## geo/weather_daily
#
# cat=geo dataset=weather_daily ; nohup wget -nv -r -l3 -np -nc ftp://ftp.ncdc.noaa.gov/pub/data/gsod/2012/ >> /data/logs/${dataset}-wget-2012-`datename`.log 2>&1 &
#
# ## Wikipedia Raw Corpus
#
# http://dumps.wikimedia.org/enwiki/20120601/
#
# ## Airflight Status
#
# wget -x http://stat-computing.org/dataexpo/2009/airports.csv    >> /data/log/airline_flight_status-wget-`datename`.log 2>&1 &
# wget -x http://stat-computing.org/dataexpo/2009/plane-data.csv  >> /data/log/airline_flight_status-wget-`datename`.log 2>&1 &
# wget -x http://stat-computing.org/dataexpo/2009/carriers.csv    >> /data/log/airline_flight_status-wget-`datename`.log 2>&1 &
# nohup parallel -j1 wget -x -nv -nc -np http://stat-computing.org/dataexpo/2009/{}.csv.bz2 ::: 19{87,88,89} {199,200}{0,1,2,3,4,5,6,7,8,9,0} >> /data/log/airflight_status-wget-`datename`.log 2>&1 &
