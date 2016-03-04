Deface::Override.new(:virtual_path => "spree/admin/products/_form", 
                     :name => "add_is_approved",
                     :insert_bottom => "[data-hook='admin_product_form_right']", 
                     :partial => "spree/admin/shared/add_is_approved_to_product")