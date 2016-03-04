class CreateSellerMarketPlaceProductStatus < ActiveRecord::Migration
  def up
   create_table :seller_market_place_product_status do |t|
      t.references :market_place_product_status
      t.references :seller_market_place_product
      t.integer :market_place_product_status_id
      t.integer :seller_market_place_product_id
      t.timestamps
    end
    add_index :seller_market_place_product_status, :market_place_product_status_id, :name => "add_index_to_smpps_mpps"
    add_index :seller_market_place_product_status, :seller_market_place_product_id, :name => "add_index_to_smpps_smpp"
  end

  def down
    drop_table :seller_market_place_product_status
  end
end

