class AddSpecialPriceProduct < ActiveRecord::Migration
  def up
    add_column :spree_variants, :special_price, :decimal, :precision => 8, :scale => 2
  end

  def down
    remove_column :spree_variants, :special_price
  end
end
