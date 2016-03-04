class AddKitIdIntoLineItems < ActiveRecord::Migration
  def change
    add_column :spree_line_items, :kit_id, :integer
    add_index :spree_line_items, :kit_id
  end
end
