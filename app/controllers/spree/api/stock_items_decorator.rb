Spree::Api::StockItemsController.class_eval do
  before_filter :stock_location, except: [:update, :destroy, :out_of_stock, :out_of_stock_globally]

	def out_of_stock
    #API body = {:product_id => 1, :stock_item_id => 2}
		@product = Spree::Product.find(params[:product_id])
    stock_item = Spree::StockItem.find(params[:stock_item_id])
    @message = ""
    if stock_item.virtual_out_of_stock?
      stock_item.update_attributes(:virtual_out_of_stock => false)
      @response = {:response => "#{stock_item.variant.name} is available in Stock now"}
    else
      stock_item.update_attributes(:virtual_out_of_stock => true)
      @response = {:response => "#{stock_item.variant.name} is Out of Stock now"}
    end

		#redirect_to stock_admin_product_path(@product)
	end

  #make product OUT OF STOCK Globally
  def out_of_stock_globally
    #API body = {:product_id => 1, :status => true}
    status = params[:status] == "true" ? true : false
    @product = Spree::Product.find(params[:product_id])
    variants = @product.variants.present? ? @product.variants : [@product.master]
    variants.each do |variant|
      Spree::StockItem.where(:variant_id => variant.id).each do |stock_item|
        stock_item.update_attributes(:virtual_out_of_stock => status)
      end
    end
    @response = {:response => status ? "Product #{@product.name} is Out of Stock" : "Product #{@product.name} is Available now"}
		#redirect_to stock_admin_product_path(@product)

  end
end		