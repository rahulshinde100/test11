class CreateDescriptionManagement < ActiveRecord::Migration
  def change
    create_table :spree_description_managements do |t|
      t.text :description, :null => false
      t.integer :market_place_id, :null => false
      t.integer :product_id, :null => false
      t.text :meta_description
      t.text :package_content  
      t.timestamps
    end
  end
end
