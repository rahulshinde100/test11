module Spree
  ProductsController.class_eval do
    include BaseHelper
    before_filter :load_retailer
    layout :check_layout
    def index
      @searcher = build_searcher(params)
      if @seller
        @taxons = @categories.collect(&:children).flatten
        @products = @seller_products
      else
        @products = Spree::Product.active.futured
        @taxons = Spree::Taxon.main_taxons
      end unless params[:keywords].present?
      @products = @searcher.retrieve_products if params[:keywords].present?
      @page = (params[:page].present? ? params[:page] : 1).to_i
      if params[:keywords].present?
        Spree::SearchTerm.transaction do
          search_term = Spree::SearchTerm.create!(:search_term => params[:keywords], :user_id => spree_current_user.try(:id), :result_count => @products.count)
        end
      end
      if request.xhr?
        respond_to do |format|
          format.js #{render 'index'}
        end
        return
      end
    end

    def search
      if @seller.present?
        @products = @seller_products.search(:name_cont => params[:keywords]).result.collect{|r| {:cast => "Products",:url => nil, :name => r.name.truncate(30)}}#.map(&:name)
        @products += @categories.collect(&:children).flatten.collect{|r| {:cast => "Category",:url => seo_url(r), :name => r.name.truncate(30)} if r.name.downcase.include? params[:keywords].downcase }.compact
        #.map(&:name).map{|n| n if n.downcase.include? params[:keywords].downcase}.compact
        # @products += Spree::ProductProperty.search(:value_cont => params[:keywords]).result.map(&:value)
      else
        @products = Spree::Product.active.search(:name_cont => params[:keywords]).result.collect{|r| {:cast => "Products",:url => nil, :name => r.name.truncate(30)}} #.map(&:name)
        @products += Spree::Taxon.search(:name_cont => params[:keywords]).result.collect{|r| {:cast => "Category",:url => seo_url(r), :name => r.name.truncate(30)}} #.map(&:name)
        @products += Spree::Seller.is_active.search(:name_cont => params[:keywords]).result.collect{|r| {:cast => "Seller",:url => root_url(:subdomain => r.permalink), :name => r.name.truncate(30)}} #map(&:name)
        @products += Spree::ProductProperty.search(:value_cont => params[:keywords]).result.collect{|r| {:cast => "Property",:url => nil, :name => r.value.truncate(30)}} #.map(&:value)
      end
      render :json => @products.uniq.to_json
      return
    end

    def show
      if @seller
        @products = @seller_products
      end
      return unless @product
      if request.subdomain.present? && request.subdomain != "www"
        @render_breadcrumb = breadcrumb_path({@product.taxons.first.name => seo_url(@product.taxons.first),:disable => "<span><a href='#'>#{@product.name}</a></span>"})
      else
        unless @product.taxons.first.parent.name.capitalize == "categories".capitalize
          @render_breadcrumb = breadcrumb_path({@product.taxons.first.parent.name => seo_url(@product.taxons.first.parent),@product.taxons.first.name => seo_url(@product.taxons.first),:disable => "<span><a href='#'>#{@product.name}</a></span>"})
        else
          @render_breadcrumb = breadcrumb_path({@product.taxons.first.parent.name => seo_url(@product.taxons.first.parent),@product.taxons.first.parent.name => seo_url(@product.taxons.first.parent),:disable => "<span><a href='#'>#{@product.name}</a></span>"})
        end
      end

      @variants = @product.variants_including_master.active(current_currency).includes([:option_values, :images])
      @product_properties = @product.product_properties.includes(:property)

      referer = request.env['HTTP_REFERER']
      if referer
        begin
          referer_path = URI.parse(request.env['HTTP_REFERER']).path
          # Fix for #2249
        rescue URI::InvalidURIError
          # Do nothing
        # else
        #   if referer_path && referer_path.match(/\/t\/(.*)/)
        #     @taxon = Taxon.find_by_permalink($1)
        #   end
        #   @taxon = Taxon.find_by_permalink(params[:taxon]) if params[:taxon].present?
        end
      else
        @taxon = Taxon.find_by_permalink(params[:taxon]) if params[:taxon].present?
      end
    end

    def notify
    	@product = Spree::Product.find_by_permalink(params[:id])
    	@variant = @product.variants.present? ? @product.variants.find(params[:variant_id]) : @product.master

    	respond_to :js
    end

    def shipli_sale
        @render_breadcrumb = breadcrumb_path({:disable => "<span><a href='#{shipli_sale_path}'>Discounts</a></span>"})
        @heading = "Discounts"
        @page = (params[:page].present? ? params[:page] : 1).to_i
        @tx_products = Spree::Product.active.sale_products
        # @tx_products = Spree::Product.sale_products.unscoped.active if params[:sort].present?
        @taxons = @tx_products.collect(&:taxons).flatten.uniq.sort_by{|t| -@tx_products.in_taxon(t).count}
        @taxons = main_taxons(@taxons)
        if params[:id].present?
          @taxon = Spree::Taxon.find_by_permalink(params[:id])
          @tx_products = @tx_products.in_taxon(@taxon) if @taxon.present?
          @taxons = @taxon.children & @tx_products.collect(&:taxons).flatten.uniq
        end
        products = sort(@tx_products, params[:sort].strip.downcase, params[:seq].downcase) if params[:sort].present?
        @products = Kaminari.paginate_array(products || @tx_products).page(@page).per(30)
        @total_products = @products.num_pages
        if request.xhr?
          render :partial => "/spree/products/load_product"
          return
        end
    end

    def warehouse_sale
      @render_breadcrumb = breadcrumb_path({:disable => "<span><a href='#{warehouse_sale_path}'>Warehouse Sale</a></span>"})
      @page = (params[:page].present? ? params[:page] : 1).to_i
      @tx_products = Spree::Product.active.warehouse_sale
      if params[:brand].present?
        brand = Spree::Brand.find_by_permalink(params[:brand])
        @tx_products = Spree::Product.active.warehouse_sale.where(:brand_id => brand.id) if brand.present?
      elsif params[:retailer].present?
        @b_seller = Spree::Seller.find_by_permalink(params[:retailer])
        @tx_products = Spree::Product.active.warehouse_sale.where(:seller_id => @b_seller.id) if @b_seller.present?
      end
      # @tx_products = Spree::Product.unswarehouse_sale.active if params[:sort].present?
      @taxons = @tx_products.collect(&:taxons).flatten.compact.uniq
      @taxons = main_taxons(@taxons).sort_by{|t| -@tx_products.in_taxon(t).count}
      if params[:id].present?
        @taxon = Spree::Taxon.find_by_permalink(params[:id])
        @tx_products = @tx_products.in_taxon(@taxon) if @taxon.present?
        @taxons = @taxon.children & @tx_products.collect(&:taxons).flatten.uniq.sort_by{|t| -@tx_products.in_taxon(t).count}
      end
      @sorted_taxons = @taxons.sort_by{|t|}
      unless brand.present?
        @brands = @tx_products.collect(&:brand).flatten.compact.uniq.sort_by{|b| -@tx_products.where(:brand_id => b.id).count}
        @sorted_brands = @brands.sort_by{|b| b.name }
      end
      unless @b_seller.present?
        @sellers = @tx_products.collect(&:seller).flatten.compact.uniq.sort_by{|s| -@tx_products.where(:seller_id => s.id).count}
        @sorted_sellers = @sellers.sort_by{|s| s.name }
      end
      products = sort(@tx_products, params[:sort].strip.downcase, params[:seq].downcase) if params[:sort].present?
      @products = Kaminari.paginate_array(products || @tx_products).page(@page).per(30)
      @total_products = @products.num_pages
      @heading = "Warehouse Sale"
      if request.xhr?
        render :partial => "/spree/products/load_product"
      else
        render :action => "shipli_sale"
        return
      end
    end

    def stores
    	@product = Spree::Product.find_by_permalink(params[:id])
			variant = @product.variants.present? ? @product.variants.find(params[:variant_id]) : @product.master
			locations = []
			variant.stock_locations.each do |store|
				next if store.stock_items.find_by_variant_id(variant.id).count_on_hand <= 0 || !store.pickup_at || store.stock_items.find_by_variant_id(variant.id).virtual_out_of_stock?
				store.update_lat_lng if store.lng.nil? or store.lat.nil?
				location ={
					"id" => "#{store.id}",
          "name" => "#{store.name}",
					"locname" => "#{store.try(:locname)}",
					"lat" => "#{store.try(:lat)}",
					"lng" => "#{store.try(:lng)}",
					"address" => "#{store.try(:address1)}",
					"address2" => "#{store.try(:address2)}",
					"city" => "#{store.try(:city)}",
					"state" => "#{store.try(:state)}",
					"postal" => "#{store.try(:zipcode)}",
					"phone" => "#{store.try(:phone)}",
					"web"	=> "",
					"hours1" => "#{store.try(:operating_hours)}",
					"hours2" => "",
					"hours3" => ""
				}
				locations << location
			end if variant.stock_locations.present?
			render :json => locations.to_json
      return
		end
		
		# Fetch quantity from FBA for all sellers
    def fetch_fba_quantity
      sellers = Spree::Seller.all
      sellers.each do |seller|
        begin
          @res = view_context.update_stock_for_seller(seller, true)
        rescue Exception => e
          
        end  
      end  
      redirect_to :back, :notice => "FBA quantity fetch successfully"  
    end

    # Callback url for the stock change in FBA    
    def stock_updates
      my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
      errors = []
      notification_array = []
      if params["products"].present?
        ApiJob.fba_stock_received(params)
      else
        notification_array << ['',"No Products found",'',true]
        errors << "No Products found"  
      end
      Spree::DataImportMailer::stock_update_notification(notification_array).deliver if notification_array.present?
      #view_context.update_stock_market_places(stock_values) if stock_values.present?  
      if errors.empty?
        respond_to do |format|
          format.json { render :status => 200, :json => {:success => "true", :message => "Stock updated successfully!" }}
        end
      else
        respond_to do |format|
          format.json { render :status => 200, :json => {:success => "false", :message => errors.join("; ") }}
        end
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
