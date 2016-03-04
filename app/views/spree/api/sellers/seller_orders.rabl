object false
node(:count) { @orders.count }
node(:total_count) { @total_count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
node(:pages) { @num_pages }
child @orders => :orders do
  attributes *order_attributes
 
	child :line_items => :line_items do
  		extends "spree/api/line_items/show"
	end
  
end

