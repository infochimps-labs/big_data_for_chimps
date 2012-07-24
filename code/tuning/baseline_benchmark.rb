#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'swineherd/resource'
Pathname.register_path(:book_tuning, File.dirname(__FILE__))

load Pathname.path_to(:book_tuning, 'fancy_tables.rb')

Pathname.register_path(:tmp_dir, '/tmp/system_baseline') ; Pathname.path_to(:tmp_dir).mkpath

class SystemBaseliner
  include Swineherd

  # collection of files &c to test with
  class_attribute :assets ; self.assets ||= AssetCollection.new

  class_attribute :runs   ; self.runs   = Hash.new

  assets << FileAsset.new(:wikipedia_articles_bz2,      '/data/ripd/dumps.wikimedia.org/enwiki/20111007/enwiki-20111007-pages-articles.xml.bz2')
  assets << FileAsset.new(:wikipedia_articles_bz2_dest, Pathname.path_to(:tmp_dir, 'enwiki-20111007-pages-articles.xml.bz2'))

  laptop_exec = Executor.new(:laptop, [ExampleMachines[:laptop]])

  run_stats = RunStats.new(assets[:wikipedia_articles_bz2], assets[:wikipedia_articles_bz2_dest], laptop_exec)
  runs[[:cp, :wikipedia_articles_bz2]] = run_stats

  cmd = Resource::CommandRunner.new('cp')
  run_stats.run( cmd, run_stats.input.to_path, run_stats.product.to_path )

end


# sync; time dd ibs=1048576 obs=1048576 count=1024 if=/dev/zero of=/u07/app/test/gigfile
# sync; time dd ibs=1048576 obs=1048576 count=1024 if=/dev/zero of=/u07/app/test/gigfile


# Formatador.models_table(ExampleMachines.values)
#
# Formatador.models_table(SystemBaseliner.assets.values)

# [:one_gb].map do |asset|
#   asset.copy_to :hdfs_src,   :exists => :ignore
#   asset.copy_to :s3n_src,    :exists => :ignore
#   asset.copy_to :s3hdfs_src, :exists => :ignore
# end
#
# [:one_gb].map do |asset|
#   time_transfer_of :local_src, :local_dest
#   time_transfer_of :local_src, :other_vol_dest
#   time_transfer_of :local_src, :remote_file_dest
#   time_transfer_of :local_src, :hdfs_dest
#   time_transfer_of :local_src, :s3n_dest
#   time_transfer_of :local_src, :s3hdfs_dest
#   #
#   time_transfer_of :hdfs_src,  :local_dest
#   time_transfer_of :hdfs_src,  :hdfs_dest
#   time_transfer_of :hdfs_src,  :s3n_dest
#   time_transfer_of :hdfs_src,  :s3hdfs_dest
#   #
#   time_transfer_of :s3n_src,   :local_dest
#   time_transfer_of :s3n_src,   :hdfs_dest
#   time_transfer_of :s3n_src,   :s3n_dest
#   time_transfer_of :s3n_src,   :s3hdfs_dest
#
# end


# [Hitachi-HTS725050A9A362](http://www.hgst.com/tech/techlib.nsf/techdocs/3FDCAB792901CF4B862575D8005AB39B/$file/TS7K500_DS.pdf)

# Using [bonnie](http://www.textuality.com/bonnie/advice.html) for disk benchmarking:
# worblehat ~/ics/core/swineherd$ bonnie -d /tmp -s 8000 -m worblehat-Hitachi-HTS725050A9A362
#
#                  -------Sequential Output-------- ---Sequential Input-- --Random--
#                  -Per Char- --Block--- -Rewrite-- -Per Char- --Block--- --Seeks---
# Machine       GB M/sec %CPU M/sec %CPU M/sec %CPU M/sec %CPU M/sec %CPU  /sec %CPU
# worblehat  2    2  58.4 54.2  92.2 13.3  57.9  6.2 157.9 100   5593  100  2067  2.6   bonnie -d /tmp -s 2000 -m worblehat-Hitachi-HTS725050A9A362 / File '/tmp/Bonnie.97743', size: 2097152000
# worblehat  8    8  73.6 67.6  70.6 10.2  31.6  4.2  68.9 59.6  53.8  3.8   185  1.8
# worblehat 32   32  48.7 55.0  53.4 18.6  22.6  2.7  54.4 47.7  55.8  4.8    76  1.2
#

