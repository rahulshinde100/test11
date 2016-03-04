Spree::Admin::ProductsHelper.module_eval do
  require 'openssl'
  require "base64"
  # Added by Nitin Khairnar on Jan 12, 2015

  # Listing product on qoo10
  def listing_product_qoo10(id, params, object, user_market_place, taxon_market_places, market_place_product)
    @object = object
    @error_message = []
    begin
      adult = @object.is_adult ? 'Y' : 'N'
      item_title = params[:product][:name] if params.present?
      item_title = @object.name if !params.present?
      image_url = ""
      if !@object.variant_images.nil? && !@object.variant_images.blank?
        size = 0
        @object.variant_images.each do |mg|
          if mg.attachment_file_name.split("_").first.capitalize == "qoo10".capitalize && size < mg.attachment_file_size
            image_url = mg.attachment.url(:original)
            size = mg.attachment_file_size
          end
        end
      end
      image_url = image_url.present? ? image_url : (request.host.to_s+":"+request.port.to_s+"/assets/noimage/large.png")
      item_description = object.description_details("qoo10")
      item_title = object.title_details("qoo10")
      @item_type = ""
      product_price_details = @object.master.price_details("qoo10")
      @object.variants.each do |v|
        price_details = v.price_details("qoo10")
        product_selling_price = @object.selling_price.present? ? @object.selling_price : @object.price
        variant_selling_price = price_details["selling_price"]
        price = variant_selling_price.to_f - product_selling_price.to_f
        @item_type = @item_type + v.option_values.first.option_type.presentation + "||*"
        @item_type = @item_type + v.option_values.first.presentation + "||*" + price.to_s + "||*"
        @item_type = @item_type + v.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand).to_s + "||*"+ (v.sku.present? ? v.sku.to_s : "0")
        @item_type = @item_type + ((v == @object.variants.last) ? "" : "$$")
      end if @object.variants.present?
      item_type = @item_type #'Color/Size||*White/100||*1000||*10||*0$$Color/Size||*Black/100||*1000||*10||*0'
      retail_price = params[:product][:price] if params.present?
      retail_price = @object.price if !params.present?
      item_price = params[:product][:selling_price].present? ? params[:product][:selling_price] : params[:product][:price] if params.present?
      item_price = @object.selling_price || @object.price if !params.present?
      item_quantity = 0#@object.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand)
      expiry_date = (Time.now + 1.year).strftime("%Y-%m-%d")
      shipping_no = user_market_place.shipping_code.to_s #"418422" # '0' :=> 'Free Shiping', '400896' :=> 'Free on condition' where '400896' is SR code of Qoo10 backend for Others, '418422' :=> 'Free on condition' where '418422' is SR code of Qoo10 backend for Qxpress.
      seller_code = market_place_product.product.sku.present? ? market_place_product.product.sku : "" rescue ""
      uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/SetNewGoods')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'SecondSubCat'=>taxon_market_places.market_place_category_id.to_s,'ManufactureNo'=>'','BrandNo'=>'','ItemTitle'=>item_title["title"].to_s,'SellerCode'=>seller_code.to_s,'IndustrialCode'=>'','ProductionPlace'=>'','AudultYN'=>adult.to_s,'ContactTel'=>'','StandardImage'=>image_url.to_s,'ItemDescription'=>item_description["description"].to_s,'AdditionalOption'=>'','ItemType'=>item_type.to_s,'RetailPrice'=>retail_price.to_s,'ItemPrice'=>item_price.to_s,'ItemQty'=>item_quantity.to_s,'ExpireDate'=>expiry_date.to_s,'ShippingNo'=>shipping_no.to_s,'AvailableDateType'=>'','AvailableDateValue'=>''})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
      if res.code == "200"
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        if res_body[:StdCustomResultOfGoodsResultModel][:ResultCode].to_i >= 0
          mp_product_code = res_body[:StdCustomResultOfGoodsResultModel][:ResultObject][:GdNo]
          market_place_product.update_attributes(:market_place_product_code=>mp_product_code) if market_place_product.present?
        else
          return res_body
          @error_message << user_market_place.market_place.name+": "+ res_body[:StdCustomResultOfGoodsResultModel][:ResultMsg]
        end
      else
        return res
        @error_message << user_market_place.market_place.name+": "+ res.message
      end
    rescue Exception => e
      return e
      @error_message << user_market_place.market_place.name+": "+e.message
    end
    return @error_message.length > 0 ? @error_message.join("; ") : true
  end

  # Update product on qoo10
  def update_product_qoo10(id, params, object, user_market_place, taxon_market_places, market_place_product, old_description, old_price, old_special_price)
    @error_message = []
    @object = object
    begin
      retail_price = params[:product][:price]
      item_description = object.description_details("qoo10")
      item_title = object.title_details("qoo10")
      shipping_no = user_market_place.shipping_code.to_s 
      seller_code = market_place_product.product.sku.present? ? market_place_product.product.sku : "" rescue ""
      uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/UpdateGoods')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code,'SecondSubCat'=>taxon_market_places.market_place_category_id.to_s,'ManufactureNo'=>'','BrandNo'=>'','ItemTitle'=>item_title["title"].to_s,'SellerCode'=>seller_code.to_s,'IndustrialCode'=>'','ProductionPlace'=>'','ContactTel'=>'','RetailPrice'=>retail_price.to_s,'ShippingNo'=>shipping_no.to_s,'AvailableDateType'=>'','AvailableDateValue'=>''})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
      if res.code == "200"
          uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/EditGoodsContents')
          req = Net::HTTP::Post.new(uri.path)
          req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code,'SellerCode'=>seller_code.to_s,'Contents'=>item_description["description"].to_s})
          res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
          if res.code != "200"
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=>true)
            @error_message << user_market_place.market_place.name+": "+res_body[:StdResult][:ResultMsg]
          end
        #if params[:product][:special_price].to_f != old_special_price.to_f
          item_qty = @object.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand)
          uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsOrderService.api/SetGoodsPrice')
          req = Net::HTTP::Post.new(uri.path)
          req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code,'SellerCode'=>seller_code.to_s,'ItemPrice'=>params[:product][:selling_price].to_s,'ItemQty'=>item_qty,'ExpireDate'=>''})
          res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
          if res.code != "200"
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=>true)
            @error_message << user_market_place.market_place.name+": "+res_body[:StdResult][:ResultMsg]
          end
        #end
        #if params[:product][:special_price] != old_special_price
          discount_type = (params[:product][:special_price].nil? || (!params[:product][:special_price].nil? && params[:product][:special_price].to_f == 0.0)) ? 0 : 1
          s_sday = Time.now.strftime("%Y-%m-%d")
          s_eday = (Time.now+1.year).strftime("%Y-%m-%d")
          discounted_price = (params[:product][:selling_price].to_f - params[:product][:special_price].to_f).to_s
          # uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/UpdateItemDiscount')
          # req = Net::HTTP::Post.new(uri.path)
          # req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code,'SellerCode'=>seller_code.to_s,'s_sday'=>s_sday.to_s,'s_eday'=>s_eday.to_s,'s_cost_price'=>discounted_price,'discount_type'=>discount_type.to_s})
          # res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
          # if res.code != "200"
            # res_body = Hash.from_xml(res.body).to_json
            # res_body = JSON.parse(res_body, :symbolize_names=>true)
            # @error_message << user_market_place.market_place.name+": "+res_body[:StdResult][:ResultMsg]
          # end
        #end
      else
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        @error_message << user_market_place.market_place.name+": "+res_body[:StdResult][:ResultMsg]
      end
    rescue Exception => e
        @error_message << user_market_place.market_place.name+": "+e.message
    end
    return @error_message.length > 0 ? @error_message.join("; ") : true
  end

  # Listing product on Lazada
  def listing_product_lazada(id, params, object, user_market_place, taxon_market_places, market_place_product)
    p '----------- Listing product on lazada'
    @object = object
    @error_message = []
    image_arr = []
    variants = []
    variants << (@object.variants.present? ? @object.variants : @object.master)
    variants = variants.flatten
    begin
      Time.zone = "Singapore"
      current_time = Time.zone.now
      user_id = user_market_place.contact_email ? user_market_place.contact_email : "tejaswini.patil@anchanto.com"
      market_place = Spree::MarketPlace.find(user_market_place.market_place_id)
      http = Net::HTTP.new(market_place.domain_url)
      product_params = {"Action"=>"ProductCreate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
      signature = ApiJob.generate_lazada_signature(product_params, user_market_place)
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
        xml_obj = {}
        img_xml_obj = {}
        xml_obj = xml_obj.compare_by_identity
        img_xml_obj = img_xml_obj.compare_by_identity
        variants.each do |variant|
          #Product params details
          item_description = object.description_details(makret_palce.code)
          item_title = object.title_details(market_place.code)
          price_details = variant.price_details(market_place.code)
          brand = (@object.brand ? @object.brand.name : "3M")
          price = variant.price.to_f
          primary_category = taxon_market_places.market_place_category_id.to_i
          category = ''
          seller_sku = variant.sku
          parent_sku = ''
          tax_class = 'default'
          sale_price = ((price_details["special_price"].present? && price_details["special_price"].to_i > 0) ? price_details["special_price"] : "")
          sale_start_date = (@object.available_on ? @object.available_on : Time.now())
          sale_end_date = ''
          shipment_type = 'dropshipping'
          product_id = ''
          conditon = 'new'
          product_data = ''
          quantity = 0#@object.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand)
          name = (object.variants.present? ? (item_title["title"].to_s+"-"+variant.option_values.first.presentation.to_s) : item_title["title"].to_s)
          description = item_description["description"]
          short_desc = item_description["meta_description"]
          package_content = item_description["package_content"]
          height = variant.height.to_f
          weight = variant.weight.to_f
          length = variant.depth.to_f
          width = variant.width.to_f
          xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :Categories=>category, :SellerSku=>seller_sku, :ParentSku=>'', :TaxClass=>tax_class, :Variation=>'', :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type, :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data, :Quantity=>quantity,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content, :PackageHeight=>height, :PackageLength=>length, :PackageWidth=>width, :PackageWeight=>weight}}
          # Image hash
          variant.images.each do |image|
            image_arr << image.attachment.url(:original).to_s if image.attachment_file_name.split("_").first.capitalize == market_place.code.capitalize
          end
          @object.images.each do |image|
            image_arr << image.attachment.url(:original).to_s if image.attachment_file_name.split("_").first.capitalize == market_place.code.capitalize
          end
          img_xml_obj["ProductImage"]={:SellerSku=>seller_sku, :Images=>image_arr} if !image_arr.blank?
        end # end of variant loop
        request.body = xml_obj.to_xml.gsub("hash", "Request")
        res = http.request(request)
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        p res_body
        if res.code == "200" && res_body[:SuccessResponse]
          mp_product_code = res_body[:SuccessResponse][:Head][:RequestId]
          market_place_product.update_attributes(:market_place_product_code=>mp_product_code) if market_place_product.present?
          # Adding images
          image_params = {"Action"=>"Image", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
          img_signature = ApiJob.generate_lazada_signature(image_params, user_market_place)
          img_formed_params = []
          img_sorted_params = Hash[image_params.sort]
          img_sorted_params.merge!("Signature"=>img_signature)
          img_sorted_params.each do |key,value|img_formed_params << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
          img_param_string = "?"+img_formed_params.join('&')
          img_uri = URI.parse(market_place.domain_url+img_param_string)
          img_http = Net::HTTP.new(img_uri.host, img_uri.port)
          img_http.use_ssl = true
          img_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          img_request = Net::HTTP::Post.new(img_uri.request_uri)
          img_request.body = img_xml_obj.to_xml(:skip_types=>true).gsub("hash", "Request")
          img_res = http.request(img_request)
          img_res_body = Hash.from_xml(img_res.body).to_json
          img_res_body = JSON.parse(img_res_body, :symbolize_names=>true)
          if img_res.code == "200" && img_res_body[:ErrorResponse]
            return img_res_body[:ErrorResponse][:Head][:ErrorMessage]
            @error_message << user_market_place.market_place.name+": "+img_res_body[:ErrorResponse][:Head][:ErrorMessage]
          end
          return res_body
        else
          return res_body
          # @error_message << user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
        end
      else
        return "#{market_place.name}: Signature can not be generated."
        @error_message << "#{market_place.name}: Signature can not be generated."
      end
    rescue Exception => e
      return e.message
        @error_message << user_market_place.market_place.name+": "+e.message
    end
    return @error_message.length > 0 ? @error_message.join("; ") : true
  end

  # Update product on Lazada
  def update_product_lazada(id, params, object, user_market_place, taxon_market_places, market_place_product)
    @object = object
    @error_message = []
    variants = []
    variants << (@object.variants.present? ? @object.variants : @object.master)
    variants = variants.flatten
    begin
      Time.zone = "Singapore"
      current_time = Time.zone.now
      user_id = user_market_place.contact_email ? user_market_place.contact_email : "tejaswini.patil@anchanto.com"
      market_place = Spree::MarketPlace.find(user_market_place.market_place_id)
      http = Net::HTTP.new(market_place.domain_url)
      product_params = {"Action"=>"ProductUpdate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
      signature = ApiJob.generate_lazada_signature(product_params, user_market_place)
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
        xml_obj = {}
        xml_obj = xml_obj.compare_by_identity
        variants.each do |variant|
          #Product params details
          brand = (@object.brand ? @object.brand.name : "3M")
          item_description = @object.description_details(market_place.code)
          item_title = @object.title_details(market_place.code)
          price_details = variant.price_details(market_place.code)
          price = variant.price.to_f
          primary_category = taxon_market_places.market_place_category_id.to_i
          category = ''
          seller_sku = variant.sku
          parent_sku = ''
          tax_class = 'default'
          sale_price = sale_price = ((price_details["special_price"].present? && price_details["special_price"].to_i > 0) ? price_details["special_price"] : "")
          sale_start_date = (@object.available_on ? @object.available_on : Time.now())
          sale_end_date = ''
          shipment_type = 'dropshipping'
          product_id = ''
          conditon = 'new'
          product_data = ''
          #quantity = variant.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand)
          name = (object.variants.present? ? (item_title["title"].to_s+"-"+variant.option_values.first.presentation.to_s) : item_title["title"].to_s)
          description = item_description["description"]
          short_desc = item_description["meta_description"]
          package_content = item_description["package_content"]
          height = variant.height.to_f
          weight = variant.weight.to_f
          length = variant.depth.to_f
          width = variant.width.to_f
          xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :SellerSku=>seller_sku, :ParentSku=>'', :TaxClass=>tax_class, :Variation=>'', :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type, :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content, :PackageHeight=>height, :PackageLength=>length, :PackageWidth=>width, :PackageWeight=>weight}}
        end # end of variant loop
        request.body = xml_obj.to_xml.gsub("hash", "Request")
        res = http.request(request)
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        if res.code == "200" && res_body[:SuccessResponse]
          @error_message << ""
        else
          @error_message << user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
        end
      else
        @error_message << "#{market_place.name}: Signature can not be generated."
      end
    rescue Exception => e
        @error_message << user_market_place.market_place.name+": "+e.message
    end
    return @error_message.length > 0 ? @error_message.join("; ") : true
  end

  def check_validation_for_mp(product,market_place_id,action)
    market_place = Spree::MarketPlace.find(market_place_id)
    market_place_code = market_place.code
    case market_place_code
      when "qoo10"
        if action == 'create'
          if product.kit.present?
            if !(product.kit.products.present? rescue true)
              return false
            end
          end
          if !product.taxons.present?
            return false
          end
          if !product.name.present?
            return false
          end
          if product.variant_images.nil? || product.variant_images.blank?
            return false
          end
          if !product.description_details(market_place_code).present?
            return false
          end
          if !product.price.present?
            return false
          end
          if !product.selling_price.present?
            return false
          else
            if product.selling_price <= 0
              return false
            end
          end
          if product.kit.present?
              if !(product.kit.products.present? rescue true)
                return false
              end
          end


          # @taxon_market_plcaes = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", params[:product][:taxon_ids].first, id)
          return true
        end
      when "lazada"
        if action == 'create'
          if product.kit.present?
            if !(product.kit.products.present? rescue true)
              return false
            end
          end
          if !product.sku.present?
            return false
          end
          if !product.name.present?
            return false
          end
          if !product.taxons.present?
            return false
          end
          if !product.description_details(market_place_code).present?
            return false
          end
          if !product.brand.present?
            return false
          end
          if !product.price.present?
            return false
          end
          if product.variants.present?
            product.variants.each do |variant|
              if (!variant.weight.present? rescue true)
                return false
              end
              if (!variant.height.present? rescue true)
                return false
              end
              if (!variant.width.present? rescue true)
                return false
              end
              if (!variant.depth.present? rescue true)
                return false
              end
            end
          else
            if (!product.weight.present? rescue true)
              return false
            end
            if (!product.height.present? rescue true)
              return false
            end
            if (!product.width.present? rescue true)
              return false
            end
            if (!product.depth.present? rescue true)
              return false
            end
          end

          return true
        end
      when 'zalora'
        if action == 'create'
          if product.kit.present?
            if !(product.kit.products.present? rescue true)
              return false
            end
          end
          if !product.sku.present?
            return false
          end
          if !product.name.present?
            return false
          end
          if !product.taxons.present?
            return false
          end
          if !product.description_details(market_place_code).present?
            return false
          end
          if !product.brand.present?
            return false
          end
          if !product.gender.present?
            return false
          else
              if product.gender == 'NA'
                return false
              end
          end
          if !product.price.present?
            return false
          end
          if !product.option_types.present?
            #return false
          else
            mapped_type = Spree::OptionTypesMarketPlace.where(:market_place_id => market_place.id,:option_type_id => product.option_types.first.id).first rescue nil
            if !mapped_type.present?
              return false
            end
          end
          if !product.variants.present?
            #return false
          else
            product.variants.each do |variant|
              mapped_value = Spree::OptionValuesMarketPlace.where(:market_place_id => market_place.id,:option_value_id => variant.option_values.first.id).first rescue nil
              if !mapped_value.present?
                return false
              end
            end
          end
          return true
        end
    end
  end

  def get_no_of_changes(product,market_place_id)
    Spree::RecentMarketPlaceChange.where("description not like '%updated%' and description != '' and product_id =? and market_place_id =? and update_on_fba = false",product,market_place_id).map(&:description).reject(&:empty?).join(',').split(',').uniq.count
  end


  end