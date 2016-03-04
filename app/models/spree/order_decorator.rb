module Spree
	Order.class_eval do
	  include ApplicationHelper
    attr_accessible :delivery_date, :delivery_time, :send_as_gift, :greating_message, :shipping_method_id, :user_id, :order_state,
     :user_name, :shipping_category, :pickup_during, :oms_shipment_state, :market_place_id, :market_place_order_no,
     :market_place_order_status, :fulflmnt_state, :fulflmnt_tracking_no, :market_place_details, :item_total, :total, :payment_total,
     :ship_address_id, :bill_address_id, :state, :is_cancel, :delivered_at, :number, :order_date, :last_updated_date, :cart_no, :invoice_details, :order_canceled_date, :seller_id, :cancel_on_fba
    serialize :market_place_details, JSON
    #serialize :invoice_details, HTML
    belongs_to :shipping_method
    belongs_to :market_place
    belongs_to :seller
    has_one  :oms_log, :dependent => :destroy
    has_many :mp_order_line_items

    validates_presence_of :market_place_order_no
    validates :market_place_order_no, :uniqueness => {:scope => :seller_id}
    validates_presence_of :seller_id, :market_place_id

    scope :abandoned_orders, where(:completed_at => nil).order("created_at DESC")
    remove_checkout_step :confirm
    remove_checkout_step :complete

    # added scope to not fetch spree orders
    default_scope where("email not in (?) and market_place_id is not null",  'spree@example.com')
    #default_scope where("market_place_id is not null")

    #remove this method once Spree fix this issue
    #please check https://github.com/spree/spree/commit/7ae239253100afc9b17203f58331c571cbf75923
    def associate_user!(user)
      self.user = user
      self.email = user.email
      self.created_by = user if self.created_by.blank?
      if persisted?
        # immediately persist the changes we just made, but don't use save since we might have an invalid address associated
        self.class.unscoped.where(id: id).update_all(email: user.email, user_id: user.id)
        #self.class.unscoped.where(id: id).update_all(email: user.email, user_id: user.id, created_by_id: self.created_by_id)
      end
    end

    def confirmation_required?
      return false
    end

    def self.build_from_api(user, params)
      #order = create
      order = user.orders.where("state != 'complete'").last
      order = create unless order
      order.update_attributes(:user_id => user.id,:email => user.email)
      params[:line_items_attributes] ||= []
      unless params[:line_items_attributes].empty?
        params[:line_items_attributes].each do |line_item|
          if line_item[:is_pick_at_store] && line_item[:stock_location_id]
            order.contents.add(Spree::Variant.find(line_item[:variant_id]), line_item[:quantity], line_item[:is_pick_at_store],line_item[:stock_location_id])
          else
            order.contents.add(Spree::Variant.find(line_item[:variant_id]), line_item[:quantity], false,nil)
          end
        end
      end
      order
    end

    def shipping_category
      self.products.each do |product|
        if product.shipping_category.present? && product.shipping_category.is_99minute?
          return 1
          break
        elsif product.shipping_category.present? && product.shipping_category.is_same_day_shipping?
          return 2
          break
        else
          return 3
        end
      end if !self.products.blank?
    end

    def pickup_during
      unless self.completed_at.nil?
        self.completed_at + 6.days
      end
    end

    def pickup_items
      self.line_items.where(is_pick_at_store: true)
    end

    def general_items
      self.line_items.collect{|item| item  unless item.product.shipping_category == Spree::ShippingCategory.same_day_shipping || item.product.shipping_category == Spree::ShippingCategory.minutes99}.compact
    end

    def same_day_items
      self.line_items.collect{|item| item  if item.product.shipping_category == Spree::ShippingCategory.minutes99 || item.product.shipping_category == Spree::ShippingCategory.same_day_shipping && !item.is_pick_at_store}.compact
    end

    def split?
      self.line_items.where("item_pickup_at is not null and is_pick_at_store is false").present?
    end

    def user_name
      "#{self.user.try(:firstname)} #{self.user.try(:lastname)}"
    end

    def find_line_item_by_variant_and_is_pick_at_store(variant, is_pick_at_store)
      line_items.detect { |line_item| line_item.variant_id == variant.id && line_item.is_pick_at_store == is_pick_at_store }
    end

    def sellers
      line_items.collect {|item| item.variant.product.seller}
    end

    def seller_line_items(seller)
      self.line_items.includes(:variant).where(:variant_id => Spree::Variant.includes(:products).where(:product_id => seller.products.map(&:id)))
    end

    def split_shipping?
      self.line_items.collect{|item| item  if item.product.shipping_category == Spree::ShippingCategory.minutes99 || item.product.shipping_category == Spree::ShippingCategory.same_day_shipping && !item.is_pick_at_store}.compact.present?
    end

    def oms_shipment_state
      if self.state == "complete" || self.state == "canceled"
        begin
          resp = RestClient.post(OMS_API_PATH, :order_no => self.number,:api_key => OMS_API_KEY, :content_type => :json, :accept => :json)
          resp = JSON.parse(resp)
          if resp["name"].capitalize == "no show".capitalize
             resp["name"] = "No Show"
          else
            @shipment_state = resp["name"]
          end
        rescue
          "completed"
        end
      else
        @shipment_state = self.shipment_state if self.shipment_state
      end
    end

    def order_state
      # raise current_api_user.inspct
      if Spree::User.current_user.has_spree_role?("seller")
        status = 0
        line_items = self.seller_line_items(Spree::User.current_user.seller)
        line_items.each do |line_item|
          if line_item.picked_up == false
            status = 1
          end
        end
        if status == 1
          return "pending"
        else
          return "completed"
        end
      else
        return "pending"
      end
    end

    def same_day?
      line_items.collect{|item| item  if item.product.shipping_category == Spree::ShippingCategory.same_day_shipping && !item.is_pick_at_store}.compact.present?
    end

    def is_99min?
      line_items.collect{|item| item  if item.product.shipping_category == Spree::ShippingCategory.minutes99 && !item.is_pick_at_store}.compact.present?
    end

    def possible_delivery_date
      delivery_date = []
      cross_time = Time.parse("#{Date.today} 9:59:59")
      until delivery_date.length == 3
        if Time.now < cross_time
          cross_time = cross_time
        else
          cross_time = cross_time + 1*86400
        end
        until is_holiday(cross_time) == false
          cross_time = cross_time + 1*86400 #possible cross date
        end
        order_date = Time.now
        if order_date < cross_time
          order_date = cross_time + 1*86400
        else
          order_date = cross_time + 2*86400
        end
        until is_holiday(order_date) == false
          order_date = order_date + 1*86400 #process date
        end
        delivery_date << with_format(order_date) #.strftime("%A, %d %B %Y")
        cross_time = cross_time + 1*86400
      end
      delivery_date
    end

    def possible_pickup_dates
      delivery_date = []
      cross_time = Time.parse("#{Date.today} 9:59:59")
      until delivery_date.length == 2
        if Time.now < cross_time
          cross_time = cross_time
        else
          cross_time = cross_time + 1*43200
        end
        until is_holiday(cross_time) == false
          cross_time = cross_time + 1*43200 #possible cross date
        end
        order_date = Time.now
        if order_date < cross_time
          order_date = cross_time #+ 1*43200
        else
          order_date = cross_time + 1*43200
        end
        until is_holiday(order_date) == false
          order_date = order_date + 1*43200 #process date
        end
        delivery_date << with_format(order_date)
        cross_time = cross_time + 1*43200
      end
      delivery_date
    end

    def is_holiday(date)
      seller_off = []
      self.sellers.each do |seller|
        seller_off.push seller.holiday_lists.map(&:to)
        seller_off.push seller.holiday_lists.map(&:from)
      end
      seller_off = seller_off.flatten
      seller_off.compact!
      seller_off = get_date_ranges(seller_off)
      if date.wday == 0 || seller_off.include?(date.to_date) #collect date object from this method
        return true
      else
        return false
      end
    end

    def get_date_ranges(seller_off)
      return [] if seller_off.blank?
      seller_off.sort!
      (seller_off.first..seller_off.last).map{ |date| date }
    end

    def with_format(date)
      date.strftime("%A, %d %B %Y")
