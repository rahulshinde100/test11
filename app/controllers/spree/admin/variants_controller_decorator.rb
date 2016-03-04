Spree::Admin::VariantsController.class_eval do
   after_filter :update_rcp, :only => [:create, :update]
   after_filter :update_variants_market_places, :only => [:create, :update, :delete]
   skip_before_filter :load_resource, :only => :get_selected_variant_data

   #load_and_authorize_resource :class => Spree::Product
   def get_selected_variant_data
     @variant = Spree::Variant.where(:id => params[:variant_id]).first
     @sku = @dispatch_no = @variant.sku+"_"+Time.now.strftime('%y%m%d%H%L')
     price = @variant.price
     respond_to do |format|
       format.json  { render :json => {:variant => @variant,
                                      :sku => @sku, :price => price }}
     end
   end

   def get_new_variants
     @search_data = Spree::Variant.includes(:product).create_fba
     @search_data = @search_data.where("spree_products.seller_id = ?", spree_current_user.seller.id) if spree_current_user.has_spree_role? 'seller'
     @search = @search_data.ransack(params[:q])
     @variants = @search.result
     page = params[:page] || 0
     @varianrts = @variants.page params[:page]

     #@varianrts = Spree::Variant.where(:is_created_on_fba => false).page params[:page]
     # @orders = Kaminari.paginate_array(@orders).page(params[:page]).per(params[:per_page] || Spree::Config[:orders_per_page])
     @variants = @varianrts#.page(page)
   end

   def create_on_fba
    # params[:skus] = params[:skus].gsub(/\r\n/,',')
    # @skus = params[:skus].gsub(/\s+/, ',').split(",").reject(&:blank?) rescue []
    # @variants = Spree::Variant.where('sku in (?)',@skus)
     @variants = Spree::Variant.where('id in (?)',params[:skus].split(','))
    # @variants = Spree::Variant.includes(:product).where('sku in (?)',@skus).group('spree_products.seller_id')
    Spree::Variant.transaction do
      @variants.update_all(:is_created_on_fba => true)
      ids = @variants.map(& :id)
      #VariantJob.delay.create_products_on_fba(ids,spree_current_user, 'creating')
      VariantJob.create_products_on_fba(ids,spree_current_user, 'creating')
    end
    # if request.xhr?
    #   redirect_to spree.admin_get_new_variants_path, :notice => "FBA quantity fetch successfully"
    # We are processing your request. We will let you know the status on you given emails.
    # end
   end

   def get_updated_variants
     #@search = Spree::Variant.update_fba.ransack(params[:q])
     @search_data = Spree::Variant.includes(:product).update_fba
     @search_data = @search_data.where("spree_products.seller_id = ?", spree_current_user.seller.id) if spree_current_user.has_spree_role? 'seller'
     @search = @search_data.ransack(params[:q])
     @variants = @search.result
     page = params[:page] || 0
     @varianrts = @variants.page params[:page]
     @variants = @varianrts#.page(page).per(Spree::Config[:admin_products_per_page])

   end

   def update_on_fba
     # params[:skus] = params[:skus].gsub(/\r\n/,',')
     # @skus = params[:skus].gsub(/\s+/, ',').split(",").reject(&:blank?) rescue []
     # @variants = Spree::Variant.where('sku in (?)',@skus)
     @variants = Spree::Variant.where('id in (?)',params[:skus].split(','))
     @search = Spree::Product.new
     Spree::Variant.transaction do
       @variants.update_all(:updated_on_fba => true)
       ids = @variants.map(& :id)
       #VariantJob.delay.create_products_on_fba(ids,spree_current_user, 'updating')
       VariantJob.create_products_on_fba(ids,spree_current_user, 'updating')
     end
   end

   def destroy
     @variant = Spree::Variant.find(params[:id])
     if @variant.destroy
       flash[:success] = Spree.t('notice_messages.variant_deleted')
     else
       flash[:success] = Spree.t('notice_messages.variant_not_deleted')
     end

     respond_with(@variant) do |format|
       format.html { redirect_to admin_product_variants_url(params[:product_id]) }
       format.js  { render_js_for_destroy }
     end
   end

  def update_variants_market_places
    @error_message = []
    @res = nil
    if @object.present? && @object.errors.empty? && (params[:action]=="destroy" || params[:action]=="update" || params[:action]=="create")
      begin
        market_places = @product.market_places
        market_places.each do |mp|
          user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", @product.seller_id, mp.id)
          market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @product.seller_id, mp.id, @product.id)
          if user_market_place.present? && !user_market_place.first.api_secret_key.nil?
            if market_place_product.present? && !market_place_product.first.market_place_product_code.nil?
              option_name = @object.option_values.first.option_type.presentation
              option_value = @object.option_values.first.presentation
              action = (params[:api] && params[:api][:variant_check] == "new" ? "new" : "edit")
              case mp.code
              when "qoo10"
                if params[:action]=="destroy"
                  @res = delete_variant_qoo10(market_place_product.first, user_market_place.first, option_name, option_value)
                # else
                  # @res = @object.update_variant_qoo10(action, market_place_product.first, user_market_place.first, option_name, option_value, @object) if params[:api] && !params[:api][:variant_check].nil?
                  if @res && @res.code == "200"
                  elsif @res
                    res_body = Hash.from_xml(@res.body).to_json
                    res_body = JSON.parse(res_body, :symbolize_names=>true)
                    @error_message << res_body[:StdResult][:ResultMsg]
                  end
                end
              when 'lazada', 'zalora'
                if params[:action]=="destroy"
                  @res = delete_variant_lazada(market_place_product.first, user_market_place.first, option_name, option_value, @object)
                  @error_message << @res if !@res.nil?
                # else
                  # @res = @object.update_variant_lazada(action, market_place_product.first, user_market_place.first, option_name, option_value, @object, @product) if params[:api] && !params[:api][:variant_check].nil?
                end

              end
            else
              @error_message << mp.name+": "+"Market place listing product code is missing"
            end
          end
        end
      rescue Exception => e
        @error_message << e.message
      end
      @error_message = @error_message.compact.reject(&:blank?)
      if @error_message.length > 0
        flash[:error] = @error_message.join("; ")
      else
        flash[:success] = params[:action]=="destroy" ? "Product variant deleted to market places" : "Product variant updated to market places" if @object.errors.empty?
      end
    end
  end

  def delete_variant_qoo10(market_place_product, user_market_place, option_name, option_value)
    begin
      market_place = market_place_product.market_place
      seller_code = market_place_product.product.sku.present? ? market_place_product.product.sku : "" rescue ""
      uri = URI(market_place.domain_url+'/GoodsBasicService.api/DeleteInventoryDataUnit')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code,'SellerCode'=>seller_code.to_s,'OptionName'=>option_name,'OptionValue'=>option_value,'OptionCode'=>''})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
    rescue Exception => e
      res = e.message
    end
    return res
  end

  def delete_variant_lazada(market_place_product, user_market_place, option_name, option_value, object)
    begin
      @object = object
      @res = nil
      Time.zone = "Singapore"
      current_time = Time.zone.now
      user_id = user_market_place.contact_email ? user_market_place.contact_email : "tejaswini.patil@anchanto.com"
      market_place = Spree::MarketPlace.find(user_market_place.market_place_id)
      http = Net::HTTP.new(market_place.domain_url)
      product_params = {"Action"=>"ProductRemove", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
      signature = view_context.generate_lazada_signature(product_params, user_market_place)
      market_place = Spree::MarketPlace.find(user_market_place.id)
      if signature
        formed_params = []
        sorted_params = Hash[product_params.sort]
        sorted_params.merge!("Signature"=>signature)
        sorted_params.each do |key,value|formed_params << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
        param_string = "?"+formed_params.join('&')
        uri = URI.parse(market_place.domain_url+param_string)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Post.new(uri.request_uri)
        xml_obj = {:Product=>{:SellerSku=>@object.sku}}
        request.body = xml_obj.to_xml.gsub("hash", "Request")
        res = http.request(request)
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        if res.code == "200" && res_body[:SuccessResponse]
        else
          @res = user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
        end
      else
        @res = "#{market_place.name}: Signature can not be generated."
      end
    rescue Exception => e
      @res = e.message
    end
    return @res
  end

def reject_change
  p params
  begin
    variant = Spree::Variant.find(params[:variant_id])
    ap variant
    Spree::RecentMarketPlaceChange.where(:product_id => variant.id, :update_on_fba => true).update_all(:deleted_at => Date.today)
    variant.update_attributes(:updated_on_fba => true)
    #variant.updated_on_fba = true
    #variant.save!
    @message = 'All these changes rejected.'
    if request.xhr?
      render :json => @message.to_json
    end
  rescue Exception => e
    p '-------------'
    p e
      res = e.message
  end

end

   # all skus that can be map with new one
   def get_skus
     if params[:id].present?
       @msg = 'nothing'
       respond_to do |format|
         format.json  { render :json => {:variant => @msg }}
         return
       end
     end

     @product = Spree::Product.find(params[:product_id])
     self_parent = @product.variants.map(&:parent_id)
     self_parent << @product.master.id
     self_parent = self_parent.flatten
     @variant = params[:variant]
     @products = @product.seller.products.where(:is_approved=>true)
     @product_hash = []
     @products.each do |product|
       product_variants = []
       product_variants << (product.variants.present? ? product.variants : product.master)
       product_variants = product_variants.flatten
       product_variants.each do |pv|
         if !pv.parent_id.present? && !(self_parent.include? pv.id)
           if pv.option_values.present?
             @product_hash << {:name=> (product.name+" -> "+pv.option_values.first.presentation+" ("+pv.sku.to_s+")"), :id=>pv.id}
           else
             @product_hash << {:name=> (product.name+" ("+pv.sku.to_s+")"), :id=>pv.id}
           end
         end
       end
     end if @products.present?
     @variant = Spree::Variant.new(:product_id => @product.id)
     @variant.attributes = @variant.product.master.attributes.except('id', 'created_at', 'deleted_at',
                                                                   'sku', 'is_master')
     # Shallow Clone of the default price to populate the price field.
     @variant.default_price = @variant.product.master.default_price.clone
     respond_to do |format|
       format.html { render :partial=>"map_variant", :locals => {:product => @product, :variant => @variant}}
     end
   end



   protected
		def update_rcp
		  if @variant.product.seller.type.price_based?
		    @variant.update_attributes(:rcp => @variant.cost_price)
			else
				rcp = (@variant.special_price || @variant.price) * (1 - (@variant.product.seller.revenue_share/100.to_f))
				rcp = (@variant.special_price || @variant.price) * (1 - (@variant.product.seller.revenue_share_on_ware_house_sale/100.to_f)) if @variant.product.is_warehouse
				@variant.update_attributes(:rcp => rcp)
		  end if @variant.product.seller.type.present?
    end
  private
   def search_result
     params[:q] = {} unless params[:q]

     if params[:q][:completed_at_gt].blank?
       params[:q][:completed_at_gt] = Time.zone.now.beginning_of_month
     else
       params[:q][:completed_at_gt] = Time.zone.parse(params[:q][:completed_at_gt]).beginning_of_day rescue Time.zone.now.beginning_of_month
     end

     if params[:q] && !params[:q][:completed_at_lt].blank?
       params[:q][:completed_at_lt] = Time.zone.parse(params[:q][:completed_at_lt]).end_of_day rescue ""
     else
       params[:q][:completed_at_lt] = Time.zone.now.end_of_day
     end
     if params[:q].delete(:completed_at_not_null) == "1"
       params[:q][:completed_at_not_null] = true
     else
       params[:q][:completed_at_not_null] = false
     end

     params[:q][:s] ||= "completed_at desc"
     @file_date = "#{params[:q][:completed_at_gt].to_date}"
     @file_date += "_to_#{params[:q][:completed_at_lt].to_date}" unless params[:q][:completed_at_lt].nil?
     search_result = params[:q]
   end
end
