require 'gorillib/string/human'
chapters = %w[
  preface
  first_exploration
  simple_transform
  transform_pivot
  regional_flavor
  toolset
  filesystem_mojo
  server_logs
  text_processing
  statistics
  time_series
  geographic
  cat_herding
  data_munging
  organizing_data
  graphs
  machine_learning
  best_practices
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
    file << "[[#{name}]]\n"
    file << "== #{name.titleize}\n" << "\n"
  end
end
