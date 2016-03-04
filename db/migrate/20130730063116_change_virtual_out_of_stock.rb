class ChangeVirtualOutOfStock < ActiveRecord::Migration
  def up
    remove_column :spree_variants, :virtual_out_of_stock
    add_column :spree_stock_items, :virtual_out_of_stock, :boolean, :default => false
  end

  def down
    remove_column :spree_stock_items, :virtual_out_of_stock
    add_column :spree_variants, :virtual_out_of_stock, :boolean
  end
end
