object false
child(@taxonomies => :taxonomies) do
   attributes *taxonomy_attributes
    child :children => :taxons do
      attributes *taxon_attributes
    end
  end

node(:count) { @taxonomies.count }
node(:current_page) { params[:page] || 1 }
node(:pages) { @taxonomies.num_pages }