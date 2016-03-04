Deface::Override.new(:virtual_path => "spree/admin/shared/_product_tabs",
                     :name => "admin_labels",
                     :insert_bottom => "[data-hook='admin_product_tabs']",
                     :text =>	"	<li<%== ' class=\"active\"' if current == 'Labels' %>>
																	<%= link_to t(:labels), selected_admin_product_labels_url(@product) %>
                         				</li>",
                     :disabled => true)