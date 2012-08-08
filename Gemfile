source 'http://rubygems.org'

gem 'configliere'
gem 'gorillib',   :github => 'infochimps-labs/gorillib', :branch => 'version_1'
gem 'wukong',     :github => 'infochimps-labs/wukong',   :branch => 'vanilla_2'

gem 'git-scribe', :path => '../git-scribe'

gem 'yajl-ruby',  :platform => :mri

gem 'coolline'

# SciRuby/sciruby

# Gems you would use if hacking on this gem (rather than with it)
group :support do
  gem 'pry'
  gem 'rake'
  #
  gem 'guard',       ">= 1.0"
  gem 'guard-shell'
  gem 'guard-livereload'
  gem 'rack'
  #
  gem 'guard-yard'
  gem 'yard',        ">= 0.7"
  gem 'redcarpet',   ">= 2.1"
end

# Gems for testing and coverage
group :test do
  gem 'rspec',       "~> 2.8"
  gem 'guard-rspec', ">= 0.6"
  if RUBY_PLATFORM.include?('darwin')
    gem 'rb-fsevent', ">= 0.9"
  end
end
