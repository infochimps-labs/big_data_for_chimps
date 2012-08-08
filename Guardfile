# -*- ruby -*-

notification :off
interactor :off

require 'guard/notifiers/emacs'
::Guard::Notifier::DEFAULTS.merge!(
  :success => '#e7fde4',
  :failed  => '#faeedc',
  :default => '#eee8d6',
)

# Add files and commands to this file, like the example:
#   watch(%r{file/path}) { `command(s)` }
#
guard 'shell' do
  watch(/(.*).asciidoc/) do |m|
    # `say -v cello #{m[0]}`
    system 'rake', '--trace', 'gen:html', '--', "--book_file=#{m[0]}"
  end
end

guard 'livereload' do
  watch(/(.*).asciidoc/){|file| "html/#{file[1]}.html" }
end
