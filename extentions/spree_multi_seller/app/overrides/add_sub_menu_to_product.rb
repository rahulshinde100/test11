Deface::Override.new(:virtual_path => "spree/admin/shared/_product_sub_menu",
                     :name => "admin_approval_request_products",
                     :insert_bottom => "[data-hook='admin_product_sub_tabs']",
                     :text => "<%= tab(:in_active_products, :url => admin_products_path(:in_active => 'true'), :icon => 'unapprove')%>",
                     :disabled => false)