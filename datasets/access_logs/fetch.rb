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
