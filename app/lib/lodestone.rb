module Lodestone
  BASE_URL = 'http://finalfantasyxiv.com'.freeze
  CATEGORIES = OpenStruct.new(YAML.load_file('config/categories.yml')).freeze

  extend self
end
