Deface::Override.new(:virtual_path => "spree/layouts/spree_application",
                     :name => "add_slider_home_page",
                     :insert_before => "div#wrapper",
                     :partial => "spree/shared/slider_home",
                     :disabled => false)