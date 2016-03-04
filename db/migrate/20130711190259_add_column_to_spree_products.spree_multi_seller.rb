# This migration comes from spree_multi_seller (originally 20130711190154)
class AddColumnToSpreeProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :is_reject, :boolean, :default => false
  end
end
