class AddRejectReasonToSpreeProducts < ActiveRecord::Migration
  def change
    add_column :spree_products, :reject_reason, :text
  end
end
