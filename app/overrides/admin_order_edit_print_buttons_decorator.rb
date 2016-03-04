Deface::Override.new(:virtual_path => "spree/admin/orders/edit",
                     :name => "print_buttons",
                     :insert_bottom => "[data-hook='admin_order_edit_form']",
                     :partial => "spree/admin/orders/print_buttons",
                     :disabled => false)