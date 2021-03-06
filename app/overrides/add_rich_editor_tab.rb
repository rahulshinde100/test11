# Added by Tejaswini Patil
# Overrided from Spree Editor gem
# To hide Rich editor menu from general settings
Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "add_rich_editor_tab",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu'], #admin_configurations_sidebar_menu[data-hook]",
                     :text => "<li<%== ' class=\"active\"' if controller.controller_name == 'editor_settings' %>><%= link_to Spree.t(:rich_editor), edit_admin_editor_settings_path %></li>",
                     :disabled => true)