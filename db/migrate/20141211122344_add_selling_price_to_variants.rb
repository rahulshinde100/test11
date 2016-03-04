class AddSellingPriceToVariants < ActiveRecord::Migration
  def self.up
    add_column :spree_variants, :selling_price, :decimal
  end

  def self.down
    remove_column :spree_variants, :selling_price
  end
end
