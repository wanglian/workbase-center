require "grape-swagger"
require 'grape_logging'

class Base < Grape::API
  prefix :api
  format :json

  helpers do
    def logger
      Grape::API.logger
    end
  end

  log_file = File.open('log/api.log', 'a')
  log_file.sync = true
  logger Logger.new GrapeLogging::MultiIO.new(STDOUT, log_file)
  logger.formatter = GrapeLogging::Formatters::Default.new
  # use GrapeLogging::Middleware::RequestLogger,
  #   logger: logger,
  #   log_level: 'info',
  #   include: [ GrapeLogging::Loggers::Response.new,
  #              GrapeLogging::Loggers::FilterParameters.new ]

  rescue_from :all do |e|
    logger.error e
    error! 'Server error', 500
  end

  mount App
  mount Server
  mount Wechat

  add_swagger_documentation(
    :api_version => "v1",
    hide_documentation_path: true,
    hide_format: true,
    info: {
      title: "Center API"
    }
  )

end

