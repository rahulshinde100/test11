class AddColumnToVariants < ActiveRecord::Migration
  def change
    add_column :spree_variants, :validation_message, :text
  end
end