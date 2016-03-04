# This migration comes from spree_multi_seller (originally 20130712100636)
class AddRejectReasonToSpreeProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :reject_reason, :text
  end
end
