Spree::Api::TaxonsController.class_eval do 
	def index
		@taxons=[]
		if taxonomy
      @taxons = taxonomy.root.children
    else
      user = defined?(spree_current_user) ? spree_current_user : spree_current_api_user
      if user.has_spree_role? 'admin'
        if params[:ids]
          @taxons = Spree::Taxon.where(:id => params[:ids].split(","))
        else
          @taxons = Spree::Taxon.ransack(params[:q]).result
        end
      else
        ids = []
        user.seller.categories.each{|cat| ids = Spree::Taxon.where("permalink like '%#{cat.permalink}%'")}
        if params[:ids]
          @taxons = Spree::Taxon.where(:id => params[:ids].split(","))
        else
          @taxons = Spree::Taxon.ransack(params[:q]).result.where(:id => ids.map(&:id))
        end
      end
    end
    respond_with(@taxons)
	end
end
