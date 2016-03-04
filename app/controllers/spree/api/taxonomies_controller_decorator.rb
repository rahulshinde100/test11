Spree::Api::TaxonomiesController.class_eval do
	
	def index
		@taxonomies =Spree::Taxonomy.categories.taxons.collect{|taxon| taxon if taxon.parent.present? && taxon.parent.name.capitalize == "categories".capitalize}.compact
		@taxonomies = Kaminari.paginate_array(@taxonomies).page(params[:page])
	end
end
