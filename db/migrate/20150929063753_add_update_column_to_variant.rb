class AddUpdateColumnToVariant < ActiveRecord::Migration
  def change
    add_column :spree_variants, :updated_on_fba, :boolean ,default: true
  end
end
