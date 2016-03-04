class AddColumnsToSeller < ActiveRecord::Migration
  def up
  	add_column :spree_sellers, :business_type_id, :integer
  	add_column :spree_variants, :rcp, :decimal, :precision => 8, :scale => 2
  	add_column :spree_line_items, :rcp, :decimal, :precision => 8, :scale => 2
  end

  def down
  	remove_column :spree_sellers, :business_type_id
  	remove_column :spree_variants, :rcp
  	remove_column :spree_line_items, :rcp
  end
end
