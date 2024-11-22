source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.5'

gem 'rails', '~> 7.2.2'
gem 'mysql2', '~> 0.5'
gem 'sass-rails'
gem 'sprockets-rails'
gem 'rack', '>= 2.2.6.3'
gem 'rack-cors', '1.1.0'
gem 'jbuilder', '~> 2.7'
gem 'bootsnap', '>= 1.4.4', require: false
gem 'lograge'
gem 'whenever', require: false
gem 'rest-client'
gem 'nokogiri', '>= 1.13.6'
gem 'tzinfo'
gem 'bootstrap', '~> 4.3.1'
gem 'mime-types-data', '3.2021.1115' # TODO: See https://github.com/mime-types/mime-types-data/pull/50
gem 'base64', '0.1.1' # Passenger requirement

group :development do
  gem 'puma'
  gem 'annotate'
  gem 'web-console'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'listen'
  gem 'spring'
  gem 'i18n_yaml_sorter'

  # capistrano
  gem 'capistrano', '3.16.0'
  gem 'capistrano-bundler'
  gem 'capistrano-rbenv'
  gem 'capistrano-rails'
  gem 'ed25519'
  gem 'bcrypt_pbkdf'
end
