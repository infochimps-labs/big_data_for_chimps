require 'gorillib/string/human'

chapters = %w[
  preface
  first_exploration
  simple_transform
  transform_pivot
  geographic_flavor
  toolset
  filesystem_mojo
  server_logs
  text_processing
  data_management
  statistics
  time_series
  geographic
  cat_herding
  data_munging
  best_practices
  graphs
  machine_learning
  java_api
  advanced_pig
  hbase_data_modeling
  hadoop_internals
  hadoop_tuning
  datasets_and_scripts
  cheatsheets
  appendix
]

chapters.each_with_index do |name, idx|
  File.open("#{"%02d" % (idx)}-#{name}.asciidoc", "w") do |file|
    file << "[[#{name}]]"
    file << "== #{name.titleize}\n" << "\n"
  end
end
