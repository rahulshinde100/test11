class CreateMarketPlaceOrderLineItemDetails < ActiveRecord::Migration
  def change
    create_table :spree_mp_order_line_items do |t|
      t.integer :order_id, :null => false
      t.text :market_place_details
      t.timestamps
    end
    add_index :spree_mp_order_line_items, :order_id
  end
end
