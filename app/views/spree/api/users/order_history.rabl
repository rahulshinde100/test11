	object false
	node(:count) { @orders.count }
	node(:total_count) { @orders.count }
	node(:current_page) { params[:page] ? params[:page].to_i : 1 }
	node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
	child @orders => :orders do
	 attributes *order_attributes
	end
