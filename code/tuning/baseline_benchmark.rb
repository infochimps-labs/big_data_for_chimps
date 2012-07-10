#!/usr/bin/env ruby
require 'swineherd/resource'
require File.expand_path('fancy_tables', File.dirname(__FILE__))

Pathname.register_path(:tmp_dir, '/tmp/system_baseline') ; Pathname.path_to(:tmp_dir).mkpath

class SystemBaseliner
  include Swineherd

  # collection of files &c to test with
  class_attribute :assets ; self.assets ||= AssetCollection.new

  class_attribute :runs   ; self.runs   = Hash.new

  assets << FileAsset.new(:wikipedia_articles_bz2,      '/data/ripd/dumps.wikimedia.org/enwiki/20111007/enwiki-20111007-pages-articles.xml.bz2')
  assets << FileAsset.new(:wikipedia_articles_bz2_dest, Pathname.path_to(:tmp_dir, 'enwiki-20111007-pages-articles.xml.bz2'))

  laptop_exec = Executor.new(:laptop, [ExampleMachines[:laptop]])

  runs[[:cp, :wikipedia_articles_bz2]] = RunStats.new(
    assets[:wikipedia_articles_bz2], assets[:wikipedia_articles_bz2_dest], laptop_exec)

end

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
