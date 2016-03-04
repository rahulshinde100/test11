class ChangeDateFormatInSpreeLineItems < ActiveRecord::Migration
  def up
  	change_column :spree_line_items, :item_pickup_at, :string
  end

  def down
  	change_column :spree_line_items, :item_pickup_at, :date
  end
end