# worblehat ||                      | This test was run with the option -m worblehat. "worblehat" is the label for the test.
# 2000      || MB                   | This test was run with the option -s 2000. Bonnie used a 2000-Megabyte file to do the testing. These numbers aren't valid: the machine has 8GB of memory, more than 4x the file size.
#   58.4    || r  seq char   M/sec  | When writing the file by doing 2000 million putc() macro invocations, Bonnie recorded an output rate of 58.4 M per second.
#   54.2    || r  seq char   %CPU   | When writing the file by doing 2000 million putc() macro invocations, the operating system reported that this work consumed 54.2% of one CPU's time.
#   92.2    || r  seq block  M/sec  | When writing the 2000-Mb file using efficient block writes, Bonnie recorded an output rate of 92.2 M per second.
#   12.3    || r  seq block  %CPU   | When writing the 2000-Mb file using efficient block writes, the operating system reported that this work consumed 12.3% of one CPU's time.
#   57.9    || rw seq rewrt  M/sec  | While running through the 2000-Mb file just creating, changing each block, and rewriting, it, Bonnie recorded an ability to cover 57.9 M per second.
#    6.2    || rw seq rewrt  %CPU   | While running through the 2000-Mb file just creating, changing each block, and rewriting, it, the operating system reported that this work consumed 6.2% of one CPU's time.
#  157.9    || w  seq char   M/sec  | While reading the file using 2000 million getc() macro invocations, Bonnie recorded an input rate of 157.9 M per second.
#  100      || w  seq char   %CPU   | While reading the file using 2000 million getc() macro invocations, the operating system reported that this work consumed 100% of one CPU's time. This is amazingly high. The 2GB file is probably too small to be an effective test.
# 5593      || w  seq block  M/sec  | While reading the file using efficient block reads, Bonnie reported an input rate of 5592 M per second.
#  100      || w  seq block  %CPU   | While reading the file using efficient block reads, the operating system reported that this work consumed 100% of one CPU's time.
# 2067      || r  rand seeks /sec   | Bonnie created 4 child processes, and had them execute 4000 seeks to random locations in the file. On 10% of these seeks, they changed the block that they had read and re-wrote it. The effective seek rate was 2067 seeks per second.
#    2.6    || r  rand seeks %CPU   | During the seeking process, the operating system reported that this work consumed 2.6% of one CPU's time.
#

# Configuration
# SATA 3Gb/s              | Interface
# 500                     | Capacity (GB)
# 512                     | Sector size (bytes)
# 24                      | Recording zones
# 370                     | Areal density (max, Gbit/sq.in.)
#                         | == Performance ==
# 16                      | Data buffer (MB)
# 7200                    | Rotational speed (RPM)
# 4.2                     | Latency average (ms)
# 1245                    | Media transfer rate (max, Mbits/sec)
# 300                     | Interface transfer rate (MB/sec)
#                         | == Seek time ==
# 12                      | Average (typical)  ms (read)
# 1                       | Track to track (typical)  ms (read)
# 20                      | Full stroke (typical)  ms (read)
# 600,000                 | Reliability
# N/A                     | Load / Unload cycle
# N/A                     | Power on hours (POH) per month
#                         | == Availability ==
# +5VDC (+-5%)            | Power
#                         | == Requirement ==
# 5.5W                    | Dissipation (typical)
# 2.0W                    | Startup (peak, max)
# 1.8W                    | Seek (average)
# 1.7W                    | Read / Write (average)
# 1.0W                    | Performance idle (average)
# 0.69W                   | Active idle (average)
# 0.2W                    | Low power idle (average)
# 0.1W                    | Standby (average)
#                         | == Sleep ==
# 9.5                     | Physical size
# 70 x 100                | Height (mm)
# 115 / 95                | Dimensions (width x depth, mm)
#                         | == Weight (max, g) ==
# 400 G/2ms, 225 G/1ms    | Environmental (Operating)
# 5° - 55° C              | Shock (half sine wave)
#                         | == Ambient temperature ==
# 1000 G/1 ms             | Environmental (Non-Operating)
# -40° - 65° C            | Shock (half sine wave)
#                         | == Ambient temperature ==
# 2.5                     | Idle (typical, Bels)
# 2.8                     | Seek (typical, Bels
