# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
SwitchFabric::Application.initialize!

ActiveRecord::Base.include_root_in_json = true
TOKENPARAM = "5h!p.1!"

# To initialize scheduler logs
CRON_LOG = Logger.new("#{Rails.root}/log/cron.log")
CRON_LOG.level = Logger::INFO

QTY_LOG = Logger.new("#{Rails.root}/log/quantity.log")
QTY_LOG.level = Logger::INFO

