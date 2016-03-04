Spree::Api::CheckoutsController.class_eval do

	def update
		#authorize! :update, @order, params[:order_token]
    if params[:order][:bill_address_attributes]
  		params[:order][:bill_address_attributes].merge!(:country_id => 160)
  		params[:order][:bill_address_attributes].merge!(:state_name => "singapore")
  		params[:order][:ship_address_attributes].merge!(:country_id => 160)
  		params[:order][:ship_address_attributes].merge!(:state_name => "singapore")
  		#ap params[:order]
    end
        order_params = object_params
        user_id = order_params.delete(:user_id)
        if @order.update_attributes(order_params)
          if current_api_user.has_spree_role?("admin") && user_id.present?
            @order.associate_user!(Spree.user_class.find(user_id))
          end
          return if after_update_attributes
          state_callback(:after) if @order.next
          respond_with(@order, :default_template => 'spree/api/orders/show')
        else
          invalid_resource!(@order)
        end
	end

	def delivery_slots
		@order = Spree::Order.find_by_number!(params[:id])
        raise_insufficient_quantity and return if @order.insufficient_stock_lines.present?
        @order.state = params[:state] if params[:state]
        state_callback(:before)

    @delivery_slots = @order.possible_delivery_date

    @order.line_items.each do |line_item|
      if line_item.is_pick_at_store == true && line_item.stock_location
        @pick_up = line_item.stock_location.possible_pickup_dates
      end
    end

	  @shipment_slots =[]
    @pick_up_slots = []
    @total_slots = Hash.new
      @delivery_slots.each do |date|
      @shipment_slots << {"day" => date.split(',')[0], "date" => date.split(',')[1]}
    end

    if @pick_up
      @pick_up.each do |day|
         @pick_up_slots << {"day" => day.split(',')[0], "date" => day.split(',')[1]}
      end
    end

    @total_slots.merge!({"shipment_slots" => @shipment_slots})
    @total_slots.merge!({"pick_up_slots" => @pick_up_slots})
    @total_slots.merge!({"available_slots" =>["1pm-6pm","6pm-8pm","8pm-11pm"]})
	end
end
