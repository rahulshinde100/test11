# Added by Tejaswini Patil
# Overrided from Spree email_t0_friend gem
# To hide Captcha menu menu from general settings

Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "add_captcha_admin_option",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :text => "<%= configurations_sidebar_menu_item Spree.t('captcha.captcha_settings'), edit_admin_captcha_settings_path %>",
                     :disabled => true)