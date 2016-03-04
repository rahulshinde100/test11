=begin
Deface::Override.new(:virtual_path => "spree/layouts/admin",
	                 :name => "newsletter_tabs",
	                 :insert_bottom => "[data-hook='admin_tabs'], #admin_tabs[data-hook]",
                     :partial => "spree/admin/shared/newsletter_subscriber_tab",
	                 #:text => "<%= tab 'Newsletter', :url => admin_newsletter_subscribers_path%>",
	                 :disabled => true)

Deface::Override.new(:virtual_path => "spree/admin/shared/_tabs",
	                 :name => "newsletter_tabs",
	                 :insert_after => "[data-hook='news-letter'], #news-letter[data-hook]",
                     :partial => "spree/admin/shared/newsletter_subscriber_tab",
	                 #:text => "<%= tab 'Newsletter', :url => admin_newsletter_subscribers_path%>",
	                 :disabled => false)
	                 
=end