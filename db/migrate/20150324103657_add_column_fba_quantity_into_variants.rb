class AddColumnFbaQuantityIntoVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :fba_quantity, :integer, :default=>0
    add_index :spree_variants, :fba_quantity
  end
end
