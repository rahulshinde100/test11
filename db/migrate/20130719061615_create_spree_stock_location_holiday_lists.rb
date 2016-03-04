class CreateSpreeStockLocationHolidayLists < ActiveRecord::Migration
  def change
    create_table :spree_stock_location_holiday_lists do |t|
      t.integer :stock_location_id
      t.integer :holiday_list_id
      t.timestamps
    end
  end
end
