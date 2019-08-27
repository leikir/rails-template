if Rails.env.production?
  Rollbar.configure do |config|
    config.access_token = ENV['ROLLBAR_TOKEN']

    config.exception_level_filters.merge!(
      'ActionController::RoutingError' => 'ignore'
    )

    config.environment = ENV['ROLLBAR_ENV'].presence || Rails.env
  end
end
