require 'bundler'
require 'logger'
Log = Logger.new($stderr).tap{|log| log.level = Logger::WARN } unless defined?(Log)

# Much of the code here adapted from [git-scribe](https://github.com/schacon/git-scribe)
# which carries the MIT license.

require 'configliere'
require 'gorillib/model'

Settings.use :commandline
Settings.define   :verbose,      default: true, flag: 'v', type: :boolean
Settings.define   :book_file,    default: 'book.asciidoc'
Settings.define   :publish,      default: false,           type: :boolean
Settings.define   :edition,      default: '0.1'
Settings.define   :language,     default: 'en'
Settings.define   :version,      default: '1.0'
Settings.define   :output_types, default: ['docbook', 'html', 'pdf', 'epub', 'mobi', 'site'], type: Array
Settings.define   :repo_dir,     finally: ->(c){ c[:repo_dir] = Dir.pwd },  type: :filename
Settings.define   :assets_dir,   default: '../git-scribe', type: :filename
Settings.read('./.gitscribe')
Settings.resolve!
Log.level   = Logger::DEBUG if Settings.verbose
Log.debug{ "configuration: #{Settings.inspect}" }

require_relative 'tasks/runners'

class BookTask
  include ::Rake::Cloneable
  include ::Rake::DSL
  include ::Gorillib::Model
  include Runners
  class_attribute :product_type

  def settings
    Settings
  end

  def info(*args)
    puts args.join("\t")
  end
  def step(name, *args)
    info( "%-20s" % name, args )
  end

  def local(*args)       ; File.expand_path(File.join(settings.repo_dir, *args)) ; end
  def output_path(*args) ; local('output', product_type.to_s, *args) ; end

  def book_file          ; local(settings.book_file)                ;  end
  def product_name()     ; File.basename(book_file).gsub(/\..*$/, '') ; end
  def output_file        ; output_path("#{product_name}.#{file_ext}") ; end
  def stylesheet_path(*args) File.join('output', 'stylesheets', *args) ; end

  def file_ext ; product_type.to_s ; end

  def asset_path(*args)
    File.expand_path(File.join(Settings.assets_dir, *args))
  end

  def output_dir_task
    directory_task(output_path)
  end

  def directory_task(dir_name)
    directory(dir_name)
    dir_name
  end

  def setup_task(ns, task, description)
    task_name = "#{ns}:#{product_type}"
    desc description
    task(task_name)
    task(ns => task_name)
    task_name
  end

  def gen_task(deps=[])
    task_name = setup_task(:gen, product_type, "Generate #{product_type} document")
    task(task_name => [output_file].flatten)
    file(output_file => [output_dir_task, book_file, deps].flatten) do
      step :generating, product_type, "output #{output_file}"
      yield
    end
  end

  def clean_task
    task_name = setup_task(:clean, product_type, "Remove generated artifacts for #{product_type} output")
    task(task_name) do
      step :removing, product_type, "output #{output_file}"
      FileUtils.rm output_file
      yield
    end
  end

  def stylesheets_to_generate
    Dir[asset_path('stylesheets', '*.css')].map do |from_file|
      [stylesheet_path(File.basename(from_file)), from_file]
    end
  end

  def copy_stylesheets
    directory_task(stylesheet_path)
    stylesheets_to_generate.map{|into, from| file(into => stylesheet_path){ cp from, into } }
  end

end


class DocbookTask < BookTask
  self.product_type = :docbook
  def file_ext ; 'xml' ; end

  def tasks
    gen_task do
      sh(* asciidoc_cmd('-b', 'docbook', output_file: output_file) )
    end
  end
end

class EpubTask < BookTask
  self.product_type = :epub

  def tasks
    gen_task [copy_stylesheets] do
      cd output_path do
        sh(* [a2x_wss, '-v', book_file].flatten )
      end
    end
  end
end

class MobiTask < BookTask
  self.product_type = :mobi
  def tasks
    gen_task ['gen:html'] do
      sh(* kindlegen_cmd )
    end
  end
end

class PdfTask < BookTask
  self.product_type = :pdf
  def java_options
    {
      'callout.graphics' => 0,
      'navig.graphics'   => 0,
      'admon.textlabel'  => 1,
      'admon.graphics'   => 0,
    }
  end

  def fop_file
    output_path("#{product_name}.fo")
  end

  def docbook_file
    DocbookTask.new.output_file
  end

  def tasks
    file fop_file => [output_dir_task, book_file].flatten do
      step :generating, product_type, "intermediate #{fop_file}"
      sh(* xslt_cmd(['-o', fop_file, docbook_file, asset_path('docbook-xsl', 'fo.xsl')], java_options))
    end
    gen_task ['gen:docbook', fop_file] do
      # cd asset_path do
        sh('fop', '-fo', fop_file, '-pdf', output_file)
      # end
    end
  end
end

class HtmlTask < BookTask
  self.product_type = :html

  def tasks
    gen_task [copy_stylesheets] do
      sh(* asciidoc_cmd(output_file: output_file, attrs: { stylesheet: stylesheet_path('scribe.css') }) )
    end
    clean_task do
      stylesheets_to_generate.map(&:first).each{|file| puts "FileUtils.rm(#{file})" }
    end
  end
end

desc "Generate all documents"
task :gen

desc "Remove generated artifacts for all file types"
task :clean

HtmlTask.new.tasks
PdfTask.new.tasks
DocbookTask.new.tasks
EpubTask.new.tasks
MobiTask.new.tasks

task :default => 'gen:html'
