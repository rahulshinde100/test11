class AddColumnToSpreeLineItems < ActiveRecord::Migration
  def change
  	add_column :spree_line_items, :is_pick_at_store, :boolean, :default => false
  	add_column :spree_line_items, :picked_up, :boolean, :default => false
  	add_column :spree_line_items, :stock_location_id, :integer
  end
end
