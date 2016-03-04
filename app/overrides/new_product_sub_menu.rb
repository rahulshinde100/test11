# Added by Tejaswini Patil
# To create new product sub menu asper requirement

Deface::Override.new(:virtual_path => "spree/admin/shared/_product_sub_menu",
	                 :name => "new_product_sub_menu",
	                 :replace_contents => "[data-hook='admin_product_sub_tabs']",
                     :partial => "spree/admin/shared/new_product_sub_menu",
	                 :disabled => false)