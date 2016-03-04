object false
node(:count) { @brands.count }
node(:total_count) { @brands.count }
node(:current_page) { params[:page] ? params[:page].to_i : 1 }
node(:per_page) { params[:per_page] || Kaminari.config.default_per_page }
node(:pages) { @brands.num_pages }
child @brands => :brands do
  attributes *brands_attributes
end