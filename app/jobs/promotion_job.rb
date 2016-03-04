class PromotionJob
  def self.start_promotion(promotion,p_action)
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    act = promotion.promotion_actions.where(:type =>'Spree::Promotion::Actions::Discount')
    if act.present?
      my_logger.info('Promotion is applying')
      discount_amount = act.first.preferred_amount.to_f
      rules = promotion.promotion_rules.where(:type => ['Spree::Promotion::Rules::Seller','Spree::Promotion::Rules::Product','Spree::Promotion::Rules::MarketPlace','Spree::Promotion::Rules::Taxon','Spree::Promotion::Rules::Variant'])
      types = rules.map(&:type)
      match_policy = promotion.match_policy
      condition = ''
      product_ids = []
      variant_ids = []

      if types.include? 'Spree::Promotion::Rules::Variant'
        p 'variant present'
        p promotion.variants
        variant_ids << promotion.variants.map(&:id)
        variant_ids = variant_ids.flatten
        p_ids =  promotion.variants.map(&:product_id).flatten.uniq
        product_ids << p_ids.flatten
        product_ids = product_ids.flatten
        # condition = condition + "id in #{product_ids}"
      end
      if types.include? 'Spree::Promotion::Rules::Product'
        product_ids << promotion.products.map(&:id)
        product_ids = product_ids.flatten
        # condition = condition + "id in #{product_ids}"
      end
      if types.include? 'Spree::Promotion::Rules::Seller'
        # rule = rules.select{|r| r.type == 'Spree::Promotion::Rules::Seller'}.first
        seller_ids = promotion.sellers.map(&:id) rescue []
        condition = condition.present? ? condition + "and seller_id in #{seller_ids.flatten}" : condition + "seller_id in #{seller_ids.flatten}"
      end
      if types.include? 'Spree::Promotion::Rules::Taxon'
        # rule = rules.select{|r| r.type == 'Spree::Promotion::Rules::Taxon'}.first
        taxons = promotion.taxons.map(&:id) rescue []
        taxon_id = taxons.collect{|t| t.self_and_descendants.map(&:id)}.flatten rescue []
        # Spree::Product.includes(:taxons).where("spree_products_taxons.taxon_id in #{taxon_id}")
        condition.present? ? condition + "and spree_products_taxons.taxon_id in #{taxon_id}" : condition + "spree_products_taxons.taxon_id in #{taxon_id}"
      end
      if types.include? 'Spree::Promotion::Rules::MarketPlace'
        # rule = rules.select{|r| r.type == 'Spree::Promotion::Rules::MarketPlace'}.first
        market_places_ids = promotion.market_places.map(&:id) rescue []
        # market_places_ids = Spree::MarketPlace.all.map(&:id) if (market_places_ids.blank? || !market_places_ids.present?)
        # Spree::Product.includes(:sellers_market_places_products).where("spree_sellers_market_places_products.market_place_id in (?)",market_places_ids)
        # seller_ids = rule.eligible_market_places.map(&:id) rescue []
      else
        market_places_ids = Spree::MarketPlace.all.map(&:id) if (market_places_ids.blank? || !market_places_ids.present?)
      end
      condition = ''
      if match_policy == 'all'
        condition = condition + "spree_products.id in #{product_ids}" if product_ids.present? && !product_ids.blank?
        condition = condition.present? ? condition + " and spree_products.seller_id in #{seller_ids.flatten}" : condition + "spree_products.seller_id in #{seller_ids.flatten}" if seller_ids.present?
        condition = condition.present? ? condition + " and spree_products_taxons.taxon_id in #{taxon_id}" : condition + "spree_products_taxons.taxon_id in #{taxon_id}" if taxon_id.present?
        condition = condition.present? ? condition + " and spree_sellers_market_places_products.market_place_id in #{market_places_ids.flatten}" : condition + "spree_sellers_market_places_products.market_place_id in #{market_places_ids.flatten}" if market_places_ids.present?
        condition =condition.gsub('[','(').gsub(']',')')
        @products = Spree::Product.includes(:taxons).includes(:sellers_market_places_products).where(condition)
      else
        condition = condition + "spree_products.id in #{product_ids}" if product_ids.present? && !product_ids.blank?
        condition = condition.present? ? condition + " or spree_products.seller_id in #{seller_ids.flatten}" : condition + "spree_products.seller_id in #{seller_ids.flatten}" if seller_ids.present?
        condition = condition.present? ? condition + " or spree_products_taxons.taxon_id in #{taxon_id}" : condition + "spree_products_taxons.taxon_id in #{taxon_id}" if taxon_id.present?
        condition = condition.present? ? condition + " or spree_sellers_market_places_products.market_place_id in #{market_places_ids.flatten}" : condition + "spree_sellers_market_places_products.market_place_id in #{market_places_ids.flatten}" if market_places_ids.present?
        condition =condition.gsub('[','(').gsub(']',')')
        @products = Spree::Product.includes(:taxons).includes(:sellers_market_places_products).where(condition)
        variant_ids = []
      end

      if p_action== 'start'
        PromotionJob.apply_discount_on_mp(@products,discount_amount,market_places_ids,variant_ids,promotion )
      else
        PromotionJob.close_discount_on_mp(@products,market_places_ids,variant_ids,promotion )
      end
    end
  end

  def self.apply_discount_on_mp(products,discount_amount,market_places_ids,variant_ids,promotion)
    act = promotion.promotion_actions.where(:type =>'Spree::Promotion::Actions::Discount')
    discount_type = act.first.preferred_operator
    if variant_ids.present?
      products = Spree::Product.where(:id => Spree::Variant.where(:id => variant_ids).map(&:product_id).uniq)
    end
    products.count
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    market_places = Spree::MarketPlace.where(:id => market_places_ids)
    if market_places.present?

      my_logger.info('calculationg discount')
      market_places.each do |market_place|
        error_hash = []
        error_hash << ['SKU', 'Price', 'Discount amount', 'Error Message']
        products.each do |product|
        begin
          smpp = Spree::SellersMarketPlacesProduct.where(:product_id => product.id, :market_place_id => market_place.id)
          if smpp.present?
            # if market_place.code != 'qoo10'
              variants = []
              variants << (product.variants.present? ? product.variants : product.master) if market_place.code
              variants = variants.flatten
              variants.each do |variant|
                pm = Spree::PriceManagement.where("variant_id=? AND market_place_id=?", variant.id, market_place.id).first rescue nil
                if pm.present? && (!variant_ids.present? || (variant_ids.present? && (variant_ids.include? variant.id)))
                  special_price = 0
                  if discount_type == 'percentage'
                    price = (pm.present? && pm.selling_price.present?) ? pm.selling_price : variant.price
                    discounted_price = price - (price*(discount_amount/100.00))
                    pm_special_price = pm.special_price rescue 0
                    special_price = (pm_special_price < discounted_price ) ? pm_special_price :  discounted_price
                    special_price = discounted_price if pm_special_price <= 0
                    if market_place.code == 'qoo10'
                      if discount_amount > 50
                        special_price = 0
                        error_hash << [variant.sku, pm.selling_price.to_s, discount_amount.to_s, 'On Qoo10 can not apply discount greater than 50%']
                      end

                    end
                  else
                    price = (pm.present? && pm.selling_price.present?) ? pm.selling_price : variant.price
                    if price > discount_amount
                      special_price = price - discount_amount
                      if special_price < (price/2) && market_place.code == 'qoo10'
                        special_price = 0
                        error_hash << [variant.sku, pm.selling_price.to_s, discount_amount.to_s, 'On Qoo10 discounted price should not be less then 50%of the price']
                      end
                    else
                      error_hash << [variant.sku, pm.selling_price.to_s, discount_amount.to_s, 'Discount amount is greater than price. Could not apply discount']
                    end
                  end
                  if special_price == 0
                    my_logger.info("Discount is calculated 0 for variant.sku pm_special = #{pm_special_price} calculated = #{discount_amount}")
                  end
                  pm.update_column(:special_price, special_price)
                end
              end
            # else
            #   price = product.selling_price
            #   discounted_price = price - (price*(discount_amount/100.00))
            #   pm_special_price = product.special_price rescue 0
            #   special_price = (pm_special_price < discounted_price ) ? pm_special_price :  discounted_price
            #   special_price = discounted_price if pm_special_price <= 0
            #   if special_price == 0
            #     my_logger.info("Discount is calculated 0 for variant.sku pm_special = #{pm_special_price} calculated = #{discount_amount}")
            #   end
            #   product.master.update_column(:special_price, special_price)
            # end

          end
        rescue Exception => e
          p '------------------------ '
          p e.message
          my_logger.info(e.message)
        end

      end
      seller_ids =  products.map(&:seller_id).uniq
      start_date = promotion.starts_at
      end_date = promotion.expires_at
        case market_place.code
          when 'lazada', 'zalora'
            PromotionJob.update_special_price_lazada(products,seller_ids, market_place,start_date,end_date,'start')
          when 'qoo10'
            PromotionJob.update_special_price_onqoo10(products,market_place,start_date,end_date)
        end
        if error_hash.present? && error_hash.size >= 2
          message = "You have some errors in applying promotion #{promotion.name} on #{market_place.name}, for details PFA. Promotion applied on rest of the products successfully"
          file = ImportJob.generate_excel(error_hash)
          Spree::ProductNotificationMailer::product_create_on_mp_status('swapnil.gadewar@anchanto.com,ritika.shetty@anchanto.com,cecile.courbon@anchanto.com', 'Promotion ', message, file, "Product_error_on_MP_#{Date.today.strftime('%d-%m-%Y')}.xls" ).deliver
        end
      end
    end
  end

  def self.update_special_price_lazada(products,seller_ids, market_place,start_date,end_date,p_action)
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_logger.info('applying discount on LAZADA/Zalora')
    error_hash = []
    begin
      # Time.zone = "Singapore"
      current_time = Time.zone.now
      seller_ids.each do |s_id|
        begin
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
          objects.each do |object|
            begin
            @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", s_id, market_place.id, object.id).try(:first)
            # taxon_market_places = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", object.taxons.first, market_place.id).try(:first)
            if @market_place_product.present? #&& taxon_market_places.present?
              variants = []
              variants << (object.variants.present? ? object.variants : object.master)
              variants = variants.flatten
              variants.each do |variant|
                #Product params details
                price_details = variant.price_details(market_place.code)
                price = ((price_details["selling_price"].present? && price_details["selling_price"].to_i > 0) ? price_details["selling_price"] : variant.price.to_f)
                seller_sku = variant.sku
                sale_price = ((price_details["special_price"].present? && price_details["special_price"].to_i > 0) ? price_details["special_price"] : "")
                sale_start_date = (object.available_on ? object.available_on : Time.now())
              if p_action == 'start'
                xml_obj["Product"]={ :Price=>price, :SellerSku=>seller_sku, :SalePrice=>sale_price, :SaleStartDate=>start_date, :SaleEndDate=>end_date, :ProductId=>''}
              else
                xml_obj["Product"]={ :Price=>price, :SellerSku=>seller_sku, :SalePrice=>sale_price, :SaleStartDate=>start_date, :SaleEndDate=>Time.zone.now,  :ProductId=>''}
              end

              end # end of variant loop
            # else
            #   error_hash << [object.sku,object.name, '','','Product not listed on Market Place']
            end
            rescue Exception => e
              my_logger.info(e.message)
            end
          end
          if !xml_obj.blank?
            request.body = xml_obj.to_xml.gsub("hash", "Request")
            res = http.request(request)
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=>true)
          end
        else
          error_hash << ['', '','',res_body[:ErrorResponse][:Head][:ErrorMessage]]
        end
        rescue Exception => e
          my_logger.info(e.message)
        end
      end
    rescue Exception => e
      error_hash << ['', '','',e.message]
    end
    if error_hash.present? && error_hash.size >= 2
      message = "You have some errors in applying promotion"
      file = ImportJob.generate_excel(error_hash)
      Spree::ProductNotificationMailer::product_create_on_mp_status('pooja.dudhatar@anchanto.com', 'Updating Product on MP status', message, file, "Product_error_on_MP_#{Date.today.strftime('%d-%m-%Y')}.xls" ).deliver
    end
  end

  def self.update_special_price_onqoo10(products, market_place,start_date,end_date,p_action='start')
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_logger.info('applying discount on Qoo10')
    error_hash = []
    products.each do |product|
      begin
        @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", product.seller_id, market_place.id, product.id)
        user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", product.seller_id, market_place.id).try(:first)
        if @market_place_product.present?
          qty =  !product.stock_products.blank? ? product.stock_products.where(:sellers_market_places_product_id=>@market_place_product.first.id).sum(&:count_on_hand) : 0
          market_place =  @market_place_product.first.market_place
          seller_code = @market_place_product.first.product.sku.present? ? @market_place_product.first.product.sku : "" rescue ""
          price_detail = product.master.price_details('qoo10')
          price =  price_detail["selling_price"].present? ? price_detail["selling_price"] : product.price
          price = price_detail["special_price"] if (price_detail["special_price"].present? && price_detail["special_price"] > 0)
          uri = URI(market_place.domain_url+'/GoodsOrderService.api/SetGoodsPrice')
          req = Net::HTTP::Post.new(uri.path)
          req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>@market_place_product.first.market_place_product_code.to_s,'SellerCode'=>seller_code.to_s,
                             'ItemPrice'=>price.to_s,'ItemQty'=>qty,'ExpireDate'=>''})
          res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end

          res_body = Hash.from_xml(res.body).to_json
          res_body = JSON.parse(res_body, :symbolize_names=>true)
          product.variants.each do |variant|
            # variant = Spree::Variant.find(v_id)
            variant_selling_price = variant.price_details("qoo10")["selling_price"]
            variant_selling_price = variant.price_details("qoo10")["special_price"] if (variant.price_details("qoo10")["special_price"].present? && variant.price_details("qoo10")["special_price"] > 0)
            final_price = variant_selling_price.to_f - price.to_f
            p "varian #{variant} - #{price}"
            seller_code = @market_place_product.first.product.sku.present? ? @market_place_product.first.product.sku : "" rescue ""
            option_name = variant.option_values.present? ? variant.option_values.first.option_type.presentation :  ""
            option_value = variant.option_values.present? ? variant.option_values.first.presentation :  product.short_name
            qty = !variant.stock_products.blank? ? variant.stock_products.where(:sellers_market_places_product_id=>@market_place_product.first.id).sum(:count_on_hand) : 0
            uri = URI(market_place.domain_url+'/GoodsBasicService.api/UpdateInventoryDataUnit')
            req = Net::HTTP::Post.new(uri.path)
            req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>@market_place_product.first.market_place_product_code,'SellerCode'=>seller_code.to_s,'OptionName'=>option_name,'OptionValue'=>option_value,'OptionCode'=>variant.sku.to_s,'Price'=>final_price.to_s,'Qty'=>qty.to_s})
            res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=>true)
            if res.code != "200"
              error_hash << [product.sku,product.name, '','',res_body[:StdResult][:ResultMsg]]
              # @error_message << user_market_place.first.market_place.name+": "+res_body[:StdResult][:ResultMsg]
              #market_place_product.update_attributes(:market_place_product_code=>market_place_product.market_place_product_code) if market_place_product.present?
            end
          end if product.variants.present?
          res_body = Hash.from_xml(res.body).to_json
          res_body = JSON.parse(res_body, :symbolize_names=>true)
          my_logger.info(res_body)
        end
      rescue Exception => e
        my_logger.info(e.message)
      end
    end
  end
  def self.close_discount_on_mp(products,market_places_ids,variant_ids,promotion)
    if variant_ids.present?
      products = Spree::Product.where(:id => Spree::Variant.where(:id => variant_ids).map(&:product_id).uniq)
    end
    my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
    my_logger.info('Close promotion')
    market_places = Spree::MarketPlace.where(:id => market_places_ids)
    if market_places.present?
      market_places.each do |market_place|
        products.each do |product|
          begin
            smpp = Spree::SellersMarketPlacesProduct.where(:product_id => product.id, :market_place_id => market_place.id)
            if smpp.present?
              # if market_place.code != 'qoo10'
                variants = []
                variants << (product.variants.present? ? product.variants : product.master)
                variants = variants.flatten
                variants.each do |variant|
                  pm = Spree::PriceManagement.where("variant_id=? AND market_place_id=?", variant.id, market_place.id).first rescue nil
                  if pm.present?  && (!variant_ids.present? || (variant_ids.present? && (variant_ids.include? variant.id)))
                    pm.update_column(:special_price, 0)
                  end
                end
              # else
              #   product.master.update_column(:special_price, 0)
              # end

            end
          rescue Exception => e
            my_logger.info(e.message)
          end
        end
        seller_ids =  products.map(&:seller_id).uniq
        start_date = promotion.starts_at
        end_date = (promotion.expires_at < Time.now) ? Time.now :  promotion.expires_at
        case market_place.code
          when 'lazada', 'zalora'
            PromotionJob.update_special_price_lazada(products,seller_ids, market_place,start_date,end_date,'close')
          when 'qoo10'
            PromotionJob.update_special_price_onqoo10(products,market_place,start_date,end_date,'close')
        end
      end
    end
  end
end