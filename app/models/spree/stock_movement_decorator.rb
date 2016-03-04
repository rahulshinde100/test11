Spree::StockMovement.class_eval do
   include ApplicationHelper
    belongs_to :stock_item, class_name: 'Spree::StockItem'
    belongs_to :originator, polymorphic: true

    attr_accessible :quantity, :stock_item, :stock_item_id, :originator, :action

    after_create :update_stock_item_quantity

    validates :stock_item, presence: true
    validates :quantity, presence: true

    scope :recent, order('created_at DESC')

    def readonly?
      !new_record?
    end

    # Code to update the kit stock for kit as product
    def self.update_kit_stock(variant_id)
       @variant = Spree::Variant.find(variant_id)
       if @variant.product.present?
         if @variant.product.kit.present?
            @variant.product.kit.update_attributes(:quantity=> @stock_product.count_on_hand)
         end
       end
    end

    def self.get_parameters_in_request(smp_id, variant_id, count_on_hand)
      begin
        @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", smp_id, variant_id).first
        if @stock_product.present?
          @stock_product.update_column(:count_on_hand, count_on_hand)
        else
          @stock_product = Spree::StockProduct.create(:sellers_market_places_product_id => smp_id, :variant_id => variant_id, :count_on_hand => count_on_hand, :virtual_out_of_stock => false)
        end

        # Call method to update the kit stock after_save callback
        #update_kit_stock(variant_id)

        market_place = @stock_product.sellers_market_places_product.market_place
        if @stock_product.present?
          @res_hash = []
          product = @stock_product.sellers_market_places_product.product
          @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", product.seller_id, product.id, market_place.id)
          @taxon_market_plcaes = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", product.taxons.first.id, @sellers_market_places_product.first.market_place_id) if product.taxons.present?
          if @taxon_market_plcaes.present?
            if !@sellers_market_places_product.blank? && @sellers_market_places_product.first.market_place_product_code.present? && !@taxon_market_plcaes.blank?
              user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", product.seller_id, market_place.id)
              if !user_market_place.blank? && !user_market_place.first.api_secret_key.nil?
                case market_place.code
                when "qoo10"
                  res = stock_update_qoo10(product, market_place.id, count_on_hand, @stock_product, user_market_place.first, @sellers_market_places_product.first, count_on_hand)
                when "lazada" , "zalora"
                  res = stock_update_lazada(product, market_place.id, count_on_hand, @stock_product, user_market_place.first, @sellers_market_places_product.first, count_on_hand)
                end
                @res_hash << (market_place.name+": "+ res) if res != true
              else
                @error_message = "Api key or Secret key is missing"
              end
            end
          else
            @error_message = "Please map market place category to list product."
          end
        end
      rescue Exception => e
        @error_message = e.message
      end
    end

    def self.stock_update_qoo10(product, mp_id, quantity, stock_product, user_market_place, market_place_product, total_stock_count)

      @error_message = ""
      begin
        @stock_product = stock_product
        seller_code = @stock_product.variant.sku.present? ? @stock_product.variant.sku : "" rescue ""
        expiry_date = (Time.now + 1.year).strftime("%Y-%m-%d")
        market_place = Spree::MarketPlace.find(mp_id)

        if @stock_product.variant.is_master
          uri = URI(market_place.domain_url+'/GoodsOrderService.api/SetGoodsInventory')
          req = Net::HTTP::Post.new(uri.path)
          req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code.to_s,'SellerCode'=>seller_code.to_s,'ItemQty'=>quantity.to_s,'ExpireDate'=>expiry_date.to_s})
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
        else
          option_names = ""
          option_values = ""
          @stock_product.variant.option_values.each do |v|
            option_names = option_names + v.option_type.name + (@stock_product.variant.option_values.last == v ? "" : "||*")
            option_values = option_values + v.name + (@stock_product.variant.option_values.last == v ? "" : "||*")
          end if @stock_product.variant.option_values.present?
          if !@stock_product.variant.option_values.present?
            variant = stock_product.variant
            parent = variant.get_parent if variant.parent_id.present?
            short_name = parent.present? ? parent.product.short_name : product.short_name
            option_names = variant.product.option_types.first.presentation
            option_values = short_name

          end
          uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/UpdateInventoryQtyUnit')
          req = Net::HTTP::Post.new(uri.path)
          req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>@stock_product.sellers_market_places_product.market_place_product_code.to_s,'SellerCode'=>seller_code.to_s,'OptionName'=>option_names,'OptionValue'=>option_values,'OptionCode'=>'','Qty'=>total_stock_count.to_s})
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end

        end
        if res.code == "200"
          expiry_date = (Time.now + 1.year).strftime("%Y-%m-%d")
          uri_total = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsOrderService.api/SetGoodsInventory')
          req_total = Net::HTTP::Post.new(uri_total.path)
          total_variant_stock = product.stock_products.includes(:sellers_market_places_product=>"market_place").where("spree_market_places.id=?",mp_id).sum(&:count_on_hand)
          p total_stock_count
          total_variant_stock = 0 if total_variant_stock < 0
          #req_total.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code,'SellerCode'=>seller_code.to_s,'ItemQty'=>product.stock_products.sum(&:count_on_hand).to_s,'ExpireDate'=>expiry_date.to_s})
          req_total.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code.to_s,'SellerCode'=>seller_code.to_s,'ItemQty'=>total_variant_stock.to_s,'ExpireDate'=>expiry_date.to_s})
          res_total = Net::HTTP.start(uri_total.hostname, uri_total.port) do |http|http.request(req_total)end

        else
          @error_message = res.message
        end
      rescue Exception => e
        @error_message = e.messsage
      end

      return @error_message && @error_message.length > 0 ? @error_message : true
    end

    def self.stock_update_lazada(product, mp_id, quantity, stock_product, user_market_place, market_place_product, total_stock_count)
      @error_message = ""
      @stock_product = stock_product
      market_place = Spree::MarketPlace.find(mp_id)
      begin
        Time.zone = "Singapore"
        current_time = Time.zone.now
        user_id = user_market_place.contact_email ? user_market_place.contact_email : "tejaswini.patil@anchanto.com"
        http = Net::HTTP.new(market_place.domain_url)
        product_params = {"Action"=>"ProductUpdate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
        signature = ApplicationController.helpers.generate_lazada_signature(product_params, user_market_place)
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
          #Product params details
          seller_sku = @stock_product.variant.sku
          # Fetch reserved stock from Lazada
          res_stock = Spree::StockMovement.get_reserver_stock_from_lazada([seller_sku], user_market_place)
          quantity = (total_stock_count + res_stock[res_stock].to_i)
          quantity = 0 if quantity < 0
          xml_obj = {:Product=>{:SellerSku=>seller_sku,:Quantity=>quantity}}

          request.body = xml_obj.to_xml.gsub("hash", "Request")
          res = http.request(request)
          res_body = Hash.from_xml(res.body).to_json
          res_body = JSON.parse(res_body, :symbolize_names=>true)
          if res.code == "200" && res_body[:SuccessResponse]
            @error_message = ""
          else
            @error_message = user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
          end
        else
          @error_message = "#{market_place.name}: Signature can not be generated."
        end
      rescue Exception => e
        @error_message = e.message
      end
      return @error_message && @error_message.length > 0 ? @error_message : true
    end

    def self.stock_update_lazada_bulk(stock_hash)
      @error_message = []
      stock_hash.each do |smp_id, stocks|
        begin
          user_market_place = Spree::SellerMarketPlace.find(smp_id)
          market_place = user_market_place.market_place
          xml_obj = {}
          xml_obj = xml_obj.compare_by_identity
          Time.zone = "Singapore"
          current_time = Time.zone.now
          user_id = user_market_place.contact_email
          http = Net::HTTP.new(market_place.domain_url)
          product_params = {"Action"=>"ProductUpdate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
          signature = ApplicationController.helpers.generate_lazada_signature(product_params, user_market_place)
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
            my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
            # Fetching reserved quantity from Lazada seller centre             
            res_stocks = Spree::StockMovement.get_reserver_stock_from_lazada(stocks.first.keys, user_market_place)
            my_logger.info('================= stock_update_lazada_bulk')
            stocks.first.each do |sku, qty|
              res_qty = (qty + res_stocks[sku].to_i)
              res_qty = 0 if res_qty < 0
              xml_obj["Product"]={:SellerSku=>sku,:Quantity=>res_qty}
            end

            request.body = xml_obj.to_xml.gsub("hash", "Request")
            my_logger.info(request.body)
            res = http.request(request)
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=>true)
            if res.code == "200" && res_body[:SuccessResponse]
            else
              @error_message << user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
            end
          else
            @error_message << "#{market_place.name}: Signature can not be generated."
          end
        rescue Exception => e
          @error_message << e.message
        end
        return (@error_message.present? ? @error_message.join("; ") : true)
      end
    end
    
    def self.get_reserver_stock_from_lazada(skus, smp)
      my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
      res_stock = {}
      Time.zone = "Singapore"
      current_time = Time.zone.now
      market_place = smp.market_place
      begin
        user_id = smp.contact_email ? smp.contact_email : "tejaswini.patil@anchanto.com"
        http = Net::HTTP.new(market_place.domain_url)
        product_params = {"Action"=>"GetProducts", "SkuSellerList"=>skus, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
        # signature = ApplicationController.helpers.generate_lazada_signature(product_params, smp)
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
          res = http.request(request)
          res_body = Hash.from_xml(res.body).to_json
          res_body = JSON.parse(res_body, :symbolize_names=>true)
          if res.code == "200" && res_body[:SuccessResponse]
            if res_body[:SuccessResponse][:Body].present? && res_body[:SuccessResponse][:Body][:Products].present? && res_body[:SuccessResponse][:Body][:Products][:Product].present?
              products = res_body[:SuccessResponse][:Body][:Products][:Product]
              # products = res_body[:SuccessResponse][:Body][:Products]
              my_logger.info("inprocess quantity hash  #{products}")
              products = [products] if !products.is_a?(Array)
              products.each do |product|
                begin
                  if skus.include?(product[:SellerSku])
                    res_stock.merge!(product[:SellerSku]=>product[:ReservedStock].to_i)
                  else
                    res_stock.merge!(product[:SellerSku]=>0)
                  end
                  my_logger.info(res_stock)
                rescue Exception => e
                end
              end
            end
          end
        end
      rescue Exception => e
      end
      my_logger.info('----------------------')
      my_logger.info(res_stock)
      return res_stock
    end

    private

    def update_stock_item_quantity
      return unless self.stock_item.should_track_inventory?
      stock_item.adjust_count_on_hand quantity
    end

end
