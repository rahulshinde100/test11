module Spree::OrderHelper

  # To change state of lazada orders to ready to ship
  def order_state_to_rts_lazada(order)
    @error_message = ""
    s_id = order.seller_id.present? ? order.seller_id : nil
    smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", s_id, order.market_place_id).first rescue nil
    if smp.present?
      begin
        Time.zone = "Singapore"
        current_time = Time.zone.now
        user_id = smp.contact_email ? smp.contact_email : "tejaswini.patil@anchanto.com"
        list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
        signature_lt = generate_lazada_signature(list_item_params, smp)
        market_place = order.market_place
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
            #shipping_company = (Rails.env.eql?('development') || Rails.env.eql?('test') ? "Singpost" : "Anchanto Seller Fleet ")
            shipping_company = smp.shipping_code
            change_state_params = {"Action"=>"SetStatusToReadyToShip", 'DeliveryType' => 'dropship', 'OrderItemIds' => @order_item_ids.to_json, 'ShippingProvider' => shipping_company, "TrackingNumber"=>order.fulflmnt_tracking_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
            signature = generate_lazada_signature(change_state_params, smp)
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
              if res.code == "200"
                res_body = Hash.from_xml(res.body).to_json
                res_body = JSON.parse(res_body, :symbolize_names=>true)
                if res_body[:ErrorResponse]
                  @error_message = res_body[:ErrorResponse][:Head][:ErrorMessage]
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

end

