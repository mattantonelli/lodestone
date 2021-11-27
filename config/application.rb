require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module LodestoneNews
  class Application < Rails::Application
    config.load_defaults 6.1

    config.generators.system_tests = nil
    config.web_console.permissions = '10.0.2.2'
  end
end
