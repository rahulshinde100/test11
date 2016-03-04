class KitDescriptionDataTypeChangeToText < ActiveRecord::Migration
  def up
    change_column :spree_kits, :description,  :text
  end

  def down
    change_column :spree_kits, :description,  :string
  end
end