#      if date.today?
#        "Today, #{date.strftime("%A, %d %B %Y")}"
#      elsif (date - 86400).today?
#        "Tomorrow, #{date.strftime("%A, %d %B %Y")}"
#      else
#        date.strftime("%A, %d %B %Y")
#      end
    end

    def deliver_order_confirmation_email
      begin
        OrderMailer.confirm_email(self.id).deliver
        self.products.collect(&:seller).uniq.each do |seller|
          line_items = self.line_items.collect{|li| li if li.product.seller == seller}.flatten.compact
          sorted_line_items = self.line_items.collect{|li| li if li.product.seller_id == seller.id && li.is_pick_at_store}.flatten.compact
          sorted_line = self.line_items.collect{|li| li if li.product.seller_id == seller.id && !li.is_pick_at_store}.flatten.compact
          if line_items.count == sorted_line_items.count
            OrderMailer.seller_order_pickup(self.id, line_items, seller).deliver
          elsif line_items.count == sorted_line.count
            OrderMailer.seller_order_delivery(self.id, line_items, seller).deliver
          else
            OrderMailer.seller_order_mix(self.id, line_items, seller).deliver
          end
          #APNS Notifications
          PushNotifications.seller_order(self, seller)
        end if self.products.collect(&:seller).present?
        # self.pickup_items.group(:stock_location_id).each do |item|
        #   # OrderMailer.pick_up_at_store(item, self).deliver
        # end if self.pickup_items.present?
      rescue Exception => e
        logger.error("#{e.class.name}: #{e.message}")
        logger.error(e.backtrace * "\n")
      end
    end

    def is_free_shipping?
      return [self.adjustments.eligible.collect(&:originator) & Spree::Calculator::FreeShipping.all.collect(&:calculable)].flatten.compact.present?
    end

    def merge!(order, user = nil)
      order.line_items.each do |line_item|
        next unless line_item.currency == currency
        current_line_item = self.line_items.find_by_variant_id(line_item.variant_id)
        if current_line_item
          current_line_item.quantity += line_item.quantity
          current_line_item.save
        else
          line_item.order_id = self.id
          line_item.save
        end
      end

      self.associate_user!(user) if !self.user && !user.blank?

      # So that the destroy doesn't take out line items which may have been re-assigned
      order.line_items.reload
      order.destroy
    end

    # To cancel the order in fulflmnt (FBA)
    def cancel_order_on_fba(smp, orders)
      @message = false
      if self.fulflmnt_state != 'cancel'
        fba_api_key = smp.fba_api_key
        authorization = Base64.encode64("#{USER}:#{PASSWORD}")
        cancel_order_path = OMS_PATH+"/cancel_order/#{self.cart_no}"
        if fba_api_key.present? && smp.fba_signature.present? && self.fulflmnt_tracking_no.present?
          begin
            contact_person_email = smp.seller.contact_person_email.present? ? smp.seller.contact_person_email : nil
            resp = RestClient.put(cancel_order_path, {:api_key => fba_api_key, :tracking_number => self.fulflmnt_tracking_no, :version => "2.0", :signature=>smp.fba_signature.strip, :email=>contact_person_email.strip}, {:Authorization => authorization})
            resp = JSON.parse(resp)
            orders.each do |order|
              order.update_attributes(:fulflmnt_state => "cancel")
            end
            if resp["response"] == "success"
              orders.each do |order|
                order.update_attributes(:cancel_on_fba => true)
                Spree::OmsLog.create!(:order_id => order.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["response"], :oms_api_message => resp["message"])
              end
            else # shoot mail whenever order is not cancelled on FBA
              # orders.update_all(:fulflmnt_state => "cancel")
              @message = resp["message"]
              Spree::OrderMailer.order_not_cancelled_notification(orders, resp["message"]).deliver
              Spree::OmsLog.create!(:order_id => self.id, :oms_reference_number => "", :oms_api_responce => resp["response"], :oms_api_message => resp["message"])
            end
          rescue Exception => e
            @message =  e.message
            Spree::OmsLog.create!(:order_id => self.id, :server_error_log => e.message)
          end
          @message = true
        else
          @message = "Ooops, API key or signature or FBA tracking number not found"
        end
      end
      return @message
    end

    # To cancel the order item in fulflmnt (FBA)
    def cancel_order_item_on_fba(smp, variant)
      @message = ""
      if self.fulflmnt_state != 'cancel'
        fba_api_key = smp.fba_api_key
        authorization = Base64.encode64("#{USER}:#{PASSWORD}")
        cancel_order_item_path = OMS_PATH+"/cancel_order_item/#{self.cart_no}"
        if fba_api_key.present? && smp.fba_signature.present? && self.fulflmnt_tracking_no.present?
          begin
            sku = (!self.is_bypass ? variant.sku : variant)
            contact_person_email = smp.seller.contact_person_email.present? ? smp.seller.contact_person_email : nil
            resp = RestClient.put(cancel_order_item_path, {:api_key => fba_api_key, :tracking_number => self.fulflmnt_tracking_no, :sku => sku, :version => "2.0", :signature=>smp.fba_signature.strip, :email=>contact_person_email.strip}, {:Authorization => authorization})
            resp = JSON.parse(resp)
            can_ord_number_count = Spree::Order.where("cart_no=? AND is_cancel=?", self.cart_no, true).count + 1
            mp_order_no = self.cart_no.to_s+"-"+sku.to_s+"-C"+can_ord_number_count.to_s
            can_order = Spree::Order.where("market_place_order_no=? AND seller_id=?", mp_order_no, smp.seller_id).try(:first)
            can_order = Spree::Order.where("market_place_order_no=? AND seller_id=?", self.market_place_order_no, smp.seller_id).try(:first) if !can_order.present?
            can_order.update_attributes(:fulflmnt_state => "cancel") if can_order.present?
            if resp["response"] == "success"
              can_order.update_attributes(:cancel_on_fba => true, :fulflmnt_tracking_no => resp["tracking_number"]) if can_order.present?
              Spree::OmsLog.create!(:order_id => self.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["response"], :oms_api_message => resp["message"])
            else # shoot mail whenever order is not cancelled on FBA
              @message = resp["message"]
              Spree::OrderMailer.order_item_not_cancelled_notification(self, resp["message"]).deliver
              Spree::OmsLog.create!(:order_id => self.id, :oms_reference_number => "", :oms_api_responce => resp["response"], :oms_api_message => resp["message"])
            end
          rescue Exception => e
            @message =  e.message
            Spree::OmsLog.create!(:order_id => self.id, :server_error_log => e.message)
          end
          @message = true if @message.empty?
        else
          @message = "Ooops, API key or signature or FBA tracking number not found"
        end
      end
      return @message
    end

    # Send invoice to FBA
    def send_invoice(smp, order, invoice_res)
      message = true
      begin
        fba_api_key = nil
        fba_api_key = smp.fba_api_key if smp.present?
        if fba_api_key.present? && invoice_res.present? && smp.fba_signature.present?
          authorization = Base64.encode64("#{USER}:#{PASSWORD}")
          send_invoice_path = FULFLMNT_PATH+"/updateinvoice"
          invoice_file = WickedPdf.new.pdf_from_string(Base64.decode64(invoice_res).to_s)
          save_path = WickedPdf.config[:wkhtmltopdf]+"/invoice_#{order.cart_no}.pdf"
          contact_person_email = smp.seller.contact_person_email.present? ? smp.seller.contact_person_email : nil
          File.open(save_path, 'wb') do |file|
            file << invoice_file
          end
          if File.exist?(save_path)
            resp_body = RestClient.post(send_invoice_path, {:api_key =>fba_api_key, :order_number=>order.cart_no, :tracking_number=>order.fulflmnt_tracking_no, :version =>"2.0", :signature=>smp.fba_signature.strip, :email=>contact_person_email.strip, :order_invoice=>File.open(save_path)}, {:Authorization => authorization})
            resp = JSON.parse(resp_body)
            if resp["response"] == "failure"
              message = false
              Spree::OmsLog.create!(:order_id => order.id, :server_error_log => resp["message"])
            else
              Spree::OmsLog.create!(:order_id => order.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["response"], :oms_api_message => resp["message"])
            end
            File.delete(save_path) rescue true
          else
            message = false
          end
        else
          message = false
        end
      rescue Exception => e
        message = false
        Spree::OmsLog.create!(:order_id => order.id, :server_error_log => e.message)
      end
      return message
    end

    # To push the order into fulflmnt (FBA) according to cart_no
    def self.push_to_fba(cart_nos)
      @message = ""
      cart_nos.each do |cn|
        @orders = []
        @orders = Spree::Order.includes([:line_items, :mp_order_line_items]).where("cart_no=? AND spree_orders.is_cancel=false AND (spree_line_items.id IS NOT NULL OR spree_mp_order_line_items.id IS NOT NULL) AND fulflmnt_tracking_no IS NULL", cn)
        seller_ids = @orders.map(&:seller_id).uniq
        seller_ids.each do |seller_id|
          s_orders = @orders.where(:seller_id=>seller_id)
          if s_orders.count == Spree::Order.where("cart_no=? AND seller_id=?", cn, seller_id).count
            begin
              smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", seller_id, @orders.first.market_place_id).try(:first)
              cm_user = !s_orders.try(:first).is_bypass rescue true
              fba_api_key = nil
              order_carrier_code = nil
              fba_api_key = smp.fba_api_key if smp.present?
              if fba_api_key.present? && smp.fba_signature.present?
                authorization = Base64.encode64("#{USER}:#{PASSWORD}")
                contact_person_email = smp.seller.contact_person_email.present? ? smp.seller.contact_person_email : nil
                order_carrier_code = smp.shipping_carrier_code.present? ? smp.shipping_carrier_code : nil
                if cm_user
                  resp_body = RestClient.post(OMS_PATH, {:api_key => fba_api_key.strip, :order_bucket => Spree::Order.get_order_bucket(s_orders, order_carrier_code), :version => "2.0", :signature=>smp.fba_signature.strip, :email=>contact_person_email.strip}, {:Authorization => authorization})
                else
                  order_bucket_hash , sku_undefined = Spree::Order.get_order_bypass_bucket(s_orders, order_carrier_code)
                  resp_body = RestClient.post(OMS_PATH, {:api_key => fba_api_key.strip, :order_bucket => order_bucket_hash, :version => "2.0", :signature=>smp.fba_signature.strip, :email=>contact_person_email.strip}, {:Authorization => authorization})
                end
                resp = JSON.parse(resp_body)
                # added the fulflmnt state & tracking number for order in switch fabric
                if (resp["response"] == "partial_success" || resp["response"] == "success") && !resp["split_orders"].present?
                  s_orders.each do |order|
                    order.update_attributes(:fulflmnt_state => resp["state"], :fulflmnt_tracking_no => resp["tracking_number"])
                    Spree::OmsLog.create!(:order_id => order.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["response"], :oms_api_message => resp["message"])
                  end # end of orders loop
                elsif (resp["response"] == "partial_success") && (resp["split_orders"].present?)
                  resp["split_orders"].each do |sp|
                    order_no = sp["order_number"]
                    tracking_number =  sp["tracking_number"]
                    state = sp["state"]
                    sp["items"].each do |item|
                      order = nil
                      order = Spree::Order.includes(:line_items=>"variant").where("cart_no=? AND spree_variants.sku=? AND seller_id=?", order_no, item["sku"], seller_id)
                      order.first.update_attributes(:fulflmnt_state => state, :fulflmnt_tracking_no =>tracking_number) if order.present?
                      Spree::OmsLog.create!(:order_id => order.first.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["response"], :oms_api_message => resp["message"])
                    end
                  end
                else
                  if (resp["response"] == "failure") && (resp["message"].include? "Order number has already been taken")
                    new_orders = Spree::Order.where(:cart_no => cn, :seller_id => seller_id)
                    new_orders.update_all(:fulflmnt_tracking_no=>resp["tracking_number"]) 
                    #Spree::OrderMailer::duplicate_order_on_fba(new_orders.try(:first), 'Duplicate order requst to FBA' ).deliver
                  end
                end # end of if
                if sku_undefined
                  new_order = Spree::Order.where(:cart_no => cn, :seller_id => seller_id).try(:first)
                  if  new_order.fulflmnt_tracking_no.present?
                    mail_id = Spree::Seller.find(seller_id).contact_person_email rescue current_user.try(:email)
                    Spree::OrderMailer::order_bypass_notification(new_order, mail_id, "Action Required | Incomplete Order #{new_order.number} Received on FBA" ).deliver
                  end
                end
              else
                @message = @message +";"+"Ooops, API key or signature not mapped"
              end
            rescue Exception => e
            @message =  e.message
            puts '-----------------------'
            puts @message
            puts '-----------------------'
            end
          end # if order count
        end # End loop seller ids
      end # Cart no loop
      return @message
    end

    # To get order status from FBA - no used currently
    def get_order_status(smp)
      fba_api_key = smp.fba_api_key
      authorization = Base64.encode64("#{USER}:#{PASSWORD}")
      order_status_path = OMS_PATH+"/order_status/#{self.cart_no}"
      @message = ""
      if fba_api_key.present? && smp.fba_signature.present?
        begin
          contact_person_email = smp.seller.contact_person_email.present? ? smp.seller.contact_person_email : nil
          resp = RestClient.post(order_status_path, {:api_key => fba_api_key, :tracking_number => self.fulflmnt_tracking_no, :version => "2.0", :signature=>smp.fba_signature.strip, :email=>contact_person_email.strip}, {:Authorization => authorization})
          resp = JSON.parse(resp)
          # update order status in SF according to FBA status
          if resp["response"] == "success"
            if (resp["state"] != self.fulflmnt_state) && (resp["state"] != nil)
               self.update_attributes(:fulflmnt_state => resp["state"])
               Spree::OmsLog.create!(:order_id => self.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["response"], :oms_api_message => resp["message"])
            end
          end
        rescue Exception => e
          @message =  e.message
          Spree::OmsLog.create!(:order_id => self.id, :server_error_log => e.message)
        end
        @message = "Order status updated successfully!" if @message.empty?
      else
        @message = "Ooops, API key or signature not mapped"
      end
      return @message
    end

    # formated order object for FBA
    def self.get_order_bucket(orders, carrier_code)
      first_order = orders.first
      order = nil
      index = 0
      total = 0.0
      item_total = 0.0
      payment_total = 0.0
      line_items_count = 0
      payment_method = ""
      order_bucket = {}
      is_customer_pickup = true
      orders.each do |ord|
        is_customer_pickup = false if (!ord.market_place_details.present? || (ord.market_place_details.present? && ord.market_place_details["OrderType"] == "Delivery") || (first_order.market_place.code == "lazada" || first_order.market_place.code == "zalora"))
        if !ord.fulflmnt_tracking_no.present?
          # to add line items into order
          ord.line_items.each do |item|
            order_bucket["item_#{index}"] = {"quantity"=>item.quantity, "id"=>item.id, "sku"=> item.variant.sku, "price"=> item.price, "weight"=>item.variant.weight,
              "height"=>item.variant.height, "width"=>item.variant.width, "depth"=>item.variant.depth, "is_master"=>item.variant.is_master,
              "product_id"=>item.variant.product.id, "product_name"=>item.variant.product.name, "description"=>"",
              "available_on"=>item.variant.product.available_on, "count_on_hand"=>item.variant.stock_products.collect(&:count_on_hand).sum, "image"=>(item.variant.images.blank? ? (item.variant.product.master.images.blank? ? "" : item.variant.product.master.images.first.attachment.url): item.variant.images.first.attachment.url)
            }
            order = ord if (!item.is_pick_at_store && !order.present?)
            index = index + 1
          end
          total +=  ord.total.present? ? ord.total.to_f : 0.0
          item_total += ord.item_total.present? ? ord.item_total.to_f : 0.0
          payment_total += ord.payment_total.present? ? ord.payment_total.to_f : 0.0
        end
      end
      order = first_order if !order.present?
      line_items_count = index
      if order.market_place_details.present? && order.market_place_details["PaymentMethod"]=="CashOnDelivery"
        payment_method = "COD"
      elsif order.market_place_details.present?
        payment_method = order.market_place_details["PaymentMethod"]
      end
      if (order.ship_address.phone.present? ? order.ship_address.phone.length : 0) >= (order.ship_address.alternative_phone.present? ? order.ship_address.alternative_phone.length : 0)
        phone_num =  order.ship_address.phone
        alt_phone_num = order.ship_address.alternative_phone
      else
        phone_num =  order.ship_address.alternative_phone
        alt_phone_num = order.ship_address.phone
      end
      tracking_no = ((order.market_place.code == "qoo10" && order.market_place_details.present?) ? order.market_place_details["PackingNo"] : nil)
      order_bucket = order_bucket.merge(
      "number"=> order.cart_no,
      "delivery_carrier_code"=>(is_customer_pickup ? "" : carrier_code),
      "is_customer_pickup"=> is_customer_pickup,
      "item_total"=> item_total,
      "total"=> total,
      "email"=> order.email,
      "number_of_items" => line_items_count,
      "delivery_date"=> order.delivery_date.present? ? order.delivery_date : nil,
      "delivery_time"=> order.delivery_time.present? ? order.delivery_time : nil,
      "currency" => order.currency,
      "tracking_number" => tracking_no,
      "shipping_address"=> {
        "firstname"=>order.ship_address.firstname,
        # "lastname"=>self.ship_address.lastname,
        "address1"=>order.ship_address.address1,
        "address2"=> order.ship_address.address2.present? ? order.ship_address.address2 : nil,
        "city"=>order.ship_address.city,
        "zipcode"=>order.ship_address.zipcode,
        "phone"=>phone_num,
        "state_name"=>order.ship_address.state_name.present? ? order.ship_address.state_name : "Singapore",
        "alternative_phone"=>alt_phone_num.present? ? alt_phone_num : nil,
        "country"=> order.ship_address.country.name
        },
        "billing_address"=> {
          "firstname"=> order.bill_address.present? ? order.bill_address.firstname : order.ship_address.firstname,
          # "lastname"=> order.bill_address.present? ? order.bill_address.lastname : order.ship_address.lastname,
          "address1"=> order.bill_address.present? ? order.bill_address.address1 : order.ship_address.address1,
          "address2"=> order.bill_address.present? ? order.bill_address.address2.present? ? order.bill_address.address2 : nil : order.ship_address.address2.present? ? order.ship_address.address2 : nil,
          "city"=> order.bill_address.present? ? order.bill_address.city : order.ship_address.city,
          "zipcode"=> order.bill_address.present? ? order.bill_address.zipcode : order.ship_address.zipcode,
          "phone"=> order.bill_address.present? ? order.bill_address.phone : order.ship_address.phone,
          "state_name"=> order.bill_address.present? ? order.bill_address.state_name.present? ? order.bill_address.state_name : "Singapore" : order.ship_address.state_name.present? ? order.ship_address.state_name : "Singapore",
          "alternative_phone"=> order.bill_address.present? ? order.bill_address.alternative_phone.present? ? order.bill_address.alternative_phone : nil : order.ship_address.alternative_phone.present? ? order.ship_address.alternative_phone : nil,
          "country"=> order.bill_address.present? ? order.bill_address.country.name : order.ship_address.country.name
        },
          "payment_total"=> payment_total,
          "shipping_method"=>order.shipping_method.present? ? order.shipping_method.try(:name) : "",
          "ip_address" => order.last_ip_address.present? ? order.last_ip_address : nil,
          "payment_method" => payment_method,
          "authorization_code" => order.payments.present? ? order.payments.completed.first.response_code : "",
          "send_as_gift" => order.try(:send_as_gift).present? ? order.try(:send_as_gift) : false,
          "greating_message" => order.try(:greating_message).present? ? order.try(:greating_message) : "Welcome, Order placed successfully!",
          "special_instruction" => order.try(:market_place_details).present? ? order.market_place_details["ShippingMsg"] : "",
          "originated_from" => order.market_place.name,
          "meta_keywords" => orders.map(&:market_place_order_no).join(",")
        )
        return order_bucket
    end

    # formated order object
    def self.get_order_bypass_bucket(orders, carrier_code)
      order = orders.first
      index = 0
      total = 0.0
      item_total = 0.0
      payment_total = 0.0
      line_items_count = 0
      payment_method = ""
      order_bucket = {}
      is_customer_pickup = true
      option_inst = "" 
      spacial_inst = ""
      sku_undefined = false
      orders.each do |ord|
        is_customer_pickup = false if (!ord.market_place_details.present? || (ord.market_place_details.present? && ord.market_place_details["OrderType"] == "Delivery") || (order.market_place.code == "lazada") || (order.market_place.code == "zalora"))
        if !ord.fulflmnt_tracking_no.present?
          # to add line items into order
          case ord.market_place.code
          when "lazada" , "zalora"
            #ord.order_bucket_lazada          
            ord.mp_order_line_items.each do |item|
              if item.market_place_details.present?
                order_bucket["item_#{index}"] = {"quantity"=>1, "id"=>item.id, "sku"=>item.market_place_details["Sku"], "price"=>item.market_place_details["ItemPrice"], "weight"=>nil,"height"=>nil, "width"=>nil, 
                  "depth"=>nil, "is_master"=>nil, "product_id"=>item.id, "product_name"=>item.market_place_details["Name"], "description"=>"", "available_on"=>nil, "count_on_hand"=>nil, "image"=>nil
                }
              else
                order_bucket["item_#{index}"] = {"quantity"=>1, "id"=>item.id, "sku"=>"undefined", "price"=>0.0, "weight"=>nil,"height"=>nil, "width"=>nil, "depth"=>nil, "is_master"=>nil, 
                  "product_id"=>item.id, "product_name"=>"undefined", "description"=>"", "available_on"=>nil, "count_on_hand"=>nil, "image"=>nil
                }
                sku_undefined = true
              end
              index = index + 1
            end              
          when "qoo10"  
            ord.mp_order_line_items.each do |item|
              if item.market_place_details.present?
                skus = []
                if item.market_place_details["option"].present?
                  op_code = item.market_place_details["optionCode"].split(",")
                  skus << (op_code.present? ? op_code : "undefined")
                else  
                  skus << (item.market_place_details["sellerItemCode"].present? ? item.market_place_details["sellerItemCode"] : "undefined")
                end
                skus = skus.flatten
                sku_undefined = true if skus.include? 'undefined'
                option_inst += option_inst.empty? ? (item.market_place_details["option"]+"-"+item.market_place_details["optionCode"]) : (" | "+(item.market_place_details["option"]+"-"+item.market_place_details["optionCode"]))  
                skus.each do |sku|
                  order_bucket["item_#{index}"] = {"quantity"=>item.market_place_details["orderQty"], "id"=>item.id, "sku"=>sku, "price"=>item.market_place_details["orderPrice"], 
                    "weight"=>nil, "height"=>nil, "width"=>nil, "depth"=>nil, "is_master"=>nil, "product_id"=>item.id, "product_name"=>item.market_place_details["itemTitle"], "description"=>"", "available_on"=>nil, 
                    "count_on_hand"=>nil, "image"=>nil
                  }
                  index = index + 1
                end
                spacial_inst += item.market_place_details["ShippingMsg"].present? ? (" | "+item.market_place_details["ShippingMsg"]) : ""
              else
                order_bucket["item_#{index}"] = {"quantity"=>1, "id"=>item.id, "sku"=>"undefined", "price"=>0.0, "weight"=>nil,"height"=>nil, "width"=>nil, "depth"=>nil, "is_master"=>nil, "product_id"=>item.id, 
                  "product_name"=>"undefined", "description"=>"", "available_on"=>nil, "count_on_hand"=>nil, "image"=>nil
                }
                sku_undefined = true
                index = index + 1
              end
            end              
          end    
          total +=  (ord.total.present? ? ord.total.to_f : 0.0)
          item_total += (ord.item_total.present? ? ord.item_total.to_f : 0.0)
          payment_total += (ord.payment_total.present? ? ord.payment_total.to_f : 0.0)
          option_inst += spacial_inst
        end
      end

      line_items_count = index
      if order.market_place_details.present? && order.market_place_details["PaymentMethod"]=="CashOnDelivery"
        payment_method = "COD"
      elsif order.market_place_details.present?
        payment_method = order.market_place_details["PaymentMethod"]
      end
      if (order.ship_address.phone.present? ? order.ship_address.phone.length : 0) >= (order.ship_address.alternative_phone.present? ? order.ship_address.alternative_phone.length : 0)
        phone_num =  order.ship_address.phone
        alt_phone_num = order.ship_address.alternative_phone
      else
        phone_num =  order.ship_address.alternative_phone
        alt_phone_num = order.ship_address.phone
      end
      tracking_no = ((order.market_place.code == "qoo10" && order.market_place_details.present?) ? order.market_place_details["PackingNo"] : nil)
      order_bucket = order_bucket.merge(
      "number"=> order.cart_no,
      "delivery_carrier_code"=>(is_customer_pickup ? "" : carrier_code),
      "is_customer_pickup"=> is_customer_pickup,
      "item_total"=> item_total,
      "total"=> total,
      "email"=> order.email,
      "number_of_items" => line_items_count,
      "delivery_date"=> (order.delivery_date.present? ? order.delivery_date : nil),
      "delivery_time"=> (order.delivery_time.present? ? order.delivery_time : nil),
      "currency" => order.currency,
      "tracking_number" => tracking_no,
      "shipping_address"=> {
        "firstname"=>order.ship_address.firstname,
        # "lastname"=>self.ship_address.lastname,
        "address1"=>order.ship_address.address1,
        "address2"=> (order.ship_address.address2.present? ? order.ship_address.address2 : nil),
        "city"=>order.ship_address.city,
        "zipcode"=>order.ship_address.zipcode,
        "phone"=>phone_num,
        "state_name"=>(order.ship_address.state_name.present? ? order.ship_address.state_name : "Singapore"),
        "alternative_phone"=>(alt_phone_num.present? ? alt_phone_num : nil),
        "country"=> order.ship_address.country.name
        },
        "billing_address"=> {
          "firstname"=> order.bill_address.present? ? order.bill_address.firstname : order.ship_address.firstname,
          # "lastname"=> order.bill_address.present? ? order.bill_address.lastname : order.ship_address.lastname,
          "address1"=> order.bill_address.present? ? order.bill_address.address1 : order.ship_address.address1,
          "address2"=> order.bill_address.present? ? order.bill_address.address2.present? ? order.bill_address.address2 : nil : order.ship_address.address2.present? ? order.ship_address.address2 : nil,
          "city"=> order.bill_address.present? ? order.bill_address.city : order.ship_address.city,
          "zipcode"=> order.bill_address.present? ? order.bill_address.zipcode : order.ship_address.zipcode,
          "phone"=> order.bill_address.present? ? order.bill_address.phone : order.ship_address.phone,
          "state_name"=> order.bill_address.present? ? order.bill_address.state_name.present? ? order.bill_address.state_name : "Singapore" : order.ship_address.state_name.present? ? order.ship_address.state_name : "Singapore",
          "alternative_phone"=> order.bill_address.present? ? order.bill_address.alternative_phone.present? ? order.bill_address.alternative_phone : nil : order.ship_address.alternative_phone.present? ? order.ship_address.alternative_phone : nil,
          "country"=> order.bill_address.present? ? order.bill_address.country.name : order.ship_address.country.name
        },
          "payment_total"=> payment_total,
          "shipping_method"=>order.shipping_method.present? ? order.shipping_method.try(:name) : "",
          "ip_address" => order.last_ip_address.present? ? order.last_ip_address : nil,
          "payment_method" => payment_method,
          "authorization_code" => order.payments.present? ? order.payments.completed.first.response_code : "",
          "send_as_gift" => order.try(:send_as_gift).present? ? order.try(:send_as_gift) : false,
          "greating_message" => order.try(:greating_message).present? ? order.try(:greating_message) : "Welcome, Order placed successfully!",
          "special_instruction" => option_inst,
          "originated_from" => order.market_place.name,
          "meta_keywords" => orders.map(&:market_place_order_no).join(",") 
        )
        return order_bucket,sku_undefined
    end

    # Update FBA order state to Complete
    def self.update_fba_state(cart_nos, smp, status)
      market_place = smp.market_place
      fba_api_key = smp.fba_api_key
      authorization = Base64.encode64("#{USER}:#{PASSWORD}")
      order_status_path = FULFLMNT_PATH+"/updateorderstatus"
      @message = ""
      @errors={}
      if fba_api_key.present? && smp.fba_signature.present?
        contact_person_email = smp.seller.contact_person_email.present? ? smp.seller.contact_person_email : nil
        cart_nos.each do |cn|
          order = nil
          begin
            @orders = nil
            @orders = Spree::Order.where("cart_no=? AND seller_id=? AND is_cancel=false", cn, smp.seller_id)
            case market_place.code
            when "qoo10"
              order = orders.first if orders.present? && (orders.count == orders.where(:market_place_order_status=>"Delivered").count)
            when "zalora"
              order = @orders.first if @orders.present? && (@orders.count == @orders.where(:market_place_order_status=>["shipped", "delivered", "Request Shipping"]).count)
            else
              order = @orders.first
            end      
            if order.present?
              resp = RestClient.post(order_status_path, {:api_key => fba_api_key, :version => "2.0",:order_number=>cn, :tracking_number=>order.fulflmnt_tracking_no, :status=>status, :signature=>smp.fba_signature.strip, :email=>contact_person_email.strip}, {:Authorization => authorization})
              resp = JSON.parse(resp)
              # update order status in SF according to FBA status
              if resp["response"] == "success"
                if (resp["state"] != nil) && (resp["state"] != self.fulflmnt_state)
                  @orders.update_all(:fulflmnt_state => resp["state"])
                  Spree::OmsLog.create!(:order_id => order.id, :oms_reference_number => resp["reference_id"], :oms_api_responce => resp["response"], :oms_api_message => resp["message"]) rescue ""
                end
              else
                @orders.update_all(:market_place_order_status=>"Request Shipping")
                @errors = @errors.merge(cn=>order.cart_no.to_s+": "+resp["message"].to_s)
              end
            end
          rescue Exception => e
            @message =  e.message
            Spree::OmsLog.create!(:order_id => order.id, :server_error_log => e.message) rescue ""
          end
        end # End cart loop
        #Spree::OrderMailer.order_state_not_changed_notification(@orders, @errors).deliver if @orders.present? && @errors.present?
        @message = "Order status updated successfully!" if @message.empty?
      else
        @message = "Ooops, API key or signature not mapped"
      end
      return @message
    end   
    
    # Fetch order status from zalora and lazada marketplace
    def self.shipped_or_delivered_order_fetch_lazada(smp)
      my_logger ||= Logger.new("#{Rails.root}/log/cron.log")
      @messages = []
      shipped_cart_numbers = []
      delivered_cart_numbers = []
      seller = smp.seller
      my_logger.info("fetch status for #{seller.name} from #{smo.market_place.code rescue ''}")
      fba_complete_states = ['complete', 'customer_complete', 'self_collect_complete', 'collect_complete', 'return_complete']
      @orders = seller.orders.where("market_place_id=? AND market_place_order_status IN(?) AND is_cancel=false", smp.market_place_id, ['ready_to_ship','ready to ship', 'Request Shipping', 'shipped'])
      if @orders.present?
        @orders.each do |order|
          begin
            # List item fetch from order API
            Time.zone = "Singapore"
            current_time = Time.zone.now
            list_item_params = {"Action"=>"GetOrderItems", "OrderId"=>order.market_place_order_no, "Timestamp"=>current_time.to_time.iso8601, "UserID"=>smp.contact_email, "Version"=>"1.0"}
            signature = ApiJob.generate_lazada_signature(list_item_params, smp)
            market_place = smp.market_place
            if signature.present?
              string_to_be_formed = []
              sorted_params = Hash[list_item_params.sort]
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
                order_items = res_body[:SuccessResponse][:Body][:OrderItems][:OrderItem]
                order_items = (order_items.class == Array ? order_items : [order_items]) 
                if order_items.present?
                  ord_item = order_items.first 
                  # Improve this condition for not repeting orders to FBA to update the status
                  #if ord_item[:Status] == "shipped" && order.fulflmnt_state != "delivery"
                   # order.update_column(:market_place_order_status, "shipped")
                    #shipped_cart_numbers << order.cart_no if !fba_complete_states.include?order.fulflmnt_state
                  if ord_item[:Status] == "delivered" && (!fba_complete_states.include?order.fulflmnt_state) 
                    order.update_column(:market_place_order_status, "delivered")
                    delivered_cart_numbers << order.cart_no
                  else
                    order.update_column(:market_place_order_status, ord_item[:Status])
                    details = "<b>Marketplace Name: </b>" + market_place.name.capitalize + "<br />" 
                    details += "<b>Seller Name: </b>" + seller.name.capitalize + "<br />"
                    details += "<b>Order Number: </b>" + order.market_place_order_no.to_s + "<br />"
                    details += "<b>FBA Order Number: </b>" + order.cart_no.to_s + "<br />"
                    details += "<b>Tracking Number: </b>" + order.fulflmnt_tracking_no.to_s + "<br />"
                    details += "<b>Marketplace state: </b>" + ord_item[:Status].to_s + "<br />"
                    details += "<b>FBA state: </b>" + order.fulflmnt_state.to_s + "<br />"
                    subject = "Channel Manger | Order status failed to update on FBA"
                    body = "Please take action on following order is not able to change order state <br /><br />" + details
                    # CustomMailer.custom_order_export("abhijeet.ghude@anchanto.com",subject,body).deliver
                  end  
                end # End for order items present 
              end
            else
              @messsges << "#{market_place.name}: Signature can not be generated."
            end
        rescue Exception => e
          #@messsges << e.message
        end
      end # end of loop
      #@messsges << Spree::Order.update_fba_state(shipped_cart_numbers.uniq, smp, "out_for_delivery") if shipped_cart_numbers.present?
      @messages << Spree::Order.update_fba_state(delivered_cart_numbers.uniq, smp, "Completed") if delivered_cart_numbers.present?
    end # end of if condition
    return @messages.join("; ")
  end
    
 end
end
