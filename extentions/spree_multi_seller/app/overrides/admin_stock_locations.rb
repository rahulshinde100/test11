Deface::Override.new(:virtual_path => "spree/admin/shared/_product_sub_menu",
                     :name => "admin_stock_locations",
                     :insert_bottom => "[data-hook='admin_product_sub_tabs']",
                     :text => "<%= tab(:stock_locations, :url => admin_stock_locations_path(:stock_product => 'true'))%>",
                     :disabled => false)