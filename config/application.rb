require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module Billionaire
  class Application < Rails::Application
    config.i18n.default_locale = :ru
    config.i18n.locale = :ru
    config.i18n.fallbacks = [:en]

    config.time_zone = 'Moscow'

    config.active_record.raise_in_transactional_callbacks = true
  end
end
