class CreateSpreeBrands < ActiveRecord::Migration
  def change
    create_table :spree_brands do |t|
    	t.string  	:name, :null => false
    	t.string 		:description
    	t.string    :permalink
      
    	t.string   	:logo_file_name
      t.string   	:logo_content_type
      t.integer  	:logo_file_size
      t.datetime 	:logo_updated_at

      t.string   	:banner_file_name
      t.string   	:banner_content_type
      t.integer  	:banner_file_size
      t.datetime 	:banner_updated_at
      t.timestamps
    end
    add_column :spree_products, :brand_id, :integer #added brand id to product model
  end
  
end
