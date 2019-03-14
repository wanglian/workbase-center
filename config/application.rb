require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WeaworkingCenter
  class Application < Rails::Application
    config.i18n.available_locales = [:en, 'zh-CN']
    config.i18n.default_locale = 'zh-CN'
    config.generators do |g|
      g.assets false
      g.helper false
      g.test_framework false
    end
    config.time_zone = 'Beijing'
  end
end
