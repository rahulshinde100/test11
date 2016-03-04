Spree::Admin::ImagesController.class_eval do
  after_filter :image_upload_market_places
	def destroy
	  @product = Spree::Product.find_by_permalink(params[:product_id])
	  @image = Spree::Image.find(params[:id])
	  @image.destroy
	  redirect_to admin_product_images_url(@product)
	end

  # Upload Images to market places
	def image_upload_market_places
    @error_messages = []
	  if params[:product_image] && params[:product_image][:market_place] && params[:product_image][:market_place] == "1" 
      begin
        image_url = !@object.attachment.nil? && !@object.attachment.blank? ? @object.attachment.url(:original) : (request.host.to_s+":"+request.port.to_s+"/assets/noimage/large.png")
        params[:product_image][:market_place_id].shift
        market_places = []
        params[:product_image][:market_place_id].each do |id|
          market_places << Spree::MarketPlace.find(id)  
        end
        market_places.each do |mp|
          user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", @product.seller_id, mp.id)
          market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @product.seller_id, mp.id, @product.id)
          if user_market_place.present? && !user_market_place.first.api_secret_key.nil?
            if market_place_product.present? && !market_place_product.first.market_place_product_code.nil?
              # case mp.code
              # when 'qoo10'
              #   # image_url = @object && @object.attachment_file_name.split("_").first.capitalize == "qoo10".capitalize ? @object.attachment.url(:original).to_s : (request.host.to_s+":"+request.port.to_s+"/assets/noimage/large.png")
              #   # res = image_update_qoo10(user_market_place.first, market_place_product.first, image_url)
              #   # @error_messages << (res == true ? "" : res)
              # when 'lazada'
              #   # image_url = @object && @object.attachment_file_name.split("_").first.capitalize == "lazada".capitalize ? @object.attachment.url(:original).to_s : (request.host.to_s+":"+request.port.to_s+"/assets/noimage/large.png")
              #   # res = image_update_lazada(user_market_place.first, market_place_product.first, image_url, params)
              #   # @error_messages << (res == true ? "" : res)
              # end
            else
              @error_messages << mp.name+"Market place listing product code is missing"
            end
          else
             @error_messages << mp.name+": Api key or Secret key is missing"
          end
        end
      rescue Exception => e
        @error_messages << e.message
      end
      @error_messages = @error_messages.compact.reject(&:blank?)
      if @error_messages.length > 0
        flash[:error] = @error_messages.join("; ")
      elsif true
        flash[:success] = "Image updated on market places"
      end
	  end
	end

  # Upload image to Qoo10 market place
  def image_update_qoo10(user_market_place, market_place_product, image_url)
    @message = nil
    begin
      seller_code = market_place_product.product.sku.present? ? market_place_product.product.sku : "" rescue ""
      uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/EditGoodsImage')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code,'SellerCode'=>seller_code.to_s,'StandardImage'=>image_url})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
      if res.code != "200"
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        @message = res_body[:StdResult][:ResultMsg]
      end
    rescue Exception => e
      @message = e.message
    end     
    return @message ? @message : true
  end

  # Upload images to Lazada market place
  def image_update_lazada(user_market_place, market_place_product, image_url, params)
    @message = nil
    Time.zone = "Singapore"
    current_time = Time.zone.now
    user_id = user_market_place.contact_email ? user_market_place.contact_email : "tejaswini.patil@anchanto.com"
    http = Net::HTTP.new("https://sellercenter-api.lazada.sg")
    product_params = {"Action"=>"Image", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
    signature = view_context.generate_lazada_signature(product_params, user_market_place)
    if signature
      formed_params = []
      sorted_params = Hash[product_params.sort]
      sorted_params.merge!("Signature"=>signature)
      sorted_params.each do |key,value|formed_params << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
      param_string = "?"+formed_params.join('&')
      uri = URI.parse("https://sellercenter-api.lazada.sg"+param_string)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Post.new(uri.request_uri)
      xml_obj = {}
      xml_obj = xml_obj.compare_by_identity
      variant = Spree::Variant.find(params[:image][:viewable_id])
      if variant.present?
        product = variant.product
        variants = []
        if product.variants.present? && variant.is_master
          variants << product.variants 
        elsif product.variants.present? && !variant.is_master
          variants << variant  
        else
          variants << variant  
        end  
        variants = variants.flatten
        variants.each do |var|
          xml_obj["ProductImage"]={:SellerSku=>var.sku, :Images=>{:Image=>image_url}}
        end
      end
      request.body = xml_obj.to_xml.gsub("hash", "Request")
      res = http.request(request)
      res_body = Hash.from_xml(res.body).to_json
      res_body = JSON.parse(res_body, :symbolize_names=>true)
      if res.code == "200" && res_body[:ErrorResponse]
        @message = user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
      end
    end
    return @message ? @message : true
  end

end
