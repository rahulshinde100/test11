Spree::Admin::StockTransfersController.class_eval do
  def authorize_admin
      authorize! params[:action].to_sym, Spree::StockTransfer
  end

  def index
    if spree_current_user.has_spree_role?("admin")
      @q = Spree::StockTransfer.search(params[:q])
    else
      @q = spree_current_user.seller.stock_transfers.search(params[:q])
    end
    @stock_transfers = @q.result.includes(:stock_movements => { :stock_item => :stock_location }).order('created_at DESC').page(params[:page])
  end

  def create
    variants = Hash.new(0)
    params[:variant].each_with_index do |variant_id, i|
      variants[variant_id] += params[:quantity][i].to_i
    end

    seller_id = spree_current_user.has_spree_role?("admin") ? params[:seller_id] : spree_current_user.seller.id
    stock_transfer = Spree::StockTransfer.create(:reference => params[:reference], :seller_id => seller_id)
    stock_transfer.transfer(source_location,destination_location,variants)

    flash[:success] = Spree.t(:stock_successfully_transferred)
    redirect_to admin_stock_transfer_path(stock_transfer)
  end

  private
  def load_stock_locations
    if spree_current_user.has_spree_role?("admin")
      @stock_locations = Spree::StockLocation.active.order('name ASC')
    else
      @stock_locations = spree_current_user.seller.stock_locations.active.order('name ASC')  #Spree::StockLocation.active.order('name ASC')
    end

  end
end
