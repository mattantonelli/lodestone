require 'rubygems'
require 'bundler'

Bundler.require

use Rack::Attack

require './lodestone.rb'
run Sinatra::Application
