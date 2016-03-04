object false
node(:count) { @products.count }
node(:total_count) { @products.count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
child @products => :products do
  attributes :id,:name
end