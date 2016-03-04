class ChangesSellingPriceFromIntegerToDecimal < ActiveRecord::Migration
  def up
    change_column :spree_variants, :selling_price, :float
  end

  def down
    change_column :spree_variants, :selling_price, :integer
  end
end
