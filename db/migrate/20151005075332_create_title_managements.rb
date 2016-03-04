class CreateTitleManagements < ActiveRecord::Migration
  def change
    create_table :spree_title_managements do |t|
      t.text :name, :null => false
      t.integer :market_place_id, :null => false
      t.integer :product_id, :null => false
      t.timestamps
    end
    add_index :spree_title_managements, :market_place_id
    add_index :spree_title_managements, :product_id
  end
end
