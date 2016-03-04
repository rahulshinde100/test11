class CreateSpreeRecentMarketPlaceChanges < ActiveRecord::Migration
 def self.up
    create_table :spree_recent_market_place_changes do |t|
      t.integer :product_id
      t.integer :variant_id
      t.integer :seller_id
      t.integer :market_place_id
      t.integer :updated_by
      t.text :description
	  t.timestamps
    end
  end

  def self.down
  	drop_table :spree_recent_market_place_changes
  end
end
