module Spree
	Variant.class_eval do
    paginates_per 10
         include ApplicationHelper
		attr_accessible :subscribed_price, :stock_on_hand,:count_on_hand, :virtual_out_of_stock, :in_stock, :special_price, :rcp, :stock_in_hand, :selling_price, :fba_quantity, :upc, :is_created_on_fba, :validation_message, :skip_callbacks, :updated_on_fba, :parent_id
    attr_accessor :warehouse_discount, :skip_callbacks
		has_many :notifications, :class_name => "Spree::ProductNotification", :dependent => :destroy
    has_many :stock_products, dependent: :destroy
    has_many :price_managements, :class_name => "Spree::PriceManagement", :dependent => :destroy
    has_many :recent_market_place_changes, :class_name => "Spree::RecentMarketPlaceChange", :dependent => :destroy
    has_many :quantity_inflations
    #validate :retailer_price
    #scope :available ,joins(:stock_items).where("spree_stock_items.count_on_hand > ?", 0)
    scope :available, joins(:stock_products).where("spree_stock_products.count_on_hand > ?", 0)
    scope :update_fba, includes(:product).where(:updated_on_fba => false,:spree_products => {:is_approved => true, :kit_id => nil})
    #scope :create_fba, includes(:product).where(:is_created_on_fba => false,:spree_products => {:is_approved => true, :kit_id => nil})
    # validates_numericality_of :special_price, :less_than_or_equal_to => :selling_price, :allow_blank => true
    validate :selling_price_is_less_than_or_equal_to_price, :special_price_is_less_than_or_equal_to_selling_price
    validates :sku, uniqueness: true

    before_destroy :check_for_line_items

    after_save :update_kit_products_stock#, :check_for_update,:unless => :skip_callbacks
    after_save :check_validate, :unless => :skip_callbacks
    after_create :add_default_entries, :check_for_master, :create_stock_products, :unless => :skip_callbacks
    after_update :update_stock_on_stock_change, :unless => :skip_callbacks

    def add_log_on_update(message = 'default')
      QTY_LOG.info "#{Time.zone.now} Stock Updated for SKU=> #{self.sku} <=SKU with Remarks LOC-- #{message} --LOC updated Quantity :=> #{self.fba_quantity}"
    end

    def self.create_fba
      seller_ids = Spree::SellerMarketPlace.all.map(&:seller_id).uniq
      if seller_ids.present?
        return Spree::Variant.includes(:product).where("spree_variants.parent_id is null and spree_products.seller_id in (?)",seller_ids).where(:is_created_on_fba => false,:spree_products => {:is_approved => true, :kit_id => nil})
      end
    end

    # Create stock product entry when variant get created and listed on marketplace
    def create_stock_products
      begin
        product = self.product
        mp = product.market_places
        if mp.present?
          sellers_market_places_products = Spree::SellersMarketPlacesProduct.unscoped.where("product_id=?", product.id)
          sellers_market_places_products.each do |smpp|
            sp = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?",smpp.id, self.id)
            Spree::StockProduct.create(:sellers_market_places_product_id=>smpp.id, :variant_id=>self.id, :count_on_hand=>0, :virtual_out_of_stock=>false) if !sp.present?
          end
        end
      rescue Exception=> e
      end
    end

    # add default product name, stock, description and price as per market places
    def add_default_entries
      product = self.product
      if !self.is_master
        if product.master.present?
          product.master.stock_products.destroy_all 
          product.master.price_managements.destroy_all
          product.master.update_attributes(:is_created_on_fba => true, :updated_on_fba => true, :skip_callbacks => true)
        end  
      end   
      begin
        mp = product.market_places
        if mp.present?
          sellers_market_places_products = Spree::SellersMarketPlacesProduct.unscoped.where("product_id=?", product.id) 
          sellers_market_places_products.each do |smpp|
            sp = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?",smpp.id, self.id)
            if !sp.present?
              Spree::StockProduct.create(:sellers_market_places_product_id=>smpp.id, :variant_id=>self.id, :count_on_hand=>0, :virtual_out_of_stock=>false)
            else
              sp.update_all(:sellers_market_places_product_id=>smpp.id, :variant_id=>self.id)
            end
            pm = Spree::PriceManagement.where("market_place_id=? AND variant_id=?", smpp.market_place_id, self.id)
            if !pm.present?
              Spree::PriceManagement.create(:selling_price=>self.selling_price.to_f, :special_price=>self.special_price.to_f, :settlement_price=>0.0, :market_place_id=>smpp.market_place_id, :variant_id=>self.id)
            else
              pm.update_all(:selling_price=>self.selling_price.to_f, :special_price=>self.special_price.to_f, :settlement_price=>0.0)
            end
          end
        end
        self.list_for_mp rescue nil
          if self.parent_id.present?
            parent = self.get_parent
            self.update_attribute(:fba_quantity, parent.fba_quantity)
            msg = 'Model - variant / add default entries'
            self.add_log_on_update(msg) rescue QTY_LOG.error            
          end
      rescue Exception=> e
      end
    end

    # If new variant created then set master variant flag created on fba to true
    def check_for_master
      product = self.product
      begin
        variant = product.master
        if variant.present?
          variant.update_attributes(:is_created_on_fba => true, :updated_on_fba => true, :skip_callbacks => true) if variant != self
        end
      rescue Exception => e
        p '-----------'
        p e.message
      end
    end

    def list_for_mp
        market_places = self.product.market_places
        market_places.each do |market_place|
          desc = ProductJob.get_updated_fields(['new_variant'],market_place.code)
          self.recent_market_place_changes.create(:product_id => self.product.id,:seller_id => self.product.seller.id, :market_place_id => market_place.id, :description => desc.join(','), :update_on_fba=>false) if (desc.present? && !desc.blank?)
        end
    end

    # check and store which fields are updated (used to update on fba)
    def check_validate

      variants = (self.product.variants.present? ? (self.product.variants) : ([self.product.master]))
      vids = variants.map(&:id)
    if vids.include? self.id
      changed_fields =  self.changed
      msg = ''
      if (changed_fields & ["weight", "height", "width", "depth"]).present? || (!self.validation_message.present?) || new_record?

        msg = msg.present? ? msg + ", Width": msg+ 'Width' if !self.width.present? || self.width <=1
        msg = msg.present? ? msg + ', Height': msg + 'Height' if !self.height.present? || self.height <=1
        msg = msg.present? ? msg + ', Depth' : msg + 'Depth' if !self.depth.present? || self.depth <=1
        msg = msg.present? ? msg + ', Weight' : msg + 'Weight' if !self.weight.present? || self.weight <=1
        msg =  msg + ' should be greater than 1' if msg.present?

      end
      changed_fields =  changed_fields - ['updated_at','available_on', 'is_created_on_fba','updated_on_fba','stock_config_type','is_approved','cost_currency','id','product_id']
      market_places = self.product.market_places
      market_place_changes = self.changed - ['cost_price','retail_price','special_price','selling_price']
      if new_record?
        market_places = self.product.market_places
        market_places.each do |market_place|
          @market_place_product = Spree::SellersMarketPlacesProduct.where(:product_id => self.product.id,:seller_id => self.product.seller_id, :market_place_id => market_place.id)
          if @market_place_product.present?
            desc = ProductJob.get_updated_fields('new_variant',market_place.code)
            self.recent_market_place_changes.create(:product_id => self.product.id,:seller_id => self.product.seller.id, :market_place_id => market_place.id, :description => desc.join(','), :update_on_fba=>false) if (desc.present? && !desc.blank?)
          end
        end
      else
        if !changed_fields.blank?
          variants =  Spree::RecentMarketPlaceChange.where(:deleted_at => nil).where("description like '%new_variant%'").where(:product_id => self.product_id, :variant_id => self.id)
          if !variants.present?
            market_places.each do |market_place|
              @market_place_product = Spree::SellersMarketPlacesProduct.where(:product_id => self.product.id,:seller_id => self.product.seller_id, :market_place_id => market_place.id)
              if @market_place_product.present?
                desc = !new_record? ? ProductJob.get_updated_fields(market_place_changes,market_place.code) : 'new_variant'
                desc =  ProductJob.get_updated_fields('new_variant',market_place.code) if self.changed.include? 'id'
                self.recent_market_place_changes.create(:product_id => self.product.id,:seller_id => self.product.seller.id, :market_place_id => market_place.id, :description => desc.join(','), :update_on_fba=>false) if (desc.present? && !desc.blank?)
              end
            end
          end

        end
      end

      changed_fields = changed_fields & ['width','height','depth','weight','cost_price','name','upc','sku']
      if !new_record? && changed_fields.present? && self.is_created_on_fba
        self.update_attributes(:validation_message => msg, :updated_on_fba => false, :skip_callbacks => true)
        self.recent_market_place_changes.create(:product_id => self.product.id,:seller_id => self.product.seller.id, :description => changed_fields.join(','), :update_on_fba=>true) if !changed_fields.blank?
      else
        self.update_attributes(:validation_message => msg, :skip_callbacks => true)
      end

    end

    end
     # Check for the line item present for the variants before delete
    def check_for_line_items
      if self.line_items.present?
        errors.add(sku, "This variant is beign used can't be deleted.")
        false
      end
    end

    # Update stock on maket place on stock update
    def update_stock_on_stock_change
        if self.changed.include? 'fba_quantity'
          # p "#{self.sku} ------ fba_quantity changed"
          self.update_stock_after_change
        end
    end

    def update_stock_after_change
      ap " #{self.sku}------------- stock updated"
      #if (STOCKCONFIG[self.variant.product.stock_config_type] == "flat_quantity") || (STOCKCONFIG[self.variant.product.stock_config_type] == "default" && STOCKCONFIG[self.variant.product.seller.stock_config_type] == "flat_quantity")
      stock_values = {}
      variant = self.reload
      product = variant.product
      smps = product.seller.seller_market_places.where(:is_active=>true)
      mps = product.market_places.uniq
      type = STOCKCONFIG[product.stock_config_type] == "default" ? STOCKCONFIG[product.seller.stock_config_type] : STOCKCONFIG[product.stock_config_type]
      case type
        when "flat_quantity"
          stock_products = variant.stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id IN (?)", smps.map(&:market_place_id))
          stock_values.merge!(variant.id=>Spree::StockProduct.flat_quantity_setting(stock_products, variant, mps))
        when "fixed_quantity"
          stock_products = variant.stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id IN (?) AND variant_id = ?", smps.map(&:market_place_id), variant.id)
          stock_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps))
        when "percentage_quantity"
          stock_products = variant.stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id IN (?)", smps.map(&:market_place_id))
          stock_values.merge!(variant.id=>Spree::StockProduct.percentage_quantity_setting(stock_products, variant, mps))
      end
      # Stock update to marketplaces
      update_stock_market_places(stock_values) if stock_values.present?
      #end
      child = self.get_child_variants
      if child.present?
        child.each do |c|
           !c.quantity_inflations.present? ? c.update_attributes(:fba_quantity => self.fba_quantity) : c.update_column(:fba_quantity , self.fba_quantity)
            msg = 'Model - variant / update stock after change'
            c.add_log_on_update(msg) rescue QTY_LOG.error           
        end
      end
    end

    # Update stock of kit when product stock changes
    def update_kit_products_stock
      kits = Spree::Kit.includes("kit_products").where("spree_kit_products.variant_id=?", self.id)
      kits.each do |kit|
        lowest_stock = 0
        kit_n=Spree::Kit.find(kit) rescue nil
        kit_n.kit_products.each_with_index do |kp, ind|
          qty = (kp.variant.fba_quantity/kp.quantity).to_i
          if ind == 0
            lowest_stock = qty
          elsif (ind!=0 && lowest_stock > qty)
            lowest_stock = qty
          end
        end if kit_n.present?
        kit.product.master.update_column(:fba_quantity, lowest_stock)
        msg = 'Model - Variant / update kit products stock 1'
        kit.product.master.add_log_on_update(msg) rescue QTY_LOG.error        
        kit.update_attributes!(:quantity=>lowest_stock)
        kit.reload
        child = kit.product.master.get_child_variants
        if child.present?
          child.each do |c|
            c.update_attributes(:fba_quantity => kit.quantity)
            msg = 'Model - Variant / update kit products stock 2'
            c.add_log_on_update(msg) rescue QTY_LOG.error        
          end
        end
      end

    end

    def in_stock?(quantity=1)
      #Spree::Stock::Quantifier.new(self).can_supply?(quantity)
    end

    def warehouse_discount
      if self.special_price.present?
        (100 - (self.special_price * 100 / self.price)).to_f.round(0)
      else
        0
      end
    end

    # Method return stock in hand for product as well as variant
    def stock_in_hand
      sum = 0
      self.stock_locations.active.each do |location|
        stock_products.where(:variant_id => self.id).each do |item|
          sum = sum + item.count_on_hand
        end if stock_products.where(:variant_id => self.id).present?
      end if self.stock_locations.present?
     #return self.stock_items.sum
    end

    def stock_on_hand
    	sum = 0
    	self.stock_locations.active.each do |location|
    		location.stock_items.where(:variant_id => self.id).each do |item|
    			sum = sum + item.count_on_hand
    		end if location.stock_items.where(:variant_id => self.id).present?
    	end if self.stock_locations.present?
     #return self.stock_items.sum
    end

    def price_in(currency)
      prices.select{ |price| price.currency == currency }.first || Spree::Price.new(variant_id: self.id, currency: currency)
    end

    def track_inventory?
      true
    end

    # Price details get by market place code
    def price_details(code)
      price = {}
      mp = Spree::MarketPlace.find_by_code(code)
      if mp.present?
        pm = Spree::PriceManagement.where("variant_id=? AND market_place_id=?", self.id, mp.id)
        price.merge!("selling_price"=>(pm.present? ? pm.first.selling_price : self.selling_price))
        price.merge!("special_price"=>(pm.present? ? pm.first.special_price : self.special_price))
        price.merge!("settlement_price"=>(pm.present? ? pm.first.settlement_price : 0.0))
      end
      return price
    end


    def qoo10_item_price(code)
      price_detail = self.price_details(code)
      price = 0.00
      if price_detail.present?
        price = price_detail["selling_price"] if price_detail["selling_price"]
        price = price_detail["special_price"] if (price_detail["special_price"].present? && price_detail["special_price"] > 0 )
      else
        price = self.product.selling_price
        price = self.product.special_price if (self.product.special_price.present? && self.product.special_price > 0)
      end
      return price
    end

    #get parent variant
    def get_parent
      if self.parent_id.present?
        return Spree::Variant.find(self.parent_id)
      else
        return nil
      end
    end

    def get_child_variants
      return Spree::Variant.where(:parent_id => self.id)
    end

    # FBA call to sync product quantity
    def self.fetch_qty_from_fba(smp, variant)
      fba_api_key = smp.fba_api_key
      authorization = Base64.encode64("#{USER}:#{PASSWORD}")
      product_qty_path = FULFLMNT_PATH+"/fetch_stock"
      @message = ""
      if fba_api_key.present? && smp.fba_signature.present?
        begin
          contact_person_email = smp.seller.contact_person_email.present? ? smp.seller.contact_person_email : nil
          variant = variant.get_parent if variant.parent_id.present?
          resp = RestClient.get(product_qty_path, {:params=>{:api_key=>fba_api_key.strip,:version=>"2.0",:product_skus=>variant.sku.strip,:request_type=>"selected",:per_page=>50,:page=>1,:signature=>smp.fba_signature.strip,:email=>contact_person_email.strip, :Authorization=>authorization}})
          resp = JSON.parse(resp)
          # update quantity from FBA
          if resp["response"] == "success"
            qty = (resp["products"].first["quantity"].to_i > 0 ? resp["products"].first["quantity"].to_i : 0) rescue 0
            variant.quantity_inflations.present? ? (variant.update_column(:fba_quantity,qty) ):(variant.update_attributes(:fba_quantity=>qty) )
            msg = 'Model - Variant / fetch qty from fba'
            variant.add_log_on_update(msg) rescue QTY_LOG.error        
            variant.reload
            child = variant.get_child_variants
            if child.present?
              child.each do |c|
                !c.quantity_inflations.present? ? c.update_attributes(:fba_quantity => variant.fba_quantity) : c.update_column(:fba_quantity , variant.fba_quantity)
              end
            end
          end
