# This migration comes from spree_multi_seller (originally 20130627063936)
class CreateSpreeStoreAddresses < ActiveRecord::Migration
  def change
    create_table :spree_store_addresses do |t|
    	t.integer :seller_id, :null => false
      t.string  :name
    	t.string :address
    	t.string :city, :limit => 30
    	t.string :state, :limit => 30
    	t.integer :country_id, :null => false
    	t.integer :zipcode, :null => false
    	t.string :contact, :null => false
    	t.string :email, :null => false
    	t.string :web_url
      t.string :operating_hours
      t.boolean :pickup_at, :default => false

      t.timestamps
    end
  end
end
