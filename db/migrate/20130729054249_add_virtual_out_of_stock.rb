class AddVirtualOutOfStock < ActiveRecord::Migration
  def change
    add_column :spree_variants, :virtual_out_of_stock, :boolean
  end
end
