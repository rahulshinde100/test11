class CreateSpreeOptionValuesMarketPlaces < ActiveRecord::Migration
  def change
    create_table :spree_option_values_market_places do |t|
      t.integer :option_value_id
      t.integer :option_type_id
      t.integer :market_place_id
      t.string :name
      t.timestamps
      t.timestamps
    end
    add_index :spree_option_values_market_places, :option_value_id
    add_index :spree_option_values_market_places, :option_type_id
    add_index :spree_option_values_market_places, :market_place_id
  end
end
