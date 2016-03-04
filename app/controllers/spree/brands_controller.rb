module Spree
	class BrandsController < Spree::StoreController
    before_filter :load_retailer
    layout :check_layout
	  def index
      if @seller
        @brands = @seller_products.collect(&:brand).compact.sort_by{|b| b.name}
        @taxons = main_taxons(@seller_products.collect(&:taxons).flatten.uniq)
      else
	  	  @brands = Brand.order(:name)
      end
	  end

	  def show
	  	@brand = Brand.find_by_permalink(params[:id])
      return if @brand.nil?
      @tx_products = @brand.products
      @tx_products = @seller_products.where(:brand_id => @brand.id) if @seller.present?
      @seller_products = @tx_products if @seller.present?
	  	@page = (params[:page].present? ? params[:page] : 1).to_i
	  	@taxons = main_taxons(@tx_products.collect(&:taxons).flatten.uniq).sort_by{|t| -@tx_products.in_taxon(t).count}
	  	@sellers = @tx_products.collect(&:seller).flatten.uniq.sort_by{|s| -@tx_products.where(:seller_id => s.id).count}
	  	@products = @tx_products.page(@page).per(30)
	  	@render_breadcrumb = breadcrumb_path({:brands => brands_path(), :disable => "<span><a href='#{brand_path(@brand)}'>#{@brand.name.capitalize}</a></span>"})
	  	if params[:permalink].present?
        @taxon = Spree::Taxon.find_by_permalink(params[:permalink])
        @products = @tx_products.in_taxon(@taxon) if @taxon.present?
        @tx_products = @products
        @sellers = @products.collect(&:seller).flatten.uniq.sort_by{|s| -@products.where(:seller_id => s.id).count}
        @taxons = @products.collect(&:taxons).flatten.uniq.collect{|tx| tx if tx.parent == @taxon}.flatten.compact.uniq.sort_by{|t| -@products.in_taxon(t).count}
        @render_breadcrumb = breadcrumb_path({:brands => brands_path, "#{@brand.name.capitalize}" => brand_path(@brand), :disable => "<span><a href='#{brands_taxon_path(@brand, @seller.permalink)}'>#{@seller.name.capitalize}</a></span>"}) if @seller.present?
      end
      @sorted_taxons = @taxons.sort_by{|t|}
      @sorted_sellers = @tx_products.collect(&:seller).compact.uniq.sort_by{|s| s.name } unless @seller.present?
      @products = sort(@products, params[:sort].strip.downcase, params[:seq].downcase) if params[:sort].present?
      @products = Kaminari.paginate_array(@products).page(@page).per(30)
	  	if request.xhr?
        render :partial => "/spree/products/load_product"
        return
      end
	  end
	 protected
    def main_taxons(taxons)
      main_taxons = []
      taxons.each do |taxon|
        next if taxon.get_parent.name == "Categories"
        main_taxons << taxon.get_parent
      end
      main_taxons.compact.uniq
    end
	end
end
