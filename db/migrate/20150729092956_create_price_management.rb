class CreatePriceManagement < ActiveRecord::Migration
  def change
    create_table :spree_price_managements do |t|
      t.float :selling_price, :null => false
      t.float :special_price
      t.float :settlement_price
      t.integer :market_place_id
      t.integer :variant_id  
      t.timestamps
    end
  end
end
