class AddFieldToLineItems < ActiveRecord::Migration
  def up
  	add_column :spree_line_items, :delivery_time, :string
  end

  def down
  	remove_column :spree_line_items, :delivery_time
  end
end
