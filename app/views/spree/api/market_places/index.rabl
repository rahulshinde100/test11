object false
node(:count) { @market_places.count }
node(:total_count) { @market_places.count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
child @market_places => :market_places do
  attributes :id,:name, :code
end