object false
node(:count) { @products.total_count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:pages) { @products.num_pages }
child @products => :products do
  extends "spree/api/products/show"
  child :tax_category do
  	attributes :id,:name
  end
  child :shipping_category do
  	attributes :id,:name
  end
end