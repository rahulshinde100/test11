Deface::Override.new(:virtual_path => "spree/admin/shared/_tabs",
                     :name => "labels_admin_tab_root",
                     :replace_contents => "code[erb-loud]:contains('tab :products')",
                     :text => "tab :products, :option_types, :properties, :prototypes, :variants, :product_properties, :taxons, :reviews, :labels, :icon => 'icon-th-large'"
                    )