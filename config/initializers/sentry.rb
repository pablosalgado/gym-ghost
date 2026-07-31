if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    # Set traces_sample_rate to 1.0 to capture 100%
    # of transactions for tracing. Adjust in production as needed.
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "1.0").to_f

    config.environment = ENV["SENTRY_ENVIRONMENT"] || Rails.env
  end
end
