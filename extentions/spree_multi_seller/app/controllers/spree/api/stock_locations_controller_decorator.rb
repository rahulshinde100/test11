Spree::Api::StockLocationsController.class_eval do 

  def index
    spree_current_api_user = defined?(spree_current_user) ? spree_current_user : spree_current_api_user
    if spree_current_api_user.has_spree_role?("admin")
      @stock_locations = Spree::StockLocation.order('name ASC').ransack(params[:q]).result.page(params[:page]).per(params[:per_page])
    else
      @stock_locations = spree_current_api_user.seller.stock_locations.order('name ASC').ransack(params[:q]).result.page(params[:page]).per(params[:per_page])
    end
    respond_with(@stock_locations)
  end

end
