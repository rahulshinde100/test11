Spree::Admin::StockMovementsController.class_eval do
  before_filter :load_stock_location
  
  def authorize_admin
      authorize! params[:action].to_sym, Spree::StockMovement
  end
end
