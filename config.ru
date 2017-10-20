require 'rubygems'
require 'bundler'

Bundler.require

require './lodestone.rb'
run Sinatra::Application
