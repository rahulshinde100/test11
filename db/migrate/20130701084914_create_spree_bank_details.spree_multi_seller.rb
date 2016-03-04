# This migration comes from spree_multi_seller (originally 20130627075110)
class CreateSpreeBankDetails < ActiveRecord::Migration
  def change
    create_table :spree_bank_details do |t|
    	t.string    :name
    	t.string    :branch
    	t.string    :address
    	t.string    :account_number
    	t.string    :ifsc_code
      t.integer   :seller_id
      t.timestamps
    end
  end
end
