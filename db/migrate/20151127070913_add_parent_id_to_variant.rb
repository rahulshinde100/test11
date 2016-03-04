class AddParentIdToVariant < ActiveRecord::Migration
  def change
    add_column :spree_variants, :parent_id, :integer
  end
  add_index :spree_variants, :parent_id
end
