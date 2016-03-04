class ApiJob

  def self.generate_lazada_signature(parameter_list, seller)
    api_key = seller.api_key
    #Sort parameter_list by key
    sorted_params = Hash[parameter_list.sort]
    string_to_be_formed = []
    # concatinate key value with
    sorted_params.each do |key,value|
      case key
        when "ShippingProvider"
          string_to_be_formed << CGI::escape("#{key}")+"="+URI::escape("#{value}")
        when "SkuSellerList"
          string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}").gsub("+", "%20")
        else
          string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")
      end
    end
    singnature_string = string_to_be_formed.join('&')
    #Compute signature and add it to parameters
    signature_key = OpenSSL::HMAC.hexdigest('sha256', api_key, singnature_string)
    return signature_key
  end

  def self.listing_product_qoo10(object, user_market_place, taxon_market_places, market_place_product,market_place,host_name,port_number)
    @error_message = []
    begin
      adult = object.is_adult ? 'Y' : 'N'
      image_url = ""
      if !object.variant_images.nil? && !object.variant_images.blank?
        size = 0
        object.variant_images.each do |mg|
          if size < mg.attachment_file_size
            image_url = mg.attachment.url(:original)
            size = mg.attachment_file_size
          end
        end
      end
      image_url = image_url.present? ? image_url : (host_name+":"+port_number.to_s+"/assets/noimage/large.png")
      item_description = object.description_details(market_place.code)
      item_title = object.title_details(market_place.code)
      @item_type = ""
      product_price_details = object.master.price_details(market_place.code)
      object.variants.each do |v|
        price_details = v.price_details(market_place.code)
        product_selling_price = object.selling_price.present? ? object.selling_price : object.price
        variant_selling_price = price_details["selling_price"]
        price = variant_selling_price.to_f - product_selling_price.to_f
        parent = v.get_parent if v.parent_id.present?
        short_name = parent.present? ? parent.product.short_name : product.short_name
        # option_name = variant.option_values.present? ? variant.option_values.first.option_type.presentation : short_name
        # option_value = variant.option_values.present? ? variant.option_values.first.presentation :  short_name
        if v.option_values.present?
          @item_type = @item_type + v.option_values.first.option_type.presentation  + "||*"
          @item_type = @item_type + v.option_values.first.presentation + "||*" + price.to_s + "||*"
          @item_type = @item_type + v.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand).to_s + "||*"+ (v.sku.present? ? v.sku.to_s : "0")
          @item_type = @item_type + ((v == object.variants.last) ? "" : "$$")
        else
          @item_type = @item_type +  object.option_types.first.presentation + "||*"
          @item_type = @item_type +  short_name + "||*" + price.to_s + "||*"
          @item_type = @item_type + v.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand).to_s + "||*"+ (v.sku.present? ? v.sku.to_s : "0")
          @item_type = @item_type + ((v == object.variants.last) ? "" : "$$")
        end

      end if object.variants.present?
      item_type = @item_type #'Color/Size||*White/100||*1000||*10||*0$$Color/Size||*Black/100||*1000||*10||*0'
      retail_price = object.price
      item_price = object.selling_price || object.price
      item_quantity = object.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand)
      expiry_date = (Time.now + 1.year).strftime("%Y-%m-%d")
      shipping_no = user_market_place.shipping_code.to_s #"418422" # '0' :=> 'Free Shiping', '400896' :=> 'Free on condition' where '400896' is SR code of Qoo10 backend for Others, '418422' :=> 'Free on condition' where '418422' is SR code of Qoo10 backend for Qxpress.
      seller_code = market_place_product.product.sku.present? ? market_place_product.product.sku : "" rescue ""
      uri = URI(market_place.domain_url+'/GoodsBasicService.api/SetNewGoods')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'SecondSubCat'=>taxon_market_places.market_place_category_id.to_s,'ManufactureNo'=>'','BrandNo'=>'','ItemTitle'=>item_title["title"].to_s,'SellerCode'=>seller_code.to_s,'IndustrialCode'=>'','ProductionPlace'=>'','AudultYN'=>adult.to_s,'ContactTel'=>'','StandardImage'=>image_url.to_s,'ItemDescription'=>item_description["description"].to_s,'AdditionalOption'=>'','ItemType'=>item_type.to_s,'RetailPrice'=>retail_price.to_s,'ItemPrice'=>item_price.to_s,'ItemQty'=>item_quantity.to_s,'ExpireDate'=>expiry_date.to_s,'ShippingNo'=>shipping_no.to_s,'AvailableDateType'=>'','AvailableDateValue'=>''})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
      if res.code == "200"
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        if res_body[:StdCustomResultOfGoodsResultModel][:ResultCode].to_i >= 0
          mp_product_code = res_body[:StdCustomResultOfGoodsResultModel][:ResultObject][:GdNo]
          market_place_product.update_attributes(:market_place_product_code=>mp_product_code) if market_place_product.present?
          object.reload
          object.variants.each do |variant|
            variant.reload
            variant.update_stock_after_change
            #variant.stock_products.reload
            #variant.stock_products.first.update_stock_on_stock_change
          end if object.variants.present?
        else
          #return res_body
          @error_message << user_market_place.market_place.name+": "+ res_body[:StdCustomResultOfGoodsResultModel][:ResultMsg]
        end
      else
        #return res
        @error_message << user_market_place.market_place.name+": "+ res.message
      end
    rescue Exception => e
      #return e
      @error_message << user_market_place.market_place.name+": "+e.message
    end
    return @error_message.length > 0 ? @error_message.join("; ") : true
  end

  # def self.listing_product_lazada(object, user_market_place, taxon_market_places, market_place_product)
  def self.listing_product_lazada(id, products, seller_ids, market_place)
    p '--------   api job listing_product_lazada'
    @error_message = []
    error_hash = []
    Time.zone = "Singapore"
    current_time = Time.zone.now
    begin
      seller_ids.each do |s_id|
        products_reactive = []
        objects = products.select { |a| a.seller_id == s_id}
        user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", s_id, market_place.id).try(:first)
        user_id = user_market_place.contact_email
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

          objects.each do |object|
            @market_place_product = Spree::SellersMarketPlacesProduct.unscoped.where("market_place_id=? AND product_id=? AND seller_id=?", market_place.id, object.id, object.seller_id).try(:first)
            taxon_market_places = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", object.taxons.first, market_place.id).try(:first)
            if @market_place_product.present? && taxon_market_places.present?
              if @market_place_product.is_active == false
                products_reactive << object
              else
                image_arr = []
                variants = []
                variants << (object.variants.present? ? object.variants : object.master)
                if variants.present?
                  variants = variants.flatten
                  variants.each do |variant|
                    #Product params details
                    item_description = object.description_details(market_place.code)
                    item_title = object.title_details(market_place.code)
                    price_details = variant.price_details(market_place.code)
                    brand = object.brand.name
                    name = (object.variants.present? ? (item_title["title"]+"-"+variant.option_values.first.presentation.to_s) : item_title["title"])
                    price = variant.price.to_f
                    price = ((price_details["selling_price"].present? && price_details["selling_price"].to_i > 0) ? price_details["selling_price"] : variant.price.to_f)
                    primary_category = taxon_market_places.market_place_category_id.to_i
                    category = ''
                    seller_sku = variant.sku
                    parent_sku = ''
                    tax_class = 'default'
                    sale_price = ((price_details["special_price"].present? && price_details["special_price"].to_i > 0) ? price_details["special_price"] : "")
                    sale_start_date = (object.available_on ? object.available_on : Time.now())
                    sale_end_date = ''
                    shipment_type = 'dropshipping'
                    product_id = ''
                    conditon = 'new'
                    product_data = ''
                    quantity = object.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand) rescue 0
                    description = item_description["description"]
                    short_desc = item_description["meta_description"]
                    package_content = item_description["package_content"]
                    height = variant.height.to_f
                    weight = variant.weight.to_f
                    length = variant.depth.to_f
                    width = variant.width.to_f
                    xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :Categories=>category, :SellerSku=>seller_sku,
                                        :ParentSku=>'', :TaxClass=>tax_class, :Variation=>'', :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type,
                                        :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data, :Quantity=>quantity,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content, :PackageHeight=>height, :PackageLength=>length, :PackageWidth=>width, :PackageWeight=>weight}
                    }
                    # Image hash
                    variant.images.each do |image|
                      image_arr << image.attachment.url(:original).to_s
                    end
                    object.images.each do |image|
                      image_arr << image.attachment.url(:original).to_s
                    end
                    img_xml_obj["ProductImage"]={:SellerSku=>seller_sku, :Images=>image_arr} if !image_arr.blank?
                  end # end of variant loop
                else
                  error_hash << [object.sku,object.name, '','','Product Does not have variantion']
                end # End of variant condition
              end # End of product remapping condition
            else
              error_hash << [object.sku,object.name, '','','Product is already listed on Market Place']
            end # End of marketplace product condition 
          end # End of object product loop
          
          #Call for remapping products on marketplace
          ApiJob.change_product_status_on_lazada(user_market_place, products_reactive, "active")
          
          request.body = xml_obj.to_xml.gsub("hash", "Request")
          res = http.request(request)
          res_body = Hash.from_xml(res.body).to_json
          res_body = JSON.parse(res_body, :symbolize_names=>true)
          if res.code == "200" && res_body[:SuccessResponse] && !img_xml_obj.blank?
            mp_product_code = res_body[:SuccessResponse][:Head][:RequestId]
            @market_place_product.update_attributes(:market_place_product_code=>mp_product_code) if @market_place_product.present?
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
              error_hash << ['', '','',img_res_body[:ErrorResponse][:Head][:ErrorMessage]]
              # return img_res_body[:ErrorResponse][:Head][:ErrorMessage]
              @error_message << user_market_place.market_place.name+": "+img_res_body[:ErrorResponse][:Head][:ErrorMessage]
            end
            #return res_body
          else
            #return res_body
            if !img_xml_obj.blank?
              @market_place_product.destroy! if @market_place_product.present?
              @error_message << user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
            else
              mp_product_code = res_body[:SuccessResponse][:Head][:RequestId] rescue nil
              @market_place_product.update_attributes(:market_place_product_code=>mp_product_code) if @market_place_product.present?
            end
          end
        else
          error_hash << ['', '','',"#{market_place.name}: Signature can not be generated."]
          @error_message << "#{market_place.name}: Signature can not be generated."
        end
      end
    rescue Exception => e
      error_hash << ['', '','',e.message]
      @error_message << e.message
    end
    return error_hash
  end

  def self.listing_product_zalora(id, products, seller_ids, market_place)
    p '--------   api job listing_product_zalora'
    @error_message = []
    error_hash = []
    Time.zone = "Singapore"
    current_time = Time.zone.now
    begin
      seller_ids.each do |s_id|
        products_reactive = []
        objects = products.select { |a| a.seller_id == s_id}
        user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", s_id, market_place.id).try(:first)
        user_id = user_market_place.contact_email
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

          objects.each do |object|
            @market_place_product = Spree::SellersMarketPlacesProduct.unscoped.where("seller_id=? AND market_place_id=? AND product_id=?", s_id, market_place.id, object.id).try(:first)
            if @market_place_product.present? && @market_place_product.is_active == false
              products_reactive << object
            else
              if object.option_types.present?
                mapped_type = Spree::OptionTypesMarketPlace.where(:market_place_id => market_place.id,:option_type_id => object.option_types.first.id).first rescue nil
                if mapped_type.present?
                else
                  @market_place_product.destroy! rescue nil
                  error_hash << [object.sku,object.name, '','','Please map option type to list this product on Zalora']
                  next
                end
              end
              taxon_market_places = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", object.taxons.first, market_place.id).try(:first)
              if @market_place_product.present? && taxon_market_places.present?
                image_arr = []
                variants = []
                variants << (object.variants.present? ? object.variants : object.master)
                variants = variants.flatten
                variants.each do |variant|
                  if variant.option_values.present?
                    mapped_value = Spree::OptionValuesMarketPlace.where(:market_place_id => market_place.id,:option_value_id => variant.option_values.first.id).first rescue nil
                    if mapped_value.present?
                    else
                      @market_place_product.destroy! rescue nil
                      error_hash << [object.sku,object.name, '','','Please map option value to list this product on Zalora']
                      next
                    end
                  end
                  #Product params details
                  gender = object.gender
                  item_title = object.title_details(market_place.code)
                  item_description = object.description_details(market_place.code)
                  price_details = variant.price_details(market_place.code)
                  brand =  (object.brand.name.upcase == "3M" ? "Maybelline" : object.brand.name) 
                  name = (object.variants.present? ? (item_title["title"]+"-"+variant.option_values.first.presentation.to_s) : item_title["title"])
                  price = variant.price.to_f
                  price = ((price_details["selling_price"].present? && price_details["selling_price"].to_i > 0) ? price_details["selling_price"] : variant.price.to_f)
                  primary_category = taxon_market_places.market_place_category_id.to_i
                  category = ''
                  seller_sku = variant.sku
                  parent_sku = ''
                  tax_class = 'default'
                  sale_price = ((price_details["special_price"].present? && price_details["special_price"].to_i > 0) ? price_details["special_price"] : "")
                  sale_start_date = (object.available_on ? object.available_on : Time.now())
                  sale_end_date = ''
                  shipment_type = 'dropshipping'
                  product_id = ''
                  conditon = 'new'
                  product_data = ''
                  quantity = object.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand) rescue 0
                  description = item_description["description"]
                  short_desc = item_description["meta_description"]
                  package_content = item_description["package_content"]
                  height = variant.height.to_f
                  weight = variant.weight.to_f
                  length = variant.depth.to_f
                  width = variant.width.to_f
                  color = ''
                  color_family = ''
                  measurements = "#{package_content}, height : #{height}, Length: #{length}, Width:#{width} Weight: #{weight}"
                  if mapped_value.present?
                    if mapped_type.name.downcase == 'color'
                      color = variant.option_values.first.presentation.to_s rescue ''
                      color_family = mapped_value.name.downcase
                      variation = "One Size"
                    else
                      variation = mapped_value.name
                    end
                  else
                    variation = "One Size"
                  end
                  xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :Categories=>category, :SellerSku=>seller_sku,
                                      :ParentSku=>'', :TaxClass=>tax_class, :Variation=>variation, :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type,
                                      :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data, :Quantity=>quantity,:ProductData=>{:Gender=>gender,:Color => color, :ColorFamily=>color_family, :Measurements => ''}
                  }
                  # Image hash
                  variant.images.each do |image|
                    image_arr << image.attachment.url(:original).to_s
                  end
                  object.images.each do |image|
                    image_arr << image.attachment.url(:original).to_s
                  end
                  img_xml_obj["ProductImage"]={:SellerSku=>seller_sku, :Images=>image_arr} if !image_arr.blank?
                end # end of variant loop
              else
                error_hash << [object.sku,object.name, '','','Product is already listed on Market Place']
              end
            end # End of marketplace product
          end # End of object products loop
          
          #Call for remapping products on marketplace
          ApiJob.change_product_status_on_lazada(user_market_place, products_reactive, "active")
          
          request.body = xml_obj.to_xml.gsub("hash", "Request")
          res = http.request(request)
          res_body = Hash.from_xml(res.body).to_json
          res_body = JSON.parse(res_body, :symbolize_names=>true)
          if res.code == "200" && res_body[:SuccessResponse] && !img_xml_obj.blank?
            mp_product_code = res_body[:SuccessResponse][:Head][:RequestId]
            @market_place_product.update_attributes(:market_place_product_code=>mp_product_code) if @market_place_product.present?
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
              error_hash << ['', '','',img_res_body[:ErrorResponse][:Head][:ErrorMessage]]
              @error_message << user_market_place.market_place.name+": "+img_res_body[:ErrorResponse][:Head][:ErrorMessage]
            end
          else
            if res.code == "200" && res_body[:SuccessResponse]
              mp_product_code = res_body[:SuccessResponse][:Head][:RequestId]
              @market_place_product.update_attributes(:market_place_product_code=>mp_product_code) if @market_place_product.present?
            end
            if !img_xml_obj.blank?
              @market_place_product.destroy! if @market_place_product.present?
              @error_message << user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
            end
          end
        else
          @market_place_product.destroy! if @market_place_product.present?
          error_hash << ['', '','',"#{market_place.name}: Signature can not be generated."]
          #return "#{market_place.code}: Signature can not be generated."
          @error_message << "#{market_place.name}: Signature can not be generated."
        end # End of signature condition
      end # End of seller ids
    rescue Exception => e
      p '------------------------------- e'
      error_hash << ['', '','',e.message]
      # return e.message
      @error_message << e.message
    end
    return error_hash
  end

  def self.update_product_lazada(id, products, seller_ids, market_place,host_name,port_number)
    @error_message = []
    error_hash = []
    begin
      Time.zone = "Singapore"
      current_time = Time.zone.now
      seller_ids.each do |s_id|
        objects = products.select { |a| a.seller_id = s_id}
        user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", s_id, market_place.id).try(:first)
        user_id = user_market_place.contact_email
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
          xml_image_obj = {}
          xml_image_obj = xml_image_obj.compare_by_identity
          new_xml_obj = {}
          new_xml_obj = new_xml_obj.compare_by_identity
          new_variant_ids = []
          new_xml_image_obj = {}
          new_xml_image_obj = new_xml_image_obj.compare_by_identity
          objects.each do |object|
            @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", s_id, market_place.id, object.id).try(:first)
            taxon_market_places = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", object.taxons.first, market_place.id).try(:first)
            if @market_place_product.present? && taxon_market_places.present?
              variants = []
              variants << (object.variants.present? ? object.variants : object.master)
              variants = variants.flatten
              variants.each do |variant|
                #Product params details
                brand = object.brand.name
                item_description = object.description_details(market_place.code)
                price_details = variant.price_details(market_place.code)
                mp_name = object.title_details(market_place.code)
                name = (object.variants.present? ? (mp_name["title"]+"-"+variant.option_values.first.presentation.to_s) : mp_name["title"])
                price = variant.price.to_f
                price = ((price_details["selling_price"].present? && price_details["selling_price"].to_i > 0) ? price_details["selling_price"] : variant.price.to_f)
                primary_category = taxon_market_places.market_place_category_id.to_i
                category = ''
                seller_sku = variant.sku
                parent_sku = ''
                tax_class = 'default'
                sale_price = sale_price = ((price_details["special_price"].present? && price_details["special_price"].to_i > 0) ? price_details["special_price"] : "")
                sale_start_date = (object.available_on ? object.available_on : Time.now())
                sale_end_date = ''
                shipment_type = 'dropshipping'
                product_id = ''
                conditon = 'new'
                product_data = ''
                #quantity = variant.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand)
                description = item_description["description"]
                short_desc = item_description["meta_description"]
                package_content = item_description["package_content"]
                height = variant.height.to_f
                weight = variant.weight.to_f
                length = variant.depth.to_f
                width = variant.width.to_f
                new_variant =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_variant%'").where(:variant_id => variant.id, :product_id => object.id, :market_place_id => market_place.id) rescue nil
                if new_variant.present?
                  image_arr = []
                  quantity = variant.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand) rescue 0
                  new_variant_ids << variant.id
                  new_xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :Categories=>category, :SellerSku=>seller_sku, :ParentSku=>'', :TaxClass=>tax_class, :Variation=>'', :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type, :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data, :Quantity=>quantity,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content, :PackageHeight=>height, :PackageLength=>length, :PackageWidth=>width, :PackageWeight=>weight}}
                  variant.images.each do |image|
                    image_arr << image.attachment.url(:original).to_s 
                  end
                  object.images.each do |image|
                    image_arr << image.attachment.url(:original).to_s 
                  end
                  new_xml_image_obj["ProductImage"]={:SellerSku=>seller_sku, :Images=>image_arr} if !image_arr.blank?
                else
                  xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :SellerSku=>seller_sku, :ParentSku=>'', :TaxClass=>tax_class, :Variation=>'', :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type, :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content, :PackageHeight=>height, :PackageLength=>length, :PackageWidth=>width, :PackageWeight=>weight}}
                  img_variant =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%image%'").where(:variant_id => variant.id, :product_id => object.id, :market_place_id => market_place.id)
                  if img_variant.present?
                    image = variant.images
                    image.each do |img|
                      image_url = img ? img.attachment.url(:original).to_s :  (host_name+":"+port_number+"/assets/noimage/large.png")
                      xml_image_obj["ProductImage"]={:SellerSku=>variant.sku, :Images=>{:Image=>image_url}}
                    end
                    object.images.each do |img|
                      image_url = img ? img.attachment.url(:original).to_s :  (host_name+":"+port_number+"/assets/noimage/large.png")
                      xml_image_obj["ProductImage"]={:SellerSku=>variant.sku, :Images=>{:Image=>image_url}}
                    end
                  end
                end
              end # end of variant loop
            else
              error_hash << [object.sku,object.name, '','','Product not listed on Market Place']
            end
          end
          if !xml_obj.blank?
            request.body = xml_obj.to_xml.gsub("hash", "Request")
            res = http.request(request)
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=>true)
          end
          if new_variant_ids.present?
            new_product_params = {"Action"=>"ProductCreate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
            new_signature = ApiJob.generate_lazada_signature(new_product_params, user_market_place)
            new_formed_params = []
            new_sorted_params = Hash[new_product_params.sort]
            new_sorted_params.merge!("Signature"=>new_signature)
            new_sorted_params.each do |key,value|new_formed_params << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
            new_param_string = "?"+new_formed_params.join('&')
            new_uri = URI.parse(market_place.domain_url+new_param_string)
            new_http = Net::HTTP.new(new_uri.host, new_uri.port)
            new_http.use_ssl = true
            new_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            new_request = Net::HTTP::Post.new(new_uri.request_uri)
            new_request.body = new_xml_obj.to_xml.gsub("hash", "Request")
            new_res = http.request(new_request)
            new_res_body = Hash.from_xml(new_res.body).to_json
            new_res_body = JSON.parse(new_res_body, :symbolize_names=>true)
            if new_res.code == "200" && new_res_body[:SuccessResponse]
              Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_variant%'").where(:product_id => objects.map(&:id), :variant_id => new_variant_ids, :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
              if  !new_xml_image_obj.blank?
                new_image_params = {"Action"=>"Image", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
                new_img_signature = ApiJob.generate_lazada_signature(new_image_params, user_market_place)
                new_img_formed_params = []
                new_img_sorted_params = Hash[new_image_params.sort]
                new_img_sorted_params.merge!("Signature"=>new_img_signature)
                new_img_sorted_params.each do |key,value|new_img_formed_params << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
                new_img_param_string = "?"+new_img_formed_params.join('&')
                new_img_uri = URI.parse(market_place.domain_url+new_img_param_string)
                new_img_http = Net::HTTP.new(new_img_uri.host, new_img_uri.port)
                new_img_http.use_ssl = true
                new_img_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                new_img_request = Net::HTTP::Post.new(new_img_uri.request_uri)
                new_img_request.body = new_xml_image_obj.to_xml(:skip_types=>true).gsub("hash", "Request")
                new_img_res = http.request(new_img_request)
                new_img_res_body = Hash.from_xml(new_img_res.body).to_json
                new_img_res_body = JSON.parse(new_img_res_body, :symbolize_names=>true)
                if new_img_res.code == "200" && new_img_res_body[:SuccessResponse]
                  #Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%image%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
                end
                if new_img_res.code == "200" && new_img_res_body[:ErrorResponse]
                  error_hash << ['', '','',new_img_res_body[:ErrorResponse][:Head][:ErrorMessage]]
                  @error_message << user_market_place.market_place.name+": "+new_img_res_body[:ErrorResponse][:Head][:ErrorMessage]
                end
              end
              new_variants = Spree::Variant.where(:id => new_variant_ids )
              new_variants.each do |v|
                v.update_stock_after_change
              end
            else
              #Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_variant%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
                error_hash << ['', '','',new_res_body[:ErrorResponse][:Head][:ErrorMessage]]
                @error_message << user_market_place.market_place.name+": "+new_res_body[:ErrorResponse][:Head][:ErrorMessage]
            end
          end
          if !xml_image_obj.blank?
            Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description not like '%image%' and description not like '%new_variant%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
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
            img_request.body = xml_image_obj.to_xml(:skip_types=>true).gsub("hash", "Request")
            img_res = http.request(img_request)
            img_res_body = Hash.from_xml(img_res.body).to_json
            img_res_body = JSON.parse(img_res_body, :symbolize_names=>true)
            if img_res.code == "200" && img_res_body[:SuccessResponse]
              Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%image%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
            end
            if img_res.code == "200" && img_res_body[:ErrorResponse]
              error_hash << ['', '','',img_res_body[:ErrorResponse][:Head][:ErrorMessage]]
              @error_message << user_market_place.market_place.name+": "+img_res_body[:ErrorResponse][:Head][:ErrorMessage]
            end
          else
            if  !xml_image_obj.blank?
              error_hash << ['', '','',res_body[:ErrorResponse][:Head][:ErrorMessage]]
              @error_message << user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
            else
              Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description not like '%new_variant%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
            end
          end
        else
          error_hash << ['', '','',res_body[:ErrorResponse][:Head][:ErrorMessage]]
          @error_message << "#{market_place.name}: Signature can not be generated."
        end
      end
    rescue Exception => e
      error_hash << ['', '','',e.message]
    end
    return error_hash
  end

  def self.update_product_zalora(id, products, seller_ids, market_place,host_name,port_number)
    @error_message = []
    error_hash = []
    begin
      Time.zone = "Singapore"
      current_time = Time.zone.now
      seller_ids.each do |s_id|
        objects = products.select { |a| a.seller_id = s_id}
        user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", s_id, market_place.id).try(:first)
        user_id =  user_market_place.contact_email
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
          xml_image_obj = {}
          xml_image_obj = xml_image_obj.compare_by_identity
          new_xml_obj = {}
          new_xml_obj = new_xml_obj.compare_by_identity
          new_variant_ids = []
          new_xml_image_obj = {}
          new_xml_image_obj = new_xml_image_obj.compare_by_identity
          objects.each do |object|
            #if object.option_types.present?
               if object.option_types.present?
                mapped_type = Spree::OptionTypesMarketPlace.where(:market_place_id => market_place.id,:option_type_id => object.option_types.first.id).first rescue nil
                if mapped_type.present?
                else
                  error_hash << [object.sku,object.name, '','','Please map option type to list this product on Zalora']
                  next
                end
               end
              #mapped_type = Spree::OptionTypesMarketPlace.where(:market_place_id => market_place.id,:option_type_id => object.option_types.first.id).try(:first) rescue nil
              #if mapped_type.present?
                @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", s_id, market_place.id, object.id).try(:first)
                taxon_market_places = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", object.taxons.first, market_place.id).try(:first)
                if @market_place_product.present? && taxon_market_places.present?
                  variants = []
                  #variants << object.variants
                  variants << (object.variants.present? ? object.variants : object.master)
                  variants = variants.flatten
                  variants.each do |variant|
                    if variant.option_values.present?
                      mapped_value = Spree::OptionValuesMarketPlace.where(:market_place_id => market_place.id,:option_value_id => variant.option_values.first.id).first rescue nil
                      if mapped_value.present?
                      else
                        error_hash << [object.sku,object.name, '','','Please map option value to list this product on Zalora']
                        next
                      end
                    end
                    #mapped_value = Spree::OptionValuesMarketPlace.where(:market_place_id => market_place.id,:option_value_id => variant.option_values.first.id).first rescue nil
                    #if mapped_value.present?
                      #Product params details
                      gender = object.gender
                      brand = object.brand.name
                      item_description = object.description_details(market_place.code)
                      item_title = object.title_details(market_place.code)
                      price_details = variant.price_details(market_place.code)
                      name = (object.variants.present? ? (item_title["title"]+"-"+variant.option_values.first.presentation.to_s) : item_title["title"])
                      price = variant.price.to_f
                      price = ((price_details["selling_price"].present? && price_details["selling_price"].to_i > 0) ? price_details["selling_price"] : variant.price.to_f)
                      primary_category = taxon_market_places.market_place_category_id.to_i
                      category = ''
                      seller_sku = variant.sku
                      parent_sku = ''
                      tax_class = 'default'
                      sale_price = sale_price = ((price_details["special_price"].present? && price_details["special_price"].to_i > 0) ? price_details["special_price"] : "")
                      sale_start_date = (object.available_on ? object.available_on : Time.now())
                      sale_end_date = ''
                      shipment_type = 'dropshipping'
                      product_id = ''
                      conditon = 'new'
                      product_data = ''
                      description = item_description["description"]
                      short_desc = item_description["meta_description"]
                      package_content = item_description["package_content"]
                      height = variant.height.to_f
                      weight = variant.weight.to_f
                      length = variant.depth.to_f
                      width = variant.width.to_f
                      color = ''
                      color_family = ''
                      measurements = "#{package_content}, height : #{height}, Length: #{length}, Width:#{width} Weight: #{weight}"
                      if mapped_value.present?
                        if mapped_type.name.downcase == 'color'
                          color = variant.option_values.first.presentation.to_s rescue ''
                          color_family = mapped_value.name.downcase
                          variation = "One Size"
                        else
                          variation = mapped_value.name
                        end
                      else
                        variation = "One Size"
                      end
                      new_variant =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_variant%'").where(:variant_id => variant.id, :product_id => object.id, :market_place_id => market_place.id) rescue nil
                      if new_variant.present?
                        image_arr = []
                        quantity = 0
                        new_variant_ids << variant.id
                        #new_xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :Categories=>category, :SellerSku=>seller_sku, :ParentSku=>'', :TaxClass=>tax_class, :Variation=>'', :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type, :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data, :Quantity=>quantity,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content, :PackageHeight=>height, :PackageLength=>length, :PackageWidth=>width, :PackageWeight=>weight}}
                        new_xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :Categories=>category, :SellerSku=>seller_sku,
                                            :ParentSku=>'', :TaxClass=>tax_class, :Variation=>variation, :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type,
                                            :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data, :Quantity=>quantity,:ProductData=>{:Gender=>gender,:Color => color, :ColorFamily=>color_family, :Measurements => ''}
                        }
                        variant.images.each do |image|
                          image_arr << image.attachment.url(:original).to_s
                        end
                        object.images.each do |image|
                          image_arr << image.attachment.url(:original).to_s
                        end
                        new_xml_image_obj["ProductImage"]={:SellerSku=>seller_sku, :Images=>image_arr} if !image_arr.blank?
                      else
                        #xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :SellerSku=>seller_sku, :ParentSku=>'', :TaxClass=>tax_class, :Variation=>'', :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type, :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content, :PackageHeight=>height, :PackageLength=>length, :PackageWidth=>width, :PackageWeight=>weight}}
                        xml_obj["Product"]={:Brand=>brand, :Description=>description, :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :SellerSku=>seller_sku, :ParentSku=>'', :TaxClass=>tax_class, :Variation=>'', :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type, :ProductId=>product_id, :Condition=>conditon, :ProductData=>product_data,:ProductData=>{:Gender=>gender,:Color => color, :ColorFamily=>color_family, :Measurements => ''}}
                        img_variant =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%image%'").where(:variant_id => variant.id, :product_id => object.id, :market_place_id => market_place.id)
                        if img_variant.present?
                          image = variant.images
                          image.each do |img|
                            if img.present? && !img.blank?
                            image_url = img ? img.attachment.url(:original).to_s :  (host_name+":"+port_number+"/assets/noimage/large.png")
                            xml_image_obj["ProductImage"]={:SellerSku=>variant.sku, :Images=>{:Image=>image_url}}
                            end
                          end
                          object.images.each do |img|
                            image_url = img ? img.attachment.url(:original).to_s :  (host_name+":"+port_number+"/assets/noimage/large.png")
                            xml_image_obj["ProductImage"]={:SellerSku=>variant.sku, :Images=>{:Image=>image_url}}
                          end
                        end
                      end
                      #img_variant =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%image%'").where(:variant_id => variant.id, :product_id => object.id, :market_place_id => market_place.id)
                      #if img_variant.present?
                      #  image = variant.images
                      #  image.each do |img|
                      #    image_url = img && img.attachment_file_name.split("_").first.capitalize == market_place.code.capitalize ? img.attachment.url(:original).to_s :  (host_name+":"+port_number+"/assets/noimage/large.png")
                      #    xml_image_obj["ProductImage"]={:SellerSku=>variant.sku, :Images=>{:Image=>image_url}}
                      #  end
                      #end
                    #else
                    #  error_hash << [object.sku,object.name, '','','Please map option value to list this product on Zalora']
                    #end
                  end # end of variant loop
                else
                  error_hash << [object.sku,object.name, '','','Product not listed on Market Place']
                end
              #else
              #  error_hash << [object.sku,object.name, '','','Please map option type to list this product on Zalora']
              #end
            #else
            #  error_hash << [object.sku,object.name, '','','Please add option type to list this product on Zalora']
            #end
          end
          if xml_obj.present?
            request.body = xml_obj.to_xml.gsub("hash", "Request")
            res = http.request(request)
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=>true)
            if (res.code == "200" && res_body[:SuccessResponse]) && !xml_image_obj.blank?
              Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description not like '%image%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
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
              img_request.body = xml_image_obj.to_xml(:skip_types=>true).gsub("hash", "Request")
              img_res = http.request(img_request)
              img_res_body = Hash.from_xml(img_res.body).to_json
              img_res_body = JSON.parse(img_res_body, :symbolize_names=>true)
              if img_res.code == "200" && img_res_body[:SuccessResponse]
                Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%image%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
              end
              if img_res.code == "200" && img_res_body[:ErrorResponse]
                error_hash << ['', '','',img_res_body[:ErrorResponse][:Head][:ErrorMessage]]
                @error_message << user_market_place.market_place.name+": "+img_res_body[:ErrorResponse][:Head][:ErrorMessage]
              end
            else
              if !xml_image_obj.blank?
                error_hash << ['', '','',res_body[:ErrorResponse][:Head][:ErrorMessage]]
                @error_message << user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
              else
                Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description not like '%new_variant%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
                #Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%image%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
              end
            end
          end
          if new_variant_ids.present?
            new_product_params = {"Action"=>"ProductCreate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
            new_signature = ApiJob.generate_lazada_signature(new_product_params, user_market_place)
            new_formed_params = []
            new_sorted_params = Hash[new_product_params.sort]
            new_sorted_params.merge!("Signature"=>new_signature)
            new_sorted_params.each do |key,value|new_formed_params << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
            new_param_string = "?"+new_formed_params.join('&')
            new_uri = URI.parse(market_place.domain_url+new_param_string)
            new_http = Net::HTTP.new(new_uri.host, new_uri.port)
            new_http.use_ssl = true
            new_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            new_request = Net::HTTP::Post.new(new_uri.request_uri)
            new_request.body = new_xml_obj.to_xml.gsub("hash", "Request")
            new_res = http.request(new_request)
            new_res_body = Hash.from_xml(new_res.body).to_json
            new_res_body = JSON.parse(new_res_body, :symbolize_names=>true)
            if new_res.code == "200" && new_res_body[:SuccessResponse]
              Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_variant%'").where(:product_id => objects.map(&:id), :variant_id => new_variant_ids, :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
              if  !new_xml_image_obj.blank?
                new_image_params = {"Action"=>"Image", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
                new_img_signature = ApiJob.generate_lazada_signature(new_image_params, user_market_place)
                new_img_formed_params = []
                new_img_sorted_params = Hash[new_image_params.sort]
                new_img_sorted_params.merge!("Signature"=>new_img_signature)
                new_img_sorted_params.each do |key,value|new_img_formed_params << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
                new_img_param_string = "?"+new_img_formed_params.join('&')
                new_img_uri = URI.parse(market_place.domain_url+new_img_param_string)
                new_img_http = Net::HTTP.new(new_img_uri.host, new_img_uri.port)
                new_img_http.use_ssl = true
                new_img_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                new_img_request = Net::HTTP::Post.new(new_img_uri.request_uri)
                new_img_request.body = new_xml_image_obj.to_xml(:skip_types=>true).gsub("hash", "Request")
                new_img_res = http.request(new_img_request)
                new_img_res_body = Hash.from_xml(new_img_res.body).to_json
                new_img_res_body = JSON.parse(new_img_res_body, :symbolize_names=>true)
                if new_img_res.code == "200" && new_img_res_body[:SuccessResponse]
                  #Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%image%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
                end
                if new_img_res.code == "200" && new_img_res_body[:ErrorResponse]
                  error_hash << ['', '','',new_img_res_body[:ErrorResponse][:Head][:ErrorMessage]]
                  @error_message << user_market_place.market_place.name+": "+new_img_res_body[:ErrorResponse][:Head][:ErrorMessage]
                end
              end
              new_variants = Spree::Variant.where(:id => new_variant_ids )
              new_variants.each do |v|
                v.update_stock_after_change
              end
            else
                Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_variant%'").where(:product_id => objects.map(&:id), :market_place_id => market_place.id, :update_on_fba => false).update_all(:deleted_at => Date.today)
            end
          end
        else
          error_hash << ['', '','',res_body[:ErrorResponse][:Head][:ErrorMessage]] rescue ''
          @error_message << "#{market_place.name}: Signature can not be generated."
        end
      end
    rescue Exception => e
      error_hash << ['', '','',e.message]
      # @error_message << user_market_place.market_place.name+": "+e.message
    end
    return error_hash
    # return error_hash.length > 0 ? error_hash : true
  end
  
  # Retrun new updated tracking from Zalora
  def self.return_tracking_zalora(smp, order)
    tracking_number = ""
    begin
      market_place = order.market_place
      Time.zone = "Singapore"
      current_time = Time.zone.now
      user_id = smp.contact_email
      list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
      signature_lt = ApiJob.generate_lazada_signature(list_item_params, smp)
      if signature_lt
        formed_list_item = []
        sorted_params_lt = Hash[list_item_params.sort]
        sorted_params_lt.merge!("Signature"=>signature_lt)
        sorted_params_lt.each do |key,value|formed_list_item << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
        param_string_lt = "?"+formed_list_item.join('&')
        uri_lt = URI.parse(market_place.domain_url+param_string_lt)
        http_lt = Net::HTTP.new(uri_lt.host, uri_lt.port)
        http_lt.use_ssl = true
        http_lt.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request_lt = Net::HTTP::Get.new(uri_lt.request_uri)
        res_lt = http_lt.request(request_lt)
        if res_lt.code == "200"
          res_lt_body = Hash.from_xml(res_lt.body).to_json
          res_lt_body = JSON.parse(res_lt_body, :symbolize_names=>true)
          if res_lt_body[:SuccessResponse]
            if res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem].class == Array
              order_items = res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]
            else  
              order_items = [res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]]
            end
            tracking_number = order_items.try(:first)[:TrackingCode] 
          else
            res_lt_body[:ErrorResponse][:Head][:ErrorMessage]
          end
        end
      end  
    rescue Exception => e  
    end
    return tracking_number
  end
  
  # Update tracking in FBA
  def self.update_tracking_number_fba(smp,order,new_tracking_no)
    @message = ""
    fba_api_key = smp.fba_api_key
    authorization = Base64.encode64("#{USER}:#{PASSWORD}")
    update_order_path = OMS_PATH+"/update_order/#{order.cart_no}"
    if fba_api_key.present? && smp.fba_signature.present? && order.fulflmnt_tracking_no.present?
      begin
        contact_person_email = smp.seller.contact_person_email.present? ? smp.seller.contact_person_email : nil
        resp = RestClient.put(update_order_path, {:api_key => fba_api_key, :tracking_number => order.fulflmnt_tracking_no, :modified_tracking_number=>new_tracking_no, :version => "2.0", :signature=>smp.fba_signature.strip, :email=>contact_person_email.strip}, {:Authorization => authorization})
        resp = JSON.parse(resp)
        if resp["response"] == "success"
          order.update_attributes(:fulflmnt_tracking_no=>new_tracking_no)
        end
      rescue Exception => e
        @message =  e.message
        Spree::OmsLog.create!(:order_id => order.id, :server_error_log => e.message)
      end
      @message = true if @message.empty?
    else
      @message = "Ooops, API key or signature or FBA tracking number not found"
    end
    return @message
  end
  
  # Fetch order invoice for lazada and zalora orders
  def self.fetch_order_invoice_from_lazada(smp, order)
    market_place = smp.market_place
    begin
      # List item fetch from order API
      order_item_code = []
      Time.zone = "Singapore"
      current_time = Time.zone.now
      list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>smp.contact_email, "Version"=>"1.0"}
      signature_lt = ApiJob.generate_lazada_signature(list_item_params, smp)
      if signature_lt
        formed_list_item = []
        sorted_params_lt = Hash[list_item_params.sort]
        sorted_params_lt.merge!("Signature"=>signature_lt)
        sorted_params_lt.each do |key,value|formed_list_item << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
        param_string_lt = "?"+formed_list_item.join('&')
        uri_lt = URI.parse(market_place.domain_url+param_string_lt)
        http_lt = Net::HTTP.new(uri_lt.host, uri_lt.port)
        http_lt.use_ssl = true
        http_lt.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request_lt = Net::HTTP::Get.new(uri_lt.request_uri)
        res_lt = http_lt.request(request_lt)
        if res_lt.code == "200"
          res_lt_body = Hash.from_xml(res_lt.body).to_json
          res_lt_body = JSON.parse(res_lt_body, :symbolize_names=>true)
          if res_lt_body[:SuccessResponse]
            order_items = res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]
            if order_items.class == Array
              order_items.each do |order_item|
                order_item_code = order_item[:OrderItemId] 
              end
            elsif order_items.class != Array
              order_item_code = order_items[:OrderItemId]
            end
            #Invoice generation call
            order_item_code = (order_item_code.present? ? order_item_code : '')
            invoice_no = order.fulflmnt_tracking_no ? order.fulflmnt_tracking_no : "12345"
            invoice_params = {"Action"=>"GetDocument", "DocumentType"=>"invoice", "InvoiceNumber"=>invoice_no, "OrderItemId"=>order_item_code, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>smp.contact_email, "Version"=>"1.0"}
            signature = ApiJob.generate_lazada_signature(invoice_params, smp)
            if signature.present?
              string_to_be_formed = []
              sorted_params = Hash[invoice_params.sort]
              sorted_params.merge!("Signature"=>signature)
              sorted_params.each do |key,value|string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
              param_string = "?"+string_to_be_formed.join('&')
              uri = URI.parse(market_place.domain_url+param_string)
              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
              request = Net::HTTP::Get.new(uri.request_uri)
              res = http.request(request)
              if res.code == "200"
                res_body = Hash.from_xml(res.body).to_json
                res_body = JSON.parse(res_body, :symbolize_names=>true)
                if res_body[:SuccessResponse]
                  #FBA invoice push API call
                  fba_res = order.send_invoice(smp, order, res_body[:SuccessResponse][:Body][:Documents][:Document][:File])
                  order.update_column(:invoice_details,res_body[:SuccessResponse][:Body][:Documents][:Document][:File])  if fba_res
                else
                  @messages = "#{market_place.name}: ["+"#{order.market_place_order_no.to_s}"+"]"+res_body[:ErrorResponse][:Head][:ErrorMessage]
                end
              end
              else
                @messsges = "#{market_place.name}: Signature can not be generated."
              end # End for invoice signature check
          else
            @messages = "#{market_place.name}: ["+"#{order.market_place_order_no.to_s}"+"] "+res_lt_body[:ErrorResponse][:Head][:ErrorMessage]
          end # End for line items error check
        end
      else
        @messsges = "#{market_place.name}: Signature can not be generated."
      end # End for the line items signature check
    rescue Exception => e
      @messsges = "#{market_place.name}: ["+"#{order.market_place_order_no.to_s}"+"] "+e.message
    end
    return @messages
  end
  
  def self.order_state_to_rts_lazada(order_id)
    order = Spree::Order.find(order_id)
    @error_message = ""
    seller_id = order.seller_id.present? ? order.seller_id : nil
    smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", seller_id, order.market_place_id).try(:first)
    market_place = order.market_place
    if smp.present?
      begin
        Time.zone = "Singapore"
        current_time = Time.zone.now
        user_id = smp.contact_email
        list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
        signature_lt = ApiJob.generate_lazada_signature(list_item_params, smp)
        if signature_lt
          formed_list_item = []
          sorted_params_lt = Hash[list_item_params.sort]
          sorted_params_lt.merge!("Signature"=>signature_lt)
          sorted_params_lt.each do |key,value|formed_list_item << CGI::escape("#{key}")+"="+CGI::escape("#{value}")end
          param_string_lt = "?"+formed_list_item.join('&')
          uri_lt = URI.parse(market_place.domain_url+param_string_lt)
          http_lt = Net::HTTP.new(uri_lt.host, uri_lt.port)
          http_lt.use_ssl = true
          http_lt.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request_lt = Net::HTTP::Get.new(uri_lt.request_uri)
          res_lt = http_lt.request(request_lt)
          @order_item_ids = []
          if res_lt.code == "200"
            res_lt_body = Hash.from_xml(res_lt.body).to_json
            res_lt_body = JSON.parse(res_lt_body, :symbolize_names=>true)
            if res_lt_body[:SuccessResponse]
              @order_items = res_lt_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]
              if @order_items.class == Array
                @order_items.each do |item|
                  @order_item_ids << item[:OrderItemId]
                end if @order_items
              else
                @order_item_ids = @order_items[:OrderItemId]
              end
            else
              @error_message = res_lt_body[:ErrorResponse][:Head][:ErrorMessage]
            end
          end
          if @order_items.present?
            shipping_company = smp.shipping_code
            tracking_no = order.fulflmnt_tracking_no
            @order_item_ids = (@order_item_ids.class == Array ? @order_item_ids.to_json : @order_item_ids) 
            if market_place.code == "zalora"
              change_state_params = {"Action"=>"SetStatusToReadyToShip", 'DeliveryType' => 'dropship', 'OrderItemIds' => @order_item_ids, 'ShippingProvider' => shipping_company, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
            else  
              change_state_params = {"Action"=>"SetStatusToReadyToShip", 'DeliveryType' => 'dropship', 'OrderItemIds' => @order_item_ids, 'ShippingProvider' => shipping_company, "TrackingNumber"=>tracking_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
            end
            signature = ApiJob.generate_lazada_signature(change_state_params, smp)
            if signature
              string_to_be_formed = []
              sorted_params = Hash[change_state_params.sort]
              sorted_params.merge!("Signature"=>signature)
              sorted_params.each do |key,value|
                if key == "ShippingProvider"
                  string_to_be_formed << CGI::escape("#{key}")+"="+URI::escape("#{value}")
                else
                  string_to_be_formed << CGI::escape("#{key}")+"="+CGI::escape("#{value}")
                end
              end
              param_string = "?"+string_to_be_formed.join('&')
              uri = URI.parse(market_place.domain_url+param_string)
              http = Net::HTTP.new(uri.host, uri.port)
              http.use_ssl = true
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
              request = Net::HTTP::Get.new(uri.request_uri)
              res = http.request(request)
              res_body = Hash.from_xml(res.body).to_json
              res_body = JSON.parse(res_body, :symbolize_names=>true)
              if res.code != "200" || (res.code == "200" && res_body[:ErrorResponse]).present?
                @error_message = res_body[:ErrorResponse][:Head][:ErrorMessage]
                details = "<b>Seller Name: </b>" + order.seller.name.capitalize + "<br />"
                details += "<b>Order Number: </b>" + order.market_place_order_no.to_s + "<br />"
                details += "<b>FBA Order Number: </b>" + order.cart_no.to_s + "<br />"
                details += "<b>Tracking Number: </b>" + order.fulflmnt_trackin_no.to_s + "<br />"
                details += "<b>Message: </b>" + @error_message.to_s + "<br />"
                body = "Please take action on following order is not able to change order state on given marketplace. <br /><br />" + details
                subject = "Channel Manager | "+market_place.name.capitalize+" | Order status failed to update on marektplace" 
                CustomMailer.custom_order_export("abhijeet.ghude@anchanto.com",subject,body).deliver 
              else
                if res_body[:SuccessResponse].present?
                  # Fetch tracking number in case of zalora and update to FBA
                  if market_place.code == "zalora"
                    tracking_no = ApiJob.return_tracking_zalora(smp,order)
                    num = Spree::Order.where("seller_id=? AND cart_no=?",smp.seller_id,order.cart_no).count
                    tracking_no = (tracking_no.present? ? tracking_no : ("NA_"+order.cart_no.to_s+"_"+smp.seller_id.to_s)) 
                    ApiJob.update_tracking_number_fba(smp,order,tracking_no) if order.fulflmnt_tracking_no.present? && tracking_no.present? && order.fulflmnt_tracking_no != tracking_no
                    order.reload
                    order.update_attributes!(:market_place_order_status=>"ready to ship")                      
                  end
                  invoice_res = ApiJob.fetch_order_invoice_from_lazada(smp, order)
                end
              end
            else
              @error_message = "Signature can not be generated"
            end
          end
        else
          @error_message = "Signature can not be generated"
        end
      rescue Exception => e
        @error_message = e.message
      end
    else
      @error_message = "Seller not found"
    end
    return @error_message.empty? ? "success" : @error_message
  end

  # Receive FBA stock in CM 
  def self.fba_stock_received(params)
    notification_array = []
    stock_values = {}
    products = JSON.parse(params["products"], :symbolize_names=>true)
    products.each do |product|
      begin 
        quantity = (product[:quantity].to_i > 0 ? product[:quantity].to_i : 0)
        variant = Spree::Variant.find_by_sku(product[:sku])
        if variant.present?
          qfs = Spree::QuantityInflation.where(:variant_id=>variant.id)
          if qfs.present?
            variant.update_column(:fba_quantity,quantity)
            msg = 'ApiJob fba_stock_received Line 1229'
            variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
            qfs.each do |qf|
              qf.update_attributes!(:next_type=>"Sync with FBA")
            end
            notification_array << [product[:sku],"Allocated Stock can't be update because, product is on inflation", quantity, true]
          else  
            if variant.update_attributes(:fba_quantity=>quantity)
              msg = 'ApiJob fba_stock_received Line 1238'
              variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
              notification_array << [product[:sku],"Stock updated successfully", quantity, false]
            else
              notification_array << [product[:sku],"Some error while updating stock", quantity, true]
            end
            stock_values.merge!(variant.update_stock_for_variant)
          end
        else
          notification_array << [product[:sku],"No Products found", quantity, true]
        end
      rescue Exception => e
        notification_array << [product[:sku],e.message, "-", true]
      end      
    end 
    Spree::DataImportMailer::stock_update_notification(notification_array).deliver if notification_array.present?
  end
  
  # Change product status on QSM
  def self.change_product_status_on_qoo10(smp, smpp, status)
    result = true
    begin
      status_code = (status == "active" ? "2" : "1") 
      market_place = smp.market_place 
      product = smpp.product
      item_code = smpp.market_place_product_code
      sku = product.sku
      uri = URI(market_place.domain_url+'/GoodsBasicService.api/EditGoodsStatus')
      req = Net::HTTP::Post.new(uri.path)
      req.set_form_data({'key'=>smp.api_secret_key.to_s,'ItemCode'=>item_code.to_s,'SellerCode'=>sku.to_s,'Status'=>status_code})
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
      if res.code == "200"
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
        if res_body[:StdResult].present? && res_body[:StdResult][:ResultCode].present? && res_body[:StdResult][:ResultCode] == "0"
          # Changes after status change
          ApiJob.update_after_product_status_change(smp, smpp, product, market_place, status)
          result = true
        else
          result = res_body[:StdResult][:ResultMsg] 
        end
      end
    rescue Exception => e
      result = e.message
    end          
    return result
  end
  
  # Change product status on lazada and zalora
  def self.change_product_status_on_lazada(smp, products, status)
    result = true
    status = (status == "active" ? "active" : "inactive")
    begin
      market_place = smp.market_place
      Time.zone = "Singapore"
      current_time = Time.zone.now
      user_id = smp.contact_email
      http = Net::HTTP.new(market_place.domain_url)
      product_params = {"Action"=>"ProductUpdate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
      signature = ApiJob.generate_lazada_signature(product_params, smp)
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
        products.each do |product|
          smpp = Spree::SellersMarketPlacesProduct.unscoped.where("seller_id=? AND product_id=? AND market_place_id=?", smp.seller_id, product.id, market_place.id).try(:first)
          variants = (product.variants.present? ? product.variants : [product.master])
          variants.each do |variant|
            sku = variant.sku
            xml_obj["Product"]={:SellerSku=>sku,:Status=>status}
          end # end of variant loop
          ApiJob.update_after_product_status_change(smp, smpp, product, market_place, status) 
        end # end of product loop
      end # End of signature condition
      if !xml_obj.blank?
        request.body = xml_obj.to_xml.gsub("hash", "Request")
        res = http.request(request)
        res_body = Hash.from_xml(res.body).to_json
        res_body = JSON.parse(res_body, :symbolize_names=>true)
      end
    rescue Exception => e
      result = e.message  
    end
    return result
  end
  
  # Method to update changes for the product status changes on qsm
  def self.update_after_product_status_change(smp, smpp, product, market_place, status)
    begin
      if status == "active"
        variants = []
        smpp.update_attributes!(:is_active=>true, :last_update_on_mp=>Time.zone.now)
        product.reload
        smpps = product.sellers_market_places_products
        perc = 100/(smpps.count == 0 ? 1 : smpps.count)
        smpps.update_all(:stock_config_details=>perc)
        smpp.reload
        variants = (product.variants.present? ? product.variants : [product.master])
        tm = product.title_managements.where(:market_place_id=>market_place.id).try(:first)
        dm = product.description_managements.where(:market_place_id=>market_place.id).try(:first)
        tm.update_attributes(:is_active=>true) if tm.present?
        dm.update_attributes(:is_active=>true) if dm.present? 
        variants.each do |variant|
          pm = variant.price_managements.where(:market_place_id=>market_place.id).try(:first)
          pm.update_attributes(:is_active=>true) if pm.present?
          if !product.kit_id.present?
            Spree::Variant.fetch_qty_from_fba(smp, variant)
            if variant.parent_id.present?
              parent = variant.get_parent
              Spree::Variant.fetch_qty_from_fba(smp, parent)
              parent.reload
              variant.update_attributes!(:fba_quantity=>parent.fba_quantity) if !variant.quantity_inflations.present?
            end
            #variant.update_stock_after_change if !variant.quantity_inflations.present?
          else
            kit = product.kit
            kit_products = kit.kit_products
            kit_products.each do |kp|
              k_variant = kp.variant
              smpp.reload
              Spree::Variant.fetch_qty_from_fba(smp, k_variant)
              #k_variant.update_stock_after_change if !k_variant.quantity_inflations.present?
            end
          end # End of kit condition   
        end # End of variant loop
      else
        variants = []
        smpp.update_attributes!(:is_active=>false, :last_update_on_mp=>Time.zone.now)
        product.reload
        smpps = product.sellers_market_places_products
        perc = 100/(smpps.count == 0 ? 1 : smpps.count)
        smpps.update_all(:stock_config_details=>perc)
        smpp.reload
        variants = (product.variants.present? ? product.variants : [product.master])
        tm = product.title_managements.where(:market_place_id=>market_place.id).try(:first)
        dm = product.description_managements.where(:market_place_id=>market_place.id).try(:first)
        tm.update_attributes(:is_active=>false) if tm.present?
        dm.update_attributes(:is_active=>false) if dm.present? 
        variants.each do |variant|
          pm = variant.price_managements.where(:market_place_id=>market_place.id).try(:first)
          pm.update_attributes(:is_active=>false) if pm.present?
          variant.reload
          variant.update_stock_after_change
          if product.kit_id.present?
            kit = product.kit
            kit_products = kit.kit_products
            kit_products.each do |kp|
              k_variant = kp.variant
              smpp.reload
              Spree::Variant.fetch_qty_from_fba(smp, k_variant)
              k_variant.update_stock_after_change if !k_variant.quantity_inflations.present?
            end
          end
        end # End of variant loop
      end # End of active status condition
    rescue Exception => e
    end    
  end
  
end