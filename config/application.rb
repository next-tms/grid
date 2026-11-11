require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

module Grid
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: ['assets', 'tasks'])

    config.api_only = true

    config.i18n.available_locales = %i[en es ja zh_cn]
    config.i18n.fallbacks = %i[en]
  end
end
