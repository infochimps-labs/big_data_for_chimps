#!/usr/bin/env ruby

# This takes [idiopidae](https://bitbucket.org/ananelson/idiopidae-fork)-formatted files
# and exports each, named for its section, to a specfied output directory.
#
# An idiopidae block looks like:
#
#     ### @export section
#     ... arbitrary content ...
#     ### @/export
#
# Notes:
#
# * The `@/` syntax is idiosyncratic. Hopefully @ananelson will backport it.
# * Only `\w` (non-quoted) sections are allowed.
#

require 'configliere'
require 'gorillib/model'
require 'gorillib/pathname'
require 'gorillib/pathname/utils'
require 'gorillib/hash/mash'
require 'gorillib/logger/log'

module Idiopidae

  class SnippetCollection < Hash
    def initialize
      super{|hh,kk| hh[kk] = [] }
    end

    def add(section, snippet)
      return unless section.present?
      self[section] << snippet.join("\n")
    end
  end

  class IdioFile
    include Gorillib::Model

    field :path,     Pathname, position: 0
    field :snippets, Hash

    EXPORT_BEG_RE = %r{^[\ \t]*\#\#\# \@export (?<name>\w+)[\ \t]*$}
    EXPORT_END_RE = %r{^[\ \t]*\#\#\# \@/export[\ \t]*$}

    def scan!
      self.snippets = SnippetCollection.new
      section = nil
      snippet = []
      # def add_and_reset!
      # end
      #
      path.open.each do |line|
        line.chomp!
        if (mm = EXPORT_BEG_RE.match(line))
          snippets.add(section, snippet)
          section = nil
          snippet = []
          section = mm[:name].to_sym
        elsif EXPORT_END_RE.match(line)
          snippets.add(section, snippet)
          section = nil
          snippet = []
        elsif section.present?
          snippet << line
        else
          # nothing
        end
      end
    end

    def dump_file(output_dir)
      output_path = output_dir + path

      snippets.each do |section, snippet|
        output_basename = [path.corename.to_s, '--', section.to_s, path.extname.to_s].join
        output_path = (output_dir + path.dirname + output_basename).expand_path
        output_path.mkparent
        Log.info("writing #{section} (#{snippet.length} lines) to #{output_path}")
        File.open(output_path, 'w') do |outfile|
          outfile << snippet.join("\n\n") << "\n"
        end
      end
    end
  end

  class IdioRunner
    def lint_settings!
      raise "Please specify an input file and output directory" unless Settings.rest.length == 2
      raise "Input file must be relative path" unless input_file.relative?
    end

    def input_file
      @input_file ||= Pathname.new(Settings.rest.first)
    end
    def output_dir
      @output_dir ||= Pathname.new(Settings.rest.last)
    end

    def run
      Settings.use :commandline
      Settings.resolve! unless Settings.rest.present?

      lint_settings!
      ff = IdioFile.new(input_file)
      ff.scan!
      ff.dump_file(output_dir)
    end

  end
end

Idiopidae::IdioRunner.new.run
