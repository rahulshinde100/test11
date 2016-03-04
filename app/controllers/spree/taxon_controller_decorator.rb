Spree::TaxonsController.class_eval do
  before_filter :load_retailer
  layout :check_layout
  def show
   @avoid_promo = false
    @sort_option = [["Name -- A to Z", "name_asc"], ["Name -- Z to A", "name_desc"],["Price -- High to Low", "price_desc"],["Price -- Low to High", "price_asc"], ["Disc -- High to Low", "disc_desc"], ["Disc -- Low to High", "disc_asc"]]
    @taxon = Spree::Taxon.find_by_permalink!(params[:id])    
    @limit = 9 #make it 9 instead of 10, first position will be taken by Promo
    
    @taxon_children = @taxon.children
    @is_parent_taxon = is_parent_taxon

    unless @seller.present? #taxons pages only, no seller associated
      @load_products = params[:sort].present? ? Spree::Product.unscoped.active.in_taxon(@taxon) : Spree::Product.active.in_taxon(@taxon).order("spree_products.created_at desc")
      #LHS START
      @sellers = @load_products.collect(&:seller).compact.uniq.sort_by{|s| -@load_products.where(:seller_id => s.id).count}
      @sorted_sellers = @load_products.collect(&:seller).compact.uniq.sort_by{|s| s.name }
      #LHS END
      #@taxon_children = @taxon.children #.collect{|taxon| taxon if @tx_products.in_taxon(taxon).present?}.compact
    else #for seller's taxon pages
      @sellers = nil
      @render_breadcrumb = breadcrumb_path({:disable => "<span><a href='#'>#{@taxon.name}</a></span>"})      
      @load_products = params[:sort].present? ? @seller_products.unscoped.in_taxon(@taxon) : @seller_products.in_taxon(@taxon).order("spree_products.created_at desc")
      @categories = [@taxon]
    end

    #LHS START
    @taxons = @taxon.children.sort_by{|t| -@load_products.in_taxon(t).count}
    @sorted_taxons = @taxon.children.sort_by{|t|}
    @brands = @load_products.collect(&:brand).compact.uniq.sort_by{|b| -@load_products.where(:brand_id => b.id).count}
    @sorted_brands = @load_products.collect(&:brand).compact.uniq.sort_by{|b| b.name }
    #LHS END
    if @is_parent_taxon
      @page = (params[:page].present? ? params[:page] : 1).to_i
      @products = params[:sort].present? ? sort(@load_products, params[:sort].strip.downcase, params[:seq].downcase) : @load_products.sort_by{|p| -p.warehouse_discount}.flatten
      count = 29 #request.xhr? ? 31 : 29
      @products = Kaminari.paginate_array(@products).page(@page).per(count)
      @total_pages = @products.total_pages
      if request.xhr?
        @avoid_promo = true
        render :partial => 'spree/shared/product_new', :locals => { :products => @products, :taxon => @taxon }
        return
      end
    else
      @products = @load_products
      product_count = @products.count
      @total_pages = (product_count%30 == 0 ? product_count/30 : (product_count/30 + 1))   #@products.total_pages
    end

  end


  def taxon_products
    @taxon = Spree::Taxon.find(params[:taxon_id])
    @limit = 9#make it 9 instead of 10, first position will be taken by Promo
    return unless @taxon
    unless @seller.present?
      #@tx_products = Spree::Product.active.in_taxon(@taxon).order("spree_products.created_at desc")
      @tx_products = params[:sort].present? ? Spree::Product.unscoped.active.in_taxon(@taxon).limit(@limit) : Spree::Product.active.in_taxon(@taxon).order("spree_products.created_at desc").limit(@limit)
      @taxon_children = @taxon.children.collect{|taxon| taxon if @tx_products.in_taxon(taxon).present?}.compact
    else
      @categories = [@taxon]
      @taxon_children = @taxon.children
      #@tx_products = @seller_products.in_taxon(@taxon).order("spree_products.created_at desc")
      @tx_products = params[:sort].present? ? @seller_products.unscoped.in_taxon(@taxon).limit(@limit) : @seller_products.in_taxon(@taxon).order("spree_products.created_at desc").limit(@limit)
    end
    @products = @tx_products.sort_by{|p| -p.warehouse_discount}.flatten
    @page = (params[:page].present? ? params[:page] : 1).to_i

    @products = sort(@tx_products, params[:sort].strip.downcase, params[:seq].downcase) if params[:sort].present?

    #@products = Kaminari.paginate_array(@products).page(@page).per(30)
    #@total_pages = @products.total_pages

    if @products.blank?
      render :nothing => true
    else
      render :partial => 'spree/shared/product_new', :locals => { :products => @products, :taxon => @taxon}
    end
    return
  end

  def is_parent_taxon
    (@taxon.parent.try(:name) == @taxon.get_parent_taxon || @taxon_children.blank?)
  end
  
end