class CreateMarketPlaceProductStatus < ActiveRecord::Migration
  def up
    create_table :market_place_product_status do |t|
      t.references :market_places
      t.string :name
      t.string :code
      t.integer :market_place_id
      t.timestamps
    end
    add_index :market_place_product_status, :market_place_id
    add_index :market_place_product_status, :code
  end

  def down
    drop_table :market_place_product_status
  end
end