=begin
          # check condition for single market place and quantity change happend on fba
          if (variant.product.market_places && variant.product.market_places.count == 1) && ((variant.stock_products.blank?) || (variant.fba_quantity != variant.stock_products.first.count_on_hand))
            mp = variant.product.market_places.first
            product = variant.product
            market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", product.seller_id, mp.id, product.id).first
            if market_place_product.present?
              if variant.stock_products.blank?
                variant.stock_products.create(sellers_market_places_product_id: market_place_product.id, variant_id: variant.id, count_on_hand: variant.fba_quantity, virtual_out_of_stock: false)
              else
                variant.stock_products.first.update_attributes(:count_on_hand=>variant.fba_quantity)
              end
              case product.market_places.first.code
              when "qoo10"
                @message = Spree::StockMovement.stock_update_qoo10(product, mp.id, variant.fba_quantity, variant.stock_products.first, smp, market_place_product, variant.fba_quantity)
              when "lazada"
                @message = Spree::StockMovement.stock_update_lazada(product, mp.id, variant.fba_quantity, variant.stock_products.first, smp, market_place_product, variant.fba_quantity)
              end
            end
            @message = (@message == true ? "" : @message)
          end
=end
        rescue Exception => e
          @message =  e.message
        end
        @message = "FBA quantity fetch successfully!" if @message.empty?
      else
        @message = "Ooops, API key or signature not mapped"
      end
      return @message
    end

    #Add and update product variant on lazada market place
    def update_variant_qoo10(action, market_place_product, user_market_place, option_name, option_value, object)
      begin
        @object = object
        product_selling_price = @object.product.selling_price.present? ? @object.product.selling_price : @object.product.price
        variant_selling_price = @object.price_details("qoo10")["selling_price"]
        price = variant_selling_price.to_f - product_selling_price.to_f
        seller_code = market_place_product.product.sku.present? ? market_place_product.product.sku : "" rescue ""
        if action == "new"
          qty =  0
        else
          qty = !@object.stock_products.blank? ? @object.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand) : 0
        end
        if action == "new"
          # uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/InsertInventoryDataUnit')
        elsif action == "edit"
          # uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/UpdateInventoryDataUnit')
        end
        req = Net::HTTP::Post.new(uri.path)
        req.set_form_data({'key'=>user_market_place.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code,'SellerCode'=>object.sku.to_s,'OptionName'=>option_name,'OptionValue'=>option_value,'OptionCode'=>object.sku.to_s,'Price'=>price.to_s,'Qty'=>qty.to_s})
        res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
        if res.code == "200"
           res_body = Hash.from_xml(res.body).to_json
           res_body = JSON.parse(res_body, :symbolize_names=>true)
           market_place_product.update_attributes(:market_place_product_code=>market_place_product.market_place_product_code) if market_place_product.present?
        end
      rescue Exception => e
        res = e.message
      end
      return res
    end

   def update_variant_lazada(action, market_place_product, user_market_place, option_name, option_value, object, product)
      begin
        @object = object
        @res = nil
        taxon_market_plcaes = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", product.taxons.first.id, market_place_product.market_place_id)
        market_place = market_place_product.market_place
        Time.zone = "Singapore"
        current_time = Time.zone.now
        user_id = user_market_place.contact_email ? user_market_place.contact_email : "tejaswini.patil@anchanto.com"
        # http = Net::HTTP.new("https://sellercenter-api.lazada.sg")
        if action == "new"
          product_params = {"Action"=>"ProductCreate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
        else
          product_params = {"Action"=>"ProductUpdate", "Timestamp"=>current_time.to_time.iso8601, "UserID"=>user_id, "Version"=>"1.0"}
        end
        signature = generate_lazada_signature(product_params, user_market_place)
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
          brand = product.brand ? product.brand.name : "3M" #need to add default brand for us
          description = product.description_details(market_place.code)
          price_details = @object.price_details(market_place.code)
          name = product.name+"-"+option_name.to_s
          price = @object.price.to_f
          primary_category = taxon_market_plcaes.first.market_place_category_id
          category = ''
          seller_sku = @object.sku
          parent_sku = @object.sku
          tax_class = 'default'
          sale_price = price_details["selling_price"]
          sale_start_date = product.available_on ? product.available_on : Time.now()
          sale_end_date = ''
          shipment_type = 'dropshipping'
          product_id = ''
          conditon = 'new'
          short_desc = description["meta_description"]
          package_content = description["package_content"]
          height = @object.height.to_f
          weight = @object.weight.to_f
          length = @object.depth.to_f
          width = @object.width.to_f
          quantity = !@object.stock_products.blank? ? @object.stock_products.where(:sellers_market_places_product_id=>market_place_product.id).sum(:count_on_hand) : 0
          variation = option_value
          xml_obj = {:Product=>{:Brand=>brand, :Description=>description["description"], :Name=>name, :Price=>price, :PrimaryCategory=>primary_category, :SellerSku=>seller_sku, :ParentSku=>parent_sku, :TaxClass=>tax_class, :Variation=>variation, :SalePrice=>sale_price, :SaleStartDate=>sale_start_date, :SaleEndDate=>sale_end_date, :ShipmentType=>shipment_type, :ProductId=>product_id, :Condition=>conditon, :Quantity=>quantity,:ProductData=>{:ShortDescription=>short_desc, :PackageContent=>package_content, :PackageHeight=>height, :PackageLength=>length, :PackageWidth=>width, :PackageWeight=>weight}}}
          request.body = xml_obj.to_xml.gsub("hash", "Request")
          res = http.request(request)
          res_body = Hash.from_xml(res.body).to_json
          res_body = JSON.parse(res_body, :symbolize_names=>true)
          if res.code == "200" && res_body[:ErrorResponse]
             # code to insert variant entry whenever failed to list the variants on lazada
             @sync_maket_place_variant = Spree::SyncMarketPlaceVariant.create(:seller_id => market_place_product.seller_id, :market_place_id => market_place_product.market_place_id, :product_id => market_place_product.product_id, :variant_id => @object.id, :variant_sku => @object.sku) if action == "new"
             @res = user_market_place.market_place.name+": "+res_body[:ErrorResponse][:Head][:ErrorMessage]
          else
              mp_product_code = res_body[:SuccessResponse][:Head][:RequestId]
              market_place_product.update_attributes(:market_place_product_code=>mp_product_code) if market_place_product.present?
          end
        else
          @res = "#{market_place.code}: Signature can not be generated."
        end
      rescue Exception => e
        @res = e.message
      end
      return @res
    end

    # Method to update stock product for the variant
    def update_stock_for_variant
      stock_values = {}
      product = self.product
      seller = product.seller
      type = STOCKCONFIG[product.stock_config_type] == "default" ? STOCKCONFIG[seller.stock_config_type] : STOCKCONFIG[product.stock_config_type]
      smps = seller.seller_market_places.where(:is_active=>true)
      mps = seller.market_places.where("spree_market_places.id IN (?)", smps.map(&:market_place_id))
      begin
        stock_products = self.stock_products.where("sellers_market_places_product_id IN (?)", product.sellers_market_places_products.where("market_place_id IN (?)",smps.map(&:market_place_id)).map(&:id))
        if stock_products.present?
          case type
            when "fixed_quantity"
              stock_values.merge!(self.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, self, mps))
            when "percentage_quantity"
              stock_values.merge!(self.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, self, mps))
              #stock_values.merge!(self.id=>Spree::StockProduct.percentage_quantity_setting(stock_products, self, mps))
            when "flat_quantity"
              stock_values.merge!(self.id=>Spree::StockProduct.flat_quantity_setting(stock_products, self, mps))
          end # end of case
        end
      rescue Exception => e
      end
      return stock_values
    end

    #get available option values
    def get_option_values(option_type,product)
      selected_values = []

      product.variants.each do |variant|
        if variant != self
          selected_values << variant.option_values.map(&:id)
        end
      end
      selected_values = selected_values.flatten
      selected_values = selected_values.uniq
      @option_values = Spree::OptionValue.where(:option_type_id => option_type.id ).where("id NOT IN (?)",selected_values) if selected_values.present?
      @option_values = Spree::OptionValue.where(:option_type_id => option_type.id ) if !selected_values.present?
      p @option_values
      p '------'
      return @option_values
    end
    private
    def create_stock_items
      self.product.seller.stock_locations.each do |stock_location|
        stock_location.propagate_variant(self) if stock_location.propagate_all_variants?
      end
    end

    def retailer_price
      errors.add(:cost_price, "must enter") if cost_price.nil? && product.seller.type.try(:price_based?)
    end

    # added validation for selling price
    def selling_price_is_less_than_or_equal_to_price
      errors.add(:selling_price, "should be less than or equal to price") if selling_price.present? && selling_price.to_f > price.to_f
    end
    def special_price_is_less_than_or_equal_to_selling_price
      errors.add(:special_price, "should be less than or equal to price") if special_price.present? && special_price.to_f > selling_price.to_f
    end
  end
end
