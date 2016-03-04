Deface::Override.new(:virtual_path => "spree/admin/products/new", 
                     :name => "add_seller_fileds",
                     :insert_bottom => "[data-hook='new_product_attrs']", 
                     :partial => "spree/admin/shared/add_fields_to_product")