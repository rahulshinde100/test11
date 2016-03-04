class AddIsSendAsGiftToSpreeOrders < ActiveRecord::Migration
  def change
  	add_column :spree_orders, :send_as_gift, :boolean, :default => false
    add_column :spree_orders, :greating_message, :string
  end
end
