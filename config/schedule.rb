env :PATH, '/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games'
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

require 'yaml'

set :environment, :development
set :output, {
    :error    => "log/cron/error.log",
    :standard => "log/cron/success.log"
}

every 5.minutes do
  rake "market_place_api_calls:check_for_new_order"
end

every 15.minutes do
  rake "market_place_api_calls:check_for_cancel_order"
end

every 1.hours do
  rake "market_place_api_calls:update_market_place_order_status"
  rake "market_place_api_calls:fetch_order_invoice_for_lazada"
  #rake "market_place_api_calls:sync_fba_kit_products"
end

every 2.hours do
  rake "market_place_api_calls:fetch_market_place_order_status"
end

every 1.days, :at => '03:50 pm' do
  rake "market_place_api_calls:check_quantity_inflation_promotions"
  rake "market_place_api_calls:generate_disputed_cancel_order_report"
  rake "promotions:close_discount_promotion"
end
every 1.days, :at => '03:55 pm' do
  rake "promotions:start_discount_promotion"
end
every :monday, :at => '01:00 am' do
  rake "market_place_api_calls:generate_weekly_report_for_seller"
end

=begin
every 4.hours do
  rake "market_place_api_calls:sync_product_quantity_from_fba"
end

every 1.days do
  rake "market_place_api_calls:complete_order_status_from_fba"
end
=end


