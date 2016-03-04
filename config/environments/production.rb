SwitchFabric::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true
  # config.action_controller.include_all_helpers = false

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  #set default time zone
  config.time_zone = 'Singapore'

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  #config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = true

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
  config.action_mailer.default_url_options = {:host => "switch-fabric"}
  ActionMailer::Base.default :from => 'no_reply@channel-manager.com'
  # Expands the lines which load the assets
  OMS_PATH =  "http://fba.anchanto.com/order_bucket"
  FULFLMNT_PATH = "http://fba.anchanto.com"
  # OMS_PATH =  "http://fba.anchanto.com/order_bucket"
  # OMS_API_PATH = "http://fulflmnt.com/api/status"
  # OMS_API_KEY = "2a0779bab2cbeb548dba9d115a15bca711f8e4a0"
  # OMS_USER_EMAIL = "abhimanyu.kashikar@gmail.com"
  # OMS_USER_SIGNATURE = "DCHkM_l9KHdwUAmNJqDAm__Os1dJPwnULOGoGvbrAxmRAbtTd_IOJA"

  USER = "fulflmnt"
  PASSWORD = "@nch@t0"

  ENV['FACEBOOK_KEY']="256759424465398"
  ENV['FACEBOOK_SECRET']="fc005382997f6be38fd9a6a30719db2f"
  DATASHIFT_PATH = Rails.root.join('tmp/data_import')

end
