class AddReadyForPickupToSpreeLineItems < ActiveRecord::Migration
  def change
    add_column :spree_line_items, :ready_for_pickup, :boolean, :default => false
  end
end
