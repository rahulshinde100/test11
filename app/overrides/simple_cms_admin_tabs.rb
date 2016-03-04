Deface::Override.new(:virtual_path => "spree/layouts/admin",
                     :name => "cms_tab",
                     :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",                     
                     :text => "<%= dropdow_tab(:cms, :childs => ['static_pages', 'posts', 'uploads'], :icons => ['icon-book', 'icon-comments', 'icon-upload'], :class => 'dropdown-menu') if spree_current_user.has_spree_role? 'admin'%>",
                     :disabled => 'true')

Deface::Override.new(:virtual_path => "spree/admin/shared/_tabs",
                     :name => "cms_tab",
                     #:insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :insert_after => "[data-hook='cms'], #cms[data-hook]",
                     :text => "<%= dropdow_tab(:cms, :childs => ['static_pages', 'posts', 'uploads'], :icons => ['icon-book', 'icon-comments', 'icon-upload'], :class => 'dropdown-menu') if spree_current_user.has_spree_role? 'admin'%>")