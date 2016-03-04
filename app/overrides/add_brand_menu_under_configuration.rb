Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "add_configuration_brand",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu'], #admin_configurations_sidebar_menu[data-hook]",
                     :text => "<%= configurations_sidebar_menu_item(Spree.t('brands'), admin_brands_url) %>",
                     :disabled => false)
