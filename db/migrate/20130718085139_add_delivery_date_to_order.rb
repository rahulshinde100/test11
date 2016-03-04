class AddDeliveryDateToOrder < ActiveRecord::Migration
  def change
    add_column :spree_orders, :delivery_date, :date
    add_column :spree_orders, :delivery_time, :string
    add_column :spree_line_items, :item_pickup_at, :date
  end
end
