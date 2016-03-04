SwitchFabric::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true
  # config.action_controller.include_all_helpers = false

  #set default time zone
  config.time_zone = 'Singapore'

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  #config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5
  # config.action_mailer.raise_delivery_errors = false
  # Do not compress assets
  config.assets.compress = false
  config.action_mailer.default_url_options = {:host => "localhost", :port => "3000"}
  ActionMailer::Base.default :from => 'no_reply@channel-manager.com'
  # Expands the lines which load the assets
  OMS_PATH =  "http://localhost:3001/order_bucket"
  FULFLMNT_PATH = "http://localhost:3001"
  #OMS_API_PATH = "http://localhost:3001/api/status"
  #OMS_API_KEY = "9aaff0889b940d3ef57c715b2d96ede10de11da9" #"ba41e26d851f02e694b1b2f59794bd9bf3595b4c"
  #OMS_USER_EMAIL = "nitin.khairnar@anchanto.com" #"v.zambre@gmail.com"
  #OMS_USER_SIGNATURE = "5BtpU9CPuiMUfrKeltiersKHFYUKAsVdXibjbBqHlu8_X391kX2nEA" #"AyEo4i0-N7UjTyrT1TwjBD1iPrJdEcmdHnXTXWLG_zsh8ThtxA-RBw"

  # Added by Tejaswini Patil
  # Lazada url
  LAZADA_URL = "https://sellercenter-api.linio.com.mx"

  USER = "fulflmnt"
  PASSWORD = "@nch@t0"

  config.assets.debug = false
  ENV['FACEBOOK_KEY']="455274101188277"
  ENV['FACEBOOK_SECRET']="98c532a64ed66cdb575556eaa27d9f25"
  DATASHIFT_PATH = Rails.root.join('tmp/data_import')
end
