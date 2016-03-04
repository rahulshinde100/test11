class CreateQuantityInflations < ActiveRecord::Migration
  def change
    create_table :spree_quantity_inflations do |t|
      t.integer :variant_id, :null => false
      t.integer :market_place_id, :null => false
      t.string :sku, :null => false
      t.string :change_type, :null => false
      t.string :next_type, :null => false
      t.integer :quantity, :null => false
      t.integer :previous_quantity, :null => false
      t.datetime :end_date, :null => false
      t.timestamps
    end
    add_index :spree_quantity_inflations, :market_place_id
    add_index :spree_quantity_inflations, :variant_id
  end
end
