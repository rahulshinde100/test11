Deface::Override.new(:virtual_path => "spree/admin/products/_form", 
                     :name => "add_company_and_website_name",
                     :insert_bottom => "[data-hook='admin_product_form_right']", 
                     :partial => "spree/admin/shared/add_extra_fields_to_product")