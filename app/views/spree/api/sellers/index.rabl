object false
node(:count) { @sellers.count }
node(:total_count) { @sellers.count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
child @sellers => :sellers do
  attributes :id,:name, :permalink
end