require 'bundler'
require 'logger'
Log = Logger.new($stderr).tap{|log| log.level = Logger::WARN } unless defined?(Log)

# Much of the code here adapted from [git-scribe](https://github.com/schacon/git-scribe)
# which carries the MIT license.

require 'configliere'
require 'gorillib/model'

Settings.use :commandline
Settings.define   :verbose,      default: true,  flag: 'v', type: :boolean
Settings.define   :force,        default: false, description: "If true, force output generation (ie pretend all dependencies were updated)", type: :boolean
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

#
# Generic tasks+methods for building book products
#
class BookTask
  include ::Rake::Cloneable
  include ::Rake::DSL
  include ::Gorillib::Model
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

  def local(*args)       ; File.expand_path(File.join(settings.repo_dir, *args.map(&:to_s))) ; end
  def output_path(*args) ; local('output', product_type.to_s, *args) ; end

  def book_file          ; local(settings.book_file)                ;  end
  def product_name()     ; File.basename(book_file).gsub(/\..*$/, '') ; end
  def output_file        ; output_path("#{product_name}.#{file_ext}") ; end
  def stylesheet_path(*args) File.expand_path(File.join('output', 'stylesheets', *args)) ; end

  def file_ext ; product_type.to_s ; end

  def asset_path(*args)
    File.expand_path(File.join(Settings.assets_dir, *args))
  end

  def directories(*dirs)
    dirs.flatten.each{|dir| directory(dir) }
  end

  def setup_task(ns, name, description)
    task_name = "#{ns}:#{name}"
    desc(description)
    task(task_name)
    task(ns => task_name)
    task_name
  end

  def gen_task(deps=[], name=nil)
    directory(output_path)
    task_name = setup_task(:gen, product_type, "Generate #{product_type} document")
    task(task_name => [output_file].flatten)
    file(output_file => :force) if settings.force
    file(output_file => [output_path, book_file, deps].flatten) do
      step :generating, product_type, "output #{output_file}"
      yield
    end
  end

  def clean_task(deps=[])
    task_name = setup_task(:clean, product_type, "Remove generated artifacts for #{product_type} output")
    task(task_name => deps) do
      step :removing, product_type, "output directory #{output_path}"
      FileUtils.rm_r output_path
      yield
    end
  end

end



class DocbookTask < BookTask
  self.product_type = :docbook
  def file_ext ; 'xml' ; end
  #
  def tasks
    gen_task{ sh(* gen_dockbook_cmd) }
    clean_task
  end
  #
  def gen_dockbook_cmd
    asciidoc_cmd('-b', 'docbook', output_file: output_file)
  end
end

class EpubTask < BookTask
  self.product_type = :epub
  #
  def tasks
    gen_task(['gen:html:assets']){ cd(output_path){ sh(* gen_epub_cmd) } }
    clean_task(['clean:html:assets'])
  end
  #
  def gen_epub_cmd
    a2x_wss << '-v' << book_file
  end
end

class MobiTask < BookTask
  self.product_type = :mobi
  #
  def tasks
    gen_task(['gen:html']){ sh(* kindlegen_cmd ) }
    clean_task(['clean:html'])
  end
  #
  def kindlegen_cmd
    cmd = ['kindlegen']
    cmd << '-verbose'
    cmd << "#{product_name}.opf" << '-o' << "#{product_name}.mobi"
    cmd
  end
end

class PdfTask < BookTask
  self.product_type = :pdf
  def tasks
    file fop_file => [output_path, book_file].flatten do
      step :generating, product_type, "intermediate #{fop_file}"
      sh(* gen_fop_cmd)
    end
    file(fop_file => :force) if settings.force
    gen_task(['gen:docbook', fop_file]){ sh(* gen_pdf_cmd) }
    clean_task
  end
  #
  def fop_file      ; output_path("#{product_name}.fo") ; end
  def docbook_file  ; DocbookTask.new.output_file       ; end
  #
  def gen_pdf_cmd
    ['fop', '-fo', fop_file, '-pdf', output_file]
  end
  def gen_fop_cmd
    xslt_cmd(['-o', fop_file, docbook_file, asset_path('docbook-xsl', 'fo.xsl')], java_options)
  end
  def java_options
    { 'callout.graphics' => 0, 'navig.graphics' => 0, 'admon.textlabel' => 1, 'admon.graphics' => 0, }
  end
end

class HtmlTask < BookTask
  self.product_type = :html
  def tasks
    copy_stylesheets_task
    gen_task(['gen:html:assets']){ sh(* gen_html_cmd) }
    clean_task(['clean:html:assets'])
  end
  #
  def gen_html_cmd
    asciidoc_cmd(output_file: output_file, attrs: { stylesheet: stylesheet_path('scribe.css') })
  end

  def assets_to_copy
    assets  = []
    assets += Dir[asset_path('assets', 'config.ru')].map{|from_file|  [local('output', File.basename(from_file)), from_file] }
    assets += Dir[asset_path('stylesheets', '*.css')].map{|from_file| [stylesheet_path(File.basename(from_file)), from_file] }
    assets
  end
  def copy_stylesheets_task
    directory(stylesheet_path)
    task('clean:html:stylesheets'){ FileUtils.rm_r(stylesheet_path) }
    task('gen:html:assets' => directories(assets_to_copy.map{|into, from| File.dirname(into) }.uniq))
    assets_to_copy.map do |into, from|
      file(into => [from, File.dirname(into)]){ cp from, into }
      task('gen:html:assets' => into)
      into
    end
  end
end

#
# Dumping ground for command invocation
#
module Runners

  def asciidoc_cmd(*args)
    options = { attrs: {} }.merge(args.extract_options!)
    cmd = ['asciidoc']
    options.delete(:attrs).each{|attr, val| cmd << '-a' << "#{attr}=#{val}" }
    cmd << "--out-file=#{options[:output_file]}" if options[:output_file]
    cmd += args
    cmd << book_file
    cmd
  end

  def a2x
    # , "--keep-artifacts"
    ["a2x", "--destination-dir=#{output_path}", "-f", product_type.to_s, "-d", "book", '--no-xmllint', ]
  end

  def a2x_wss
    a2x + ["--stylesheet=#{File.join('output', 'stylesheets', 'scribe.css')}"]
  end

  def xslt_cmd(jar_arguments, java_options)
    cmd = ['java']
    cmd << '-cp' << [asset_path('vendor', 'saxon.jar'), asset_path('vendor', 'xslthl-2.0.2.jar')].join(classpath_delimiter)
    cmd << "-Dxslthl.config=file://#{asset_path('docbook-xsl', 'highlighting', 'xslthl-config.xml')}"
    cmd += java_options.map{|attr,val| "-D#{attr}=#{val}" }
    cmd << 'com.icl.saxon.StyleSheet'
    cmd += Array(jar_arguments)
    cmd
  end
  def windows?() RbConfig::CONFIG['host_os'] =~ /mswin|windows|mingw|cygwin/i ; end
  def classpath_delimiter() windows? ? ';' : ':' ; end

end
class BookTask ; include Runners ; end

# --------------------------------------------------------------------------
#
# Rake Task definitions
#

# dummy task to force generation
task :force

desc "Generate all documents"
task :gen

desc "Remove generated artifacts for all file types"
task :clean

HtmlTask.new.tasks
PdfTask.new.tasks
DocbookTask.new.tasks
EpubTask.new.tasks
# MobiTask.new.tasks

task :default => 'gen:html'
