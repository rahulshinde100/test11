class AddColumnInvoiceDetailsInOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :invoice_details, :text
  end
end
