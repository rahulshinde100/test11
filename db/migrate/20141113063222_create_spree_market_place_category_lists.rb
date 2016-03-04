class CreateSpreeMarketPlaceCategoryLists < ActiveRecord::Migration
  def change
    create_table :spree_market_place_category_lists do |t|
      t.string :name , :null => false
      t.string :category_code, :null => false
      t.integer :market_palce_id	
      t.timestamps
    end
  end
end
