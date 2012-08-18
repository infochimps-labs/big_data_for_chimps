require 'gorillib/model'
require 'gorillib/factories'
require 'gorillib/model/serialization'
require 'gorillib/model/serialization/csv'
require 'gorillib/type/extended'
require 'gorillib/hash/slice'
require 'gorillib/pathname'

Pathname.register_path(:book_root, '~/ics/book/big_data_for_chimps/')
Pathname.register_path(:code, :book_root, 'code')
Pathname.register_path(:data, :book_root, 'data')
