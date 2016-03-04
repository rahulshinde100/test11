class AddIsCancelStateToOrder < ActiveRecord::Migration
  def change
    add_column :spree_orders, :cancel_on_fba, :boolean, default:false
  end
end
