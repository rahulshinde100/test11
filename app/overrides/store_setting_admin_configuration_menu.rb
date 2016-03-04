# Added by Tejaswini Patil
# Overrided from Spree simple_cms gem
# To hide Taxonomy posts & store settings menues from general settings

Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "add_store_settings",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu'], #admin_configurations_sidebar_menu[data-hook]",
                     :text => "<%= configurations_sidebar_menu_item t(:store_settings), edit_admin_store_settings_url %>",
                     :disabled => true)

Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "add_taxonomy_posts",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu'], #admin_configurations_sidebar_menu[data-hook]",
                     :text => "<%= configurations_sidebar_menu_item t(:taxonomy_posts), admin_taxonomy_posts_url %>",
                     :disabled => true)
