Deface::Override.new(:virtual_path => "spree/layouts/admin", 
                     :name => "admin-logo", 
                     :insert_bottom => "[data-hook='logo-wrapper']", 
                     :partial => "spree/shared/change_admin_logo")