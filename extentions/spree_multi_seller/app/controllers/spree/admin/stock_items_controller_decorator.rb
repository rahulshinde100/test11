Spree::Admin::StockItemsController.class_eval do

  def authorize_admin
      authorize! params[:action].to_sym, Spree::StockItem
  end

end