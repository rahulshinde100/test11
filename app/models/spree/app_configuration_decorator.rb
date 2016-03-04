Spree::AppConfiguration.class_eval do 
	preference :operating_hours, :time
	preference :cart_item_limit, :integer, default: 10	
	preference :login_necessity, :boolean, :default => false
	preference :store_credit_email_text, :string
	# searcher_class allows spree extension writers to provide their own Search class
    def searcher_class
      @searcher_class ||= Spree::Core::Search::ProductCustomeSearch
    end
end