class ProductJob

  def self.create_products_on_mp(product_ids, market_place, seller_ids, current_user, host_name, port_number)
    products = Spree::Product.where("id in (?)", product_ids.split(','))
    @error_message = []
    error_hash = []
    error_hash << ['SKU','Name', '','','Please Find the errors Below']
    market_place_code = market_place.code
    case market_place_code
      when "lazada"
        seller_ids = Spree::Product.where("id in (?)", product_ids.split(',')).map(&:seller_id).uniq
        res = ApiJob.listing_product_lazada(market_place.id, products, seller_ids, market_place)
        if res.length > 0
          error_hash << res
        end
      when "zalora"
        seller_ids = Spree::Product.where("id in (?)", product_ids.split(',')).map(&:seller_id).uniq
        res = ApiJob.listing_product_zalora(market_place.id, products, seller_ids, market_place)
        if res.length > 0
          error_hash << res
        end
      when 'qoo10'
        products.each   do |product|
          if seller_ids.include? product.seller_id
            @market_place_product = Spree::SellersMarketPlacesProduct.unscoped.where("seller_id=? AND market_place_id=? AND product_id=?", product.seller_id, market_place.id, product.id).try(:first)
            @taxon_market_places = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", product.taxons.first, market_place.id).try(:first)
            user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", product.seller_id, market_place.id).try(:first)
            if @taxon_market_places.present?
              if @market_place_product.present? && !@market_place_product.market_place_product_code.present? && @taxon_market_places.present?
                begin
                  if user_market_place.present? && user_market_place.api_secret_key.present?
                    if market_place.present?
                      res = ApiJob.listing_product_qoo10(product, user_market_place, @taxon_market_places, @market_place_product, market_place, host_name, port_number)  
                      if res != true
                        @market_place_product.destroy
                        error_hash << [product.sku, product.name,  '' ,'' , res]
                      end
                    end
                  else
                    @error_message << market_place.name+": Api key or Secret key is missing"
                    error_hash << [product.sku, product.name,  '' ,'' , 'Api key or Secret key is missing']
                  end
                rescue Exception => e
                  @market_place_product.destroy
                  error_hash << [product.sku, product.name, '' ,'' , e.message]
                end
              elsif @market_place_product.present? && @market_place_product.market_place_product_code.present? && @taxon_market_places.present?
                if @market_place_product.is_active == false
                  ApiJob.change_product_status_on_qoo10(user_market_place, @market_place_product, "active")
                else  
                  @error_message << market_place.name+": Product is already listed on this market place."
                  error_hash << [product.sku, product.name,  '' ,'' , 'Product is already listed on this market place']
                end                
              end
            else
              @market_place_product.destroy
              @error_message << market_place.name+": Please map market place category to list product."
              error_hash << [product.sku, product.name,  '' ,'' , 'Please map market place category to list product']
            end

          else
            error_hash << [product.sku, product.name, '' ,'' , 'Please map seller market place to list product']
          end
        end
    end
    # market_place = Spree::MarketPlace.find(market_place)
    if error_hash.present? && error_hash.size >= 2
      message = "You have some errors in creating products on #{market_place.name}, for details PFA. Rest of the products are created successfully"
      file = ImportJob.generate_excel(error_hash)
      Spree::ProductNotificationMailer::product_create_on_mp_status(current_user.try(:email), 'Create Product on MP status', message, file, "Product_error_on_MP_#{Date.today.strftime('%d-%m-%Y')}.xls" ).deliver
    else
      message = "Successfully created Products on #{market_place.name}"
      Spree::ProductNotificationMailer::product_create_on_mp_status(current_user.try(:email), 'Create Product on MP status', message, '', "" ).deliver
    end
    products.reload
    products.each do |product|
      variants = []
      variants << (product.variants.present? ? product.variants : product.master)
      if variants.present?
        variants = variants.flatten
        variants.each do |variant|
          variant.update_stock_after_change
        end
      end
    end
  end

  def self.update_products_on_mp(product_ids,market_place, current_user,host_name,port_number)
    products = Spree::Product.where("id in (?)", product_ids.split(','))
    @error_message = []
    error_hash = []
    error_hash << ['SKU','Name', '','','Please Find the errors Below']

    case market_place.code
      when 'qoo10'
        products.each   do |product|
          # if seller_ids.include? product.seller_id
          @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", product.seller_id, market_place.id, product.id)
          market_place =  @market_place_product.first.market_place
          @taxon_market_places = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", product.taxons.first, market_place.id)
          user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", product.seller_id, market_place.id)
          if @taxon_market_places && !@taxon_market_places.blank?
            if !@market_place_product.blank? && @market_place_product.first.market_place_product_code.present? && !@taxon_market_places.blank?
              begin
                if !user_market_place.blank? && !user_market_place.first.api_secret_key.nil?
                  updated_fields = Spree::RecentMarketPlaceChange.where("product_id =? and market_place_id =? and update_on_fba = false",product.id,market_place.id).map(&:description).reject(&:empty?).join(',').squish.gsub('-','').gsub(' ','').split(',').uniq
                  api_lists = ProductJob.get_qoo10_api_list(updated_fields)
                  seller_code = @market_place_product.first.product.sku.present? ? @market_place_product.first.product.sku : "" rescue ""
                  api_lists.each do |api_name|
                    case api_name
                      when "update_goods"
                        item_title = product.name
                        mp_name = Spree::TitleManagement.where(:product_id => product.id, :market_place_id=>market_place.id).first.name rescue item_title
                        #name = (object.variants.present? ? (mp_name+"-"+variant.option_values.first.presentation.to_s) : mp_name)
                        retail_price = product.price
                        shipping_no = user_market_place.first.shipping_code.to_s
                        uri = URI(market_place.domain_url+'/GoodsBasicService.api/UpdateGoods')
                        req = Net::HTTP::Post.new(uri.path)
                        req.set_form_data({'key'=>user_market_place.first.api_secret_key.to_s,'ItemCode'=>@market_place_product.first.market_place_product_code,'SecondSubCat'=>@taxon_market_places.first.market_place_category_id.to_s,'ManufactureNo'=>'','BrandNo'=>'','ItemTitle'=>mp_name.to_s,'SellerCode'=>seller_code.to_s,'IndustrialCode'=>'','ProductionPlace'=>'','ContactTel'=>'','RetailPrice'=>retail_price.to_s,'ShippingNo'=>shipping_no.to_s,'AvailableDateType'=>'','AvailableDateValue'=>''})
                        res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
                        if res.code != "200"
                          res_body = Hash.from_xml(res.body).to_json
                          res_body = JSON.parse(res_body, :symbolize_names => true)
                          error_hash << [product.sku,product.name, '','',res_body[:StdResult][:ResultMsg]]
                          @error_message << user_market_place.market_place.name+": "+res_body[:StdResult][:ResultMsg]
                        else
                          Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description not like '%uidu%'").where("description like '%upg%'").where(:product_id => product.id, :market_place_id => market_place.id).update_all(:deleted_at => Date.today)
                        end
                      when "goods_status"
                      when "goods_contents"
                        item_description = product.description_details("qoo10")
                        uri = URI(market_place.domain_url+'/GoodsBasicService.api/EditGoodsContents')
                        req = Net::HTTP::Post.new(uri.path)
                        req.set_form_data({'key' => user_market_place.first.api_secret_key.to_s, 'ItemCode' => @market_place_product.first.market_place_product_code, 'SellerCode' => seller_code.to_s, 'Contents' => item_description["description"].to_s})
                        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
                          http.request(req)
                        end
                        if res.code != "200"
                          res_body = Hash.from_xml(res.body).to_json
                          res_body = JSON.parse(res_body, :symbolize_names => true)
                          error_hash << [product.sku,product.name, '','',res_body[:StdResult][:ResultMsg]]
                          @error_message << user_market_place.market_place.name+": "+res_body[:StdResult][:ResultMsg]
                        else
                          Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%gc%'").where(:product_id => product.id, :market_place_id => market_place.id).update_all(:deleted_at => Date.today)
                        end
                      when "goods_price"
                        qty =  !product.stock_products.blank? ? product.stock_products.where(:sellers_market_places_product_id=>@market_place_product.first.id).sum(&:count_on_hand) : 0
                        item_price = product.selling_price
                        item_price = product.master.qoo10_item_price(market_place.code) if !product.variants.present?
                        uri = URI(market_place.domain_url+'/GoodsOrderService.api/SetGoodsPrice')
                        req = Net::HTTP::Post.new(uri.path)
                        req.set_form_data({'key'=>user_market_place.first.api_secret_key.to_s,'ItemCode'=>@market_place_product.first.market_place_product_code,'SellerCode'=>seller_code.to_s,
                                           'ItemPrice'=>item_price.to_s,'ItemQty'=>qty,'ExpireDate'=>''})
                        res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
                        if res.code != "200"
                          res_body = Hash.from_xml(res.body).to_json
                          res_body = JSON.parse(res_body, :symbolize_names=>true)
                          error_hash << [product.sku,product.name, '','',res_body[:StdResult][:ResultMsg]]
                          @error_message << user_market_place.market_place.name+": "+res_body[:StdResult][:ResultMsg]
                        else
                          Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description not like '%uidu%' ").where("description like '%gp%'").where(:product_id => product.id, :market_place_id => market_place.id).update_all(:deleted_at => Date.today)
                        end
                      when "update_inventory_data_unit"
                        product_selling_price = product.selling_price.present? ? product.selling_price : product.price
                        variants =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%uidu%'").where(:product_id => product.id, :market_place_id => market_place.id).map(&:variant_id)
                        variants.each do |v_id|
                          variant = Spree::Variant.find(v_id)
                          if variant.is_master?
                            qty =  !product.stock_products.blank? ? product.stock_products.where(:sellers_market_places_product_id=>@market_place_product.first.id).sum(&:count_on_hand) : 0
                            item_price = product.master.qoo10_item_price(market_place.code)
                            uri = URI(market_place.domain_url+'/GoodsOrderService.api/SetGoodsPrice')
                            req = Net::HTTP::Post.new(uri.path)
                            req.set_form_data({'key'=>user_market_place.first.api_secret_key.to_s,'ItemCode'=>@market_place_product.first.market_place_product_code,'SellerCode'=>seller_code.to_s,
                                               'ItemPrice'=>item_price.to_s,'ItemQty'=>qty,'ExpireDate'=>''})
                            res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
                            if res.code != "200"
                              res_body = Hash.from_xml(res.body).to_json
                              res_body = JSON.parse(res_body, :symbolize_names=>true)
                              error_hash << [product.sku,product.name, '','',res_body[:StdResult][:ResultMsg]]
                              @error_message << user_market_place.first.market_place.name+": "+res_body[:StdResult][:ResultMsg]
                              #market_place_product.update_attributes(:market_place_product_code=>market_place_product.market_place_product_code) if market_place_product.present?
                            else
                              Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%uidu%'").where(:variant_id => variant.id, :product_id => product.id, :market_place_id => market_place.id).update_all(:deleted_at => Date.today)
                            end
                          else
                            variant_selling_price = variant.price_details("qoo10")["selling_price"]
                            variant_selling_price = variant.price_details("qoo10")["special_price"] if (variant.price_details("qoo10")["special_price"].present? && variant.price_details("qoo10")["special_price"] > 0)
                            price = variant_selling_price.to_f - product_selling_price.to_f
                            seller_code = @market_place_product.first.product.sku.present? ? @market_place_product.first.product.sku : "" rescue ""
                            option_name = variant.option_values.present? ? variant.option_values.first.option_type.presentation :  ""
                            option_value = variant.option_values.present? ? variant.option_values.first.presentation :  product.short_name
                            qty = !variant.stock_products.blank? ? variant.stock_products.where(:sellers_market_places_product_id=>@market_place_product.first.id).sum(:count_on_hand) : 0
                            uri = URI(market_place.domain_url+'/GoodsBasicService.api/UpdateInventoryDataUnit')
                            req = Net::HTTP::Post.new(uri.path)
                            req.set_form_data({'key'=>user_market_place.first.api_secret_key.to_s,'ItemCode'=>@market_place_product.first.market_place_product_code,'SellerCode'=>seller_code.to_s,'OptionName'=>option_name,'OptionValue'=>option_value,'OptionCode'=>variant.sku.to_s,'Price'=>price.to_s,'Qty'=>qty.to_s})
                            res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
                            if res.code != "200"
                              res_body = Hash.from_xml(res.body).to_json
                              res_body = JSON.parse(res_body, :symbolize_names=>true)
                              error_hash << [product.sku,product.name, '','',res_body[:StdResult][:ResultMsg]]
                              @error_message << user_market_place.first.market_place.name+": "+res_body[:StdResult][:ResultMsg]
                              #market_place_product.update_attributes(:market_place_product_code=>market_place_product.market_place_product_code) if market_place_product.present?
                            else
                              Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%uidu%'").where(:variant_id => variant.id, :product_id => product.id, :market_place_id => market_place.id).update_all(:deleted_at => Date.today)
                            end
                          end

                        end
                      when "insert_inventory_data_unit"
                        product_selling_price = product.selling_price.present? ? product.selling_price : product.price
                        variants =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%insidu%'").where(:product_id => product.id, :market_place_id => market_place.id).map(&:variant_id)
                        variants.each do |v_id|
                          variant = Spree::Variant.find(v_id)
                          variant_selling_price = variant.price_details("qoo10")["selling_price"]
                          price = variant_selling_price.to_f - product_selling_price.to_f
                          seller_code = @market_place_product.first.product.sku.present? ? @market_place_product.first.product.sku : "" rescue ""
                          parent = variant.get_parent if variant.parent_id.present?
                          short_name = parent.present? ? parent.product.short_name : product.short_name
                          option_name = variant.option_values.present? ? variant.option_values.first.option_type.presentation : short_name
                          option_value = variant.option_values.present? ? variant.option_values.first.presentation :  short_name
                          qty =  !variant.stock_products.blank? ? variant.stock_products.where(:sellers_market_places_product_id=>@market_place_product.first.id).sum(:count_on_hand) : 0
                          uri = URI(market_place.domain_url+'/GoodsBasicService.api/InsertInventoryDataUnit')
                          req = Net::HTTP::Post.new(uri.path)
                          req.set_form_data({'key'=>user_market_place.first.api_secret_key.to_s,'ItemCode'=>@market_place_product.first.market_place_product_code,'SellerCode'=>seller_code.to_s,'OptionName'=>option_name,'OptionValue'=>option_value,'OptionCode'=>variant.sku.to_s,'Price'=>price.to_s,'Qty'=>qty.to_s})
                          res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
                          if res.code != "200"
                            res_body = Hash.from_xml(res.body).to_json
                            res_body = JSON.parse(res_body, :symbolize_names=>true)
                            error_hash << [product.sku,product.name, '','',res_body[:StdResult][:ResultMsg]]
                            @error_message << user_market_place.first.market_place.name+": "+res_body[:StdResult][:ResultMsg]
                          else
                            Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%insidu%'").where(:variant_id => variant.id, :product_id => product.id, :market_place_id => market_place.id).update_all(:deleted_at => Date.today)
                          end
                        end

                      when "goods_image"
                        variants =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%gimg1%'").where(:product_id => product.id, :market_place_id => market_place.id)
                        variants.each do |v|
                          c_date = v.created_at.to_date
                          variant = Spree::Variant.find(v.variant_id)
                          image = variant.images.where(:attachment_updated_at => c_date.beginning_of_day..c_date.end_of_day).last
                          image_url = image && image.attachment_file_name.split("_").first.capitalize == "qoo10".capitalize ? image.attachment.url(:original).to_s : (host_name+":"+port_number+"/assets/noimage/large.png")
                          uri = URI(market_place.domain_url+'/GoodsBasicService.api/EditGoodsImage')
                          req = Net::HTTP::Post.new(uri.path)
                          req.set_form_data({'key'=>user_market_place.first.api_secret_key.to_s,'ItemCode'=>@market_place_product.first.market_place_product_code,'SellerCode'=>seller_code.to_s,'StandardImage'=>image_url})
                          res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end

                          if res.code != "200"
                            res_body = Hash.from_xml(res.body).to_json
                            res_body = JSON.parse(res_body, :symbolize_names=>true)
                            error_hash << [product.sku,product.name, '','',res_body[:StdResult][:ResultMsg]]
                            @error_message << user_market_place.first.market_place.name+": "+res_body[:StdResult][:ResultMsg]
                            @message = res_body[:StdResult][:ResultMsg]
                          else
                            Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%nimg1%'").where(:variant_id => variant.id, :product_id => product.id, :market_place_id => market_place.id).update_all(:deleted_at => Date.today)
                          end
                        end

                    end
                  end
                else
                  @error_message << @sellers_market_places_product.market_place.name+": Api key or Secret key is missing"
                end
              rescue Exception => e
                p '----------------------  '
                p e
                # @market_place_product.first.delete
                error_hash << [product.sku, product.name, '' ,'' , e.message]
              end
            elsif !@market_place_product.blank? && @market_place_product.first.market_place_product_code.present? && !@taxon_market_places.blank?
              @error_message << market_place.name+": Product is already listed on this market place."
              error_hash << [product.sku, product.name,  '' ,'' , 'Product is already listed on this market place']
            end

          else
            # @market_place_product.first.delete
            @error_message << market_place.name+": Please map market place category to list product."
            error_hash << [product.sku, product.name,  '' ,'' , 'Please map market place category to list product']
          end

          # else
          #   error_hash << [product.sku, product.name, '' ,'' , 'Please map seller market place to list product']
          # end
        end

      when 'lazada'
        seller_ids = Spree::Product.where("id in (?)", product_ids.split(',')).map(&:seller_id).uniq
        res = ApiJob.update_product_lazada(market_place.id, products, seller_ids, market_place,host_name,port_number)
        if res.length > 0
          error_hash << res
        end
      when 'zalora'
        seller_ids = Spree::Product.where("id in (?)", product_ids.split(',')).map(&:seller_id).uniq
        res = ApiJob.update_product_zalora(market_place.id, products, seller_ids, market_place,host_name,port_number)
        if res.length > 0
          error_hash << res
        end
      # res = ApiJob.update_product_lazada(market_place.id, product, user_market_place.first, @taxon_market_places.first, @market_place_product.first)
    end

    if error_hash.present? && error_hash.size >= 2
      message = "You have some errors in updating products on #{market_place.name}, for details PFA. Rest of the products are updating successfully"
      file = ImportJob.generate_excel(error_hash)
      Spree::ProductNotificationMailer::product_create_on_mp_status(current_user.try(:email), 'Updating Product on MP status', message, file, "Product_error_on_MP_#{Date.today.strftime('%d-%m-%Y')}.xls" ).deliver
    else
      message = "Successfully updating Products on #{market_place.name}"
      Spree::ProductNotificationMailer::product_create_on_mp_status(current_user.try(:email), 'Updating Product on MP status', message, '', '' ).deliver
    end
  end

  def self.get_updated_fields(changed_fields,market_place_code)
    desc = []
    case market_place_code
      when 'qoo10'
        QOO10CHECKLIST.each do |key,value|
          value.each do |k,v|
            desc << k.to_s if changed_fields.include? v
          end
        end
      when 'lazada'
        LAZADACHACKLIST.each do |key,value|
          # value.each do |k,v|
          desc << key.to_s if changed_fields.include? value
          # end
        end
      when 'zalora'
        ZALORACHACKLIST.each do |key,value|
          # value.each do |k,v|
          desc << key.to_s if changed_fields.include? value
          # end
        end
    end
    return desc
  end

  def self.get_qoo10_api_list(updated_fields)
    p_keys = []
    QOO10CHECKLIST.each do |k, v|
      if Hash === v
        k_arr = []
        v.keys.each { |a| k_arr << a.to_s}
        if (k_arr&updated_fields).present?
          p_keys << k.to_s
        end
      end
    end
    return p_keys
  end


end
