class Spree::StockLocationHolidayList < ActiveRecord::Base
  attr_accessible :stock_location_id, :holiday_list_id

  belongs_to :stock_location
  belongs_to :holiday_list

  validates_presence_of :stock_location_id, :holiday_list_id

end
