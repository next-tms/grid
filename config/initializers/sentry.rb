Sentry.init do |config|
  config.breadcrumbs_logger = %i[active_support_logger http_logger]
  config.dsn = ENV.fetch('SENTRY_DSN', nil)
  config.enabled_environments = ['production']
  config.environment = Rails.env
  config.send_default_pii = false
end
