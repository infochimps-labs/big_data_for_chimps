# -*- ruby -*-

notification :off
# interactor :off

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
  watch(/(.*).asciidoc/) do |match|
    system 'rake', '--trace', 'gen:html', '--rules', '--', "--book_file=#{match[0]}"
    system 'rake', '--trace', 'gen:html', '--rules', '--', "--book_file=working.asciidoc", '--force'
  end
end

guard 'livereload' do
  watch(/(.*).asciidoc/){|match| [ "#{match[1]}.html", "working.html"] }
end
