require "csv"

module Spree
  class HolidayList < ActiveRecord::Base
    attr_accessible :active, :description, :name, :from, :to, :seller_id, :all_locations, :stock_locations

    belongs_to :seller
    #belongs_to :stock_location
    has_many :stock_location_holiday_lists
    has_many :stock_locations, :through => :stock_location_holiday_lists

    validates_presence_of :name, :from

    def self.import(file)
      CSV.foreach(file.path, headers: true) do |row|
        row = row.to_hash
        stock_location_name = Spree::StockLocation.find_by_name(row["stock_location_name"])
        unless stock_location_name.nil?
          row.delete("stock_location_name")
          holiday_list = HolidayList.create(row.merge(:seller_id => stock_location_name.seller.id))
          holiday_list.stock_locations << stock_location_name
        end
      end
    end
  end
end
