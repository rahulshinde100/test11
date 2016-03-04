module Spree
  class TitleManagement < ActiveRecord::Base
    include ApplicationHelper
    
    attr_accessible :name, :market_place_id, :product_id, :is_active

    belongs_to :market_place, class_name: 'Spree::MarketPlace'
    belongs_to :product, class_name: 'Spree::Product'
  
    default_scope { where(is_active: true) }
  
    validates_presence_of :market_place_id, :product_id, :name
    after_update :check_updated_fields

    def check_updated_fields
      # changed_fields =  self.changed
      product = self.product
      desc = !new_record? ? ProductJob.get_updated_fields(self.changed,self.market_place.code) : 'new_description'
      variants = product.variants.present? ? product.variants : product.master
      #product.recent_market_place_changes.create!(:seller_id => product.seller_id, :market_place_id => self.market_place_id, :description => desc.join(','), :update_on_fba=>false)
      if desc.present?
        if product.variants.present?
          variants.each do |v|
            v.recent_market_place_changes.create!(:product_id => product.id,:seller_id => product.seller_id, :market_place_id => self.market_place_id, :description => desc.join(','), :update_on_fba=>false) if !desc.blank?
          end
        else
          variants.recent_market_place_changes.create!(:product_id => product.id,:seller_id => product.seller_id, :market_place_id => self.market_place_id, :description => desc.join(','), :update_on_fba=>false) if !desc.blank?
        end
      end
    end

     # Update product decription on Lazada
    def update_product_title_to_lazada
      @error_message = []
      begin
        product = self.product
        smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", product.seller_id, self.market_place_id).first
        smpp = product.sellers_market_places_products.where(:market_place_id=>self.market_place_id).first
        market_place = self.market_place
        variants = []
        variants << (product.variants.present? ? product.variants : product.master)
        variants = variants.flatten
        begin
          Time.zone = "Singapore"
          current_time = Time.zone.now
          user_id = smp.contact_email ? smp.contact_email : "tejaswini.patil@anchanto.com"
          http = Net::HTTP.new(market_place.domain_url)
          product_params = {"Action"=>"ProductUpdate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
          signature = generate_lazada_signature(product_params, smp)
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
            item_title = product.title_details(market_place.code)
            title = (object.variants.present? ? (item_title["title"].to_s+"-"+variant.option_values.first.presentation.to_s) : item_title["title"].to_s)
            variants.each do |variant|
              seller_sku = variant.sku
              xml_obj["Product"]={:Name=>title.to_s, :SellerSku=>seller_sku}
            end # end of variant loop
            request.body = xml_obj.to_xml.gsub("hash", "Request")
            res = http.request(request)
            res_body = Hash.from_xml(res.body).to_json
            res_body = JSON.parse(res_body, :symbolize_names=>true)
            if res.code == "200" && res_body[:SuccessResponse]
              @error_message << ""
            else
              @error_message << smp.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
            end
          else
            @error_message << "#{market_place.code}: Signature can not be generated."
          end
        rescue Exception => e
          @error_message << smp.market_place.name+": "+e.message  
        end
      rescue Exception => e
        @error_message << smp.market_place.name+": "+e.message
      end
      return @error_message.length > 0 ? @error_message.join("; ") : true
    end

    def get_mp_title(product,mp_id)
      Spree::TitleManagement.where(:product_id => product.id, :market_place_id=>mp_id).first.name rescue product
    end
  end
end
