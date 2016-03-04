class CreateSpreeHolidayLists < ActiveRecord::Migration
  def change
    create_table :spree_holiday_lists do |t|
      t.string :name
      t.text :description
      t.date :from, :null => false
      t.date :to
      t.boolean :active,:default => true
      t.integer :seller_id
      t.timestamps
    end
  end
end
