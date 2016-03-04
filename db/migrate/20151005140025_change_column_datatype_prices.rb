class ChangeColumnDatatypePrices < ActiveRecord::Migration
  def up
   change_column :spree_price_managements, :selling_price, :decimal, :precision=>15, :scale => 2
   change_column :spree_price_managements, :special_price, :decimal, :precision=>15, :scale => 2
   change_column :spree_price_managements, :settlement_price, :decimal, :precision=>15, :scale => 2
   change_column :spree_variants, :selling_price, :decimal, :precision=>15, :scale => 2
  end

  def down
   change_column :spree_price_managements, :selling_price, :float
   change_column :spree_price_managements, :special_price, :float
   change_column :spree_price_managements, :settlement_price, :float
   change_column :spree_variants, :selling_price, :float
  end
end
