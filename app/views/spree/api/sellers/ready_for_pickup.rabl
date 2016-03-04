object false
child @order => :order do
  attributes *order_attributes
 
  child @order.seller_line_items(@seller) => :line_items  do
      extends "spree/api/line_items/show"
  end
  
end
