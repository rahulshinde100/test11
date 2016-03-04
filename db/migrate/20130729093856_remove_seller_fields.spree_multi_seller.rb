# This migration comes from spree_multi_seller (originally 20130729093101)
class RemoveSellerFields < ActiveRecord::Migration
  def up
  	remove_column :spree_sellers, :business_type_id
  	remove_column :spree_sellers, :paypal_account_email
  	remove_column :spree_stock_locations, :web_url
  	add_column :spree_stock_locations, :contact_person_name, :string
  	add_column :spree_bank_details, :account_name, :string
    change_column :spree_line_items, :item_pickup_at, :date
    change_column(:spree_product_properties, :value, :text)
  end

  def down
  	add_column :spree_sellers, :business_type_id, :integer
  	add_column :spree_sellers, :paypal_account_email, :string
  	add_column :spree_stock_locations, :web_url, :string
  	remove_column :spree_stock_locations, :contact_person_name
  	remove_column :spree_bank_details, :account_name
    change_column :spree_line_items, :item_pickup_at, :string
    change_column(:spree_product_properties, :value, :string)
  end
end
