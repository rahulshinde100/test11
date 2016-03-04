Spree::Api::OrdersController.class_eval do
	def create
        # @order = Spree::Order.build_from_api(current_api_user, nested_params)

        # unless current_api_user.nil?
        #   @order.bill_address = current_api_user.orders.complete.blank? ? Spree::Address.default : current_api_user.orders.complete.last.bill_address
        #   @order.ship_address = current_api_user.orders.complete.blank? ? Spree::Address.default : current_api_user.orders.complete.last.ship_address
        # else
        #   @order.bill_address ||= Spree::Address.default
        #   @order.ship_address ||= Spree::Address.default
        # end
        # respond_with(order, :default_template => :show, :status => 201)
    end

	def update
		# @order = Spree::Order.find_by_number(params[:id])

		# @order.line_items.delete_all
		# #authorize! :update, Spree::Order
		# params['order']['line_items'].each_with_index do |li,i|
		# 	@order.line_items.build(:variant_id => li['variant_id'], :quantity => li['quantity'], :price => Spree::Variant.find(li['variant_id']).price.to_f,:is_pick_at_store => li['is_pick_at_store'],:stock_location_id => li['stock_location_id']).save
		# end
  #   session["view"] == "ios"
		# @order = Spree::Order.find_by_number(@order.number)
		# render :show
	end

	def empty
		# @order = Spree::Order.find_by_number(params[:id])
		# if @order
	 #        @order.line_items.destroy_all
	 #        @order.update!
	 #        @response = {:response => "succsess"}
	 #    else
	 #    	@response = {:response => "Order not found"}
	 #    end
	end
end
