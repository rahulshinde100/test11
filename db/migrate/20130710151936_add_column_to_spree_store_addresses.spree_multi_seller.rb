# This migration comes from spree_multi_seller (originally 20130710151806)
class AddColumnToSpreeStoreAddresses < ActiveRecord::Migration
  def change
  	add_column :spree_store_addresses, :lat, :string
    add_column :spree_store_addresses, :lng, :string
    add_column :spree_store_addresses, :locname, :string
  end
end
