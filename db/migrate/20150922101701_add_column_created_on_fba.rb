class AddColumnCreatedOnFba < ActiveRecord::Migration
  def up
    add_column :spree_variants, :is_created_on_fba, :boolean, default: false
  end

  def down
    remove_column :spree_variants, :is_created_on_fba
  end
end
