module Spree
  class DescriptionManagement < ActiveRecord::Base
    include ApplicationHelper
    
    attr_accessible :description, :market_place_id, :product_id, :meta_description, :package_content, :is_active

    belongs_to :market_place, class_name: 'Spree::MarketPlace'
    belongs_to :product, class_name: 'Spree::Product'
  
    default_scope { where(is_active: true) }
  
    validates_presence_of :market_place_id, :product_id, :meta_description, :package_content
    after_update :check_updated_fields

    def check_updated_fields
      # changed_fields =  self.changed
      product = self.product
      desc = !new_record? ? ProductJob.get_updated_fields(self.changed,self.market_place.code) : 'new_description'
      if desc.present?
        variants = product.variants.present? ? product.variants : product.master
        #product.recent_market_place_changes.create!(:seller_id => product.seller_id, :market_place_id => self.market_place_id, :description => desc.join(','), :update_on_fba=>false)
        if product.variants.present?
          variants.each do |v|
            v.recent_market_place_changes.create!(:product_id => product.id,:seller_id => product.seller_id, :market_place_id => self.market_place_id, :description => desc.join(','), :update_on_fba=>false) if !desc.blank?
          end
        else
          variants.recent_market_place_changes.create!(:product_id => product.id,:seller_id => product.seller_id, :market_place_id => self.market_place_id, :description => desc.join(','), :update_on_fba=>false) if !desc.blank?
        end
      end


    end

    # Update product decription on Qoo10
    def update_description_to_qoo10
      @error_message = []
      begin
        product = self.product
        smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", product.seller_id, self.market_place_id).first
        market_place = Spree::MarketPlace.find(self.market_place_id)
        item_description = self.description
        smpp = product.sellers_market_places_products.where(:market_place_id=>self.market_place_id).first
        seller_code = product.sku
        uri = URI(market_place.domain_url+'/GoodsBasicService.api/EditGoodsContents')
        req = Net::HTTP::Post.new(uri.path)
        req.set_form_data({'key'=>smp.api_secret_key.to_s, 'ItemCode'=>smpp.market_place_product_code.to_s, 'SellerCode'=>seller_code.to_s, 'Contents'=>item_description})
        res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
        if res.code == "200"
          res_body = Hash.from_xml(res.body).to_json
          res_body = JSON.parse(res_body, :symbolize_names=>true)
          if res_body[:StdResult][:ResultCode].to_i >= 0
          else
            @error_message << smp.market_place.name+": "+ res_body[:StdResult][:ResultMsg]
          end
        else
          @error_message << smp.market_place.name+": "+ res.message
        end
      rescue Exception => e
        @error_message << smp.market_place.name+": "+e.message
      end
      return @error_message.length > 0 ? @error_message.join("; ") : true
    end

    # Update product decription on Lazada
    def update_description_to_lazada
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
            item_description = product.description_details(market_place.code)
            description = item_description["description"]
            short_desc = item_description["meta_description"]
            package_content = item_description["package_content"]
            variants.each do |variant|
              seller_sku = variant.sku
              xml_obj["Product"]={:Description=>description, :SellerSku=>seller_sku,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content}}
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
  
  end
end
