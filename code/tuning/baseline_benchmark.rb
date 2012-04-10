
SCHEMES = [:file, :hdfs, :s3n, :s3hdfs]

class Asset
  field :name,        Symbol
  field :description, String
  field :path,        Pathname
  field :host,        String
  field :scheme,      Symbol

  def copy_to_file(*args)   raise NoMethodError.abstract(self) ; end
  def copy_to_hdfs(*args)   raise NoMethodError.abstract(self) ; end
  def copy_to_s3n(*args)    raise NoMethodError.abstract(self) ; end
  def copy_to_s3hdfs(*args) raise NoMethodError.abstract(self) ; end
end

class FileAsset
  def from_http(*args) raise NoMethodError.abstract(self) ; end
  def copy_to_remote_file(*args) raise NoMethodError.abstract(self) ; end
end

class AssetCollection
  field :assets

end

module RunWithStats
  include Gorillib::CheckedPopen

  def run_with_stats(command, stdin)
    checked_popen(command, mode, fail_action) do |process|
      process.write(message)
      process.close_write
      process.read
    end
  end

end


[:one_gb].map do |asset|
  asset.copy_to :hdfs_src,   :exists => :ignore
  asset.copy_to :s3n_src,    :exists => :ignore
  asset.copy_to :s3hdfs_src, :exists => :ignore
end

[:one_gb].map do |asset|
  time_transfer_of :local_src, :local_dest
  time_transfer_of :local_src, :other_vol_dest
  time_transfer_of :local_src, :remote_file_dest
  time_transfer_of :local_src, :hdfs_dest
  time_transfer_of :local_src, :s3n_dest
  time_transfer_of :local_src, :s3hdfs_dest
  #
  time_transfer_of :hdfs_src,  :local_dest
  time_transfer_of :hdfs_src,  :hdfs_dest
  time_transfer_of :hdfs_src,  :s3n_dest
  time_transfer_of :hdfs_src,  :s3hdfs_dest
  #
  time_transfer_of :s3n_src,   :local_dest
  time_transfer_of :s3n_src,   :hdfs_dest
  time_transfer_of :s3n_src,   :s3n_dest
  time_transfer_of :s3n_src,   :s3hdfs_dest

end
