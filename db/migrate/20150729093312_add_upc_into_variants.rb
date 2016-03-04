class AddUpcIntoVariants < ActiveRecord::Migration
  def up
    add_column :spree_variants, :upc, :string
  end

  def down
    remove_column :spree_variants, :upc
  end
end
