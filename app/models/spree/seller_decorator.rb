Spree::Seller.class_eval do
  include ApplicationHelper
  attr_accessible :business_name, :revenue_share, :revenue_share_on_ware_house_sale, :stock_config_type, :is_cm_user

  has_many :holiday_lists
  has_many :labels
  has_many :recent_market_place_changes
  has_many :orders

  after_create :create_stock_locations

  validates :business_name, uniqueness: true
  validates :name, uniqueness: true

  has_attached_file :logo, :styles => {
    :small => "50x100>",
    :medium => "100x200>",
    :large => "200x300>" },
    default_style: :small,
    url:  '/images/sellers/logo/:id/:style/:basename.:extension',
    path: '/images/sellers/logo/:id/:style/:basename.:extension',
    default_url: '/assets/ship.li/logo.png'

  has_attached_file :banner, :styles => {
    :small => "100x100>",
    :medium => "300x300>",
    :large => "500x500>" },
    default_style: :small,
    url:  '/images/sellers/banner/:id/:style/:basename.:extension',
    path: '/images/sellers/banner/:id/:style/:basename.:extension',
    :default_url => "/assets/ship.li/banner.png"


	default_scope :order => 'name ASC'

  # Load user defined paperclip settings
  if Spree::Config[:use_s3]
    s3_creds = { :access_key_id => Spree::Config[:s3_access_key], :secret_access_key => Spree::Config[:s3_secret], :bucket => Spree::Config[:s3_bucket]}
    Spree::Seller.attachment_definitions[:logo][:storage] = :s3
    Spree::Seller.attachment_definitions[:logo][:s3_credentials] = s3_creds
    Spree::Seller.attachment_definitions[:logo][:s3_headers] = ActiveSupport::JSON.decode(Spree::Config[:s3_headers])
    Spree::Seller.attachment_definitions[:logo][:bucket] = Spree::Config[:s3_bucket]
    Spree::Seller.attachment_definitions[:logo][:s3_protocol] = Spree::Config[:s3_protocol].downcase unless Spree::Config[:s3_protocol].blank?
    Spree::Seller.attachment_definitions[:logo][:s3_host_alias] = Spree::Config[:s3_host_alias]
    Spree::Seller.attachment_definitions[:logo][:url] = Spree::Config[:attachment_url]

    Spree::Seller.attachment_definitions[:banner][:storage] = :s3
    Spree::Seller.attachment_definitions[:banner][:s3_credentials] = s3_creds
    Spree::Seller.attachment_definitions[:banner][:s3_headers] = ActiveSupport::JSON.decode(Spree::Config[:s3_headers])
    Spree::Seller.attachment_definitions[:banner][:bucket] = Spree::Config[:s3_bucket]
    Spree::Seller.attachment_definitions[:banner][:s3_protocol] = Spree::Config[:s3_protocol].downcase unless Spree::Config[:s3_protocol].blank?
    Spree::Seller.attachment_definitions[:banner][:s3_host_alias] = Spree::Config[:s3_host_alias]
    Spree::Seller.attachment_definitions[:banner][:url] = Spree::Config[:attachment_url]

  end

  def active?
    return false if(!self.is_active || !self.deactivated_at.nil? || !self.deleted_at.nil?)
    return true
  end

  def is_completed?
    # Commented By Tejaswini Patil
    # As of now bank details and store loactions are not required for seller
    #if self.users.blank? || self.categories.blank? || self.bank_detail.blank? || self.stock_locations.blank?
    if self.users.blank?
    	return false
    else
    	return true
    end
  end

  #get sale percentage
  def self.get_percentage(a = nil, b = nil)
    a = (a.to_f || 0.0 rescue 0.0)
    b = (b.to_f || 0.0 rescue 0.0)
    return 0.0 if a == 0.0 && b == 0.0
    c = (((b-a) * 100 / (a)).to_f.round(2) rescue 0.0)
    (c.to_s == "Infinity" || c.to_s == "-Infinity") ? 100.0 : c
  end

  # get cost of orders goods sale
  def self.get_orders_cogs(orders)
    cogs = 0.0
    orders.each do |order|
      order.line_items.each do |lt|
        cogs += (lt.quantity*lt.variant.cost_price.to_f)
      end
    end
    return cogs
  end

  # get available stock for products
  def self.get_available_stock(products)
    units = 0
    cost_price = 0.0
    products.each do |product|
      variants = []
      variants << (product.variants.present? ? product.variants : product.master)
      variants = variants.flatten
      variants.each do |variant|
        units += variant.fba_quantity.to_i
        cost_price += (variant.cost_price.to_f*variant.fba_quantity.to_i)
      end
    end
    pro_stock_price={"units"=>units, "cost_price"=>cost_price}
    return pro_stock_price
  end

  # Added by Tejaswini to return the specified market place api key
  def return_market_place_api(name)
    self.seller_market_places.where(:market_place_id => Spree::MarketPlace.return_market_place(name).first.id).first.api_key rescue nil
  end

  def self.seller_users_roles
    Spree::Role.seller_roles.where("name != 'user'")
  end

  def in_process
    self.orders.complete.collect{|o| o if ['New','In Proccess','In packing queue','Packed','In Delivery Queue'].include? o.oms_shipment_state}.flatten.compact
  end

  def out_of_stock_products
    self.products.collect{|p| p if p.total_on_hand <= 0}.flatten.compact
  end

  def sold_products
    line_items =[]
    self.orders.complete.collect{|order| [order.line_items.map(&:id)]}.each do |items|
      line_items << items
    end if self.orders.complete.present?
    sale_items = Spree::LineItem.where(:id => line_items.flatten)
    sale_items.sum(&:quantity)
  end

  def sold_product
    self.orders.complete.collect(&:products).flatten.uniq
  end

  def total_sale
    line_items =[]
    self.orders.complete.collect{|order| [order.line_items.map(&:id)]}.each do |items|
      line_items << items
    end if self.orders.complete.present?
    sale_items = Spree::LineItem.where(:id => line_items.flatten)
    sale_items.collect{|item| [item.price * item.quantity]}.flatten.sum
  end

  def incomplete_message
    if self.users.blank?
      return @message = "Please create seller user for this seller"
    end
  end

  def create_stock_locations
    self.stock_locations.create!(:name => self.name, :address1 => self.address_1, :address2 => self.address_2, :city => self.city, :state_name => self.state, :state_id => nil, :country_id => 160, :zipcode => self.zip, :phone => self.phone, :active => true, :backorderable_default => true, :propagate_all_variants => true, :contact => self.phone, :email => self.contact_person_email, :seller_id => self.id, :contact_person_name => self.contact_person_name)
  end
  
  # Sales report for all seller
  def self.weekly_sales_report_for_cm_seller
    errors = []
    files = {}
    start_week=(Time.zone.now - 1.week).beginning_of_week
    end_week=(Time.zone.now - 1.week).end_of_week
    sellers = Spree::Seller.where("is_cm_user=true AND is_active=true")
    sellers.each do |seller|    
      puts seller.name
      begin
        res = seller.generate_weekly_sales_report(start_week, end_week)
        errors << seller.name+": "+res if res.present?
      rescue Exception => e
        errors << seller.name+": "+e.message.to_s   
      end
    end
    return errors.join(", ")
  end
  
  # Weely Sales report for single seller
  def generate_weekly_sales_report(start_week, end_week)
    file = {}
    report = []
    start_week = (!start_week.present? ? (Time.zone.now - 1.week).beginning_of_week : start_week.beginning_of_day)
    end_week= (!end_week.present? ? (Time.zone.now - 1.week).end_of_week : end_week.end_of_day)

    week_orders = self.orders.where(:is_cancel=>false).where(:order_date=>start_week..end_week)
    market_places = Spree::MarketPlace.all

    total_weekly_sales = 0.0
    total_weekly_volumes = week_orders.count
    blank_row = []
    
    # header1
    header1 = ["", "", "WEEKLY SALES UPDATE"] 
    header2 = [self.name.capitalize]
    
    market_places.each_with_index do |mp, ind|
      mp_total_orders_sales = 0.0
      mp_total_order_volume = 0
      mp_total_orders_sales_kit = 0.0
      mp_total_order_volume_kit = 0
      
      mp_orders = week_orders.where(:market_place_id=>mp.id)
      mp_total_orders_count = mp_orders.count
      #line_items = Spree::LineItem.where(:order_id=>mp_orders.map(&:id)).group(:variant_id, :rcp).select("*,sum(quantity) as number_of_item") 
      line_items = Spree::LineItem.where("order_id IN (?) AND kit_id IS NULL",mp_orders.map(&:id)).group(:variant_id, :rcp).select("*,sum(quantity) as number_of_item, sum(rcp) as price_of_item")

      header3 = [mp.name.capitalize]
      header4 = ["Orders", mp_total_orders_count]
      header5 = ["", "", "SINGLE SKUs"]
      header6 = ["DESCRIPTION", "SAP CODE", "CATEGORY", "RSP", "CUSTOMER PAID", "QTY SOLD", "VALUE SALES"]
      
      if line_items.present?
        report << [header3, []]
        report << [header4, []]
        report << [blank_row]
        report << [header5, []]
        report << [blank_row]
        report << [header6, []]
      else
        report << [header3, []]
      end

      line_items.each do |lt|
        rp = []
        variant = lt.variant
        product = variant.product
        price_details = variant.price_details(mp.code)
        mp_total_order_volume += (lt.number_of_item.present? ? lt.number_of_item.to_i : 0)
        mp_total_orders_sales += (lt.price_of_item.present? ? lt.price_of_item.to_f : 0.0) 
        rp << variant.name
        rp << variant.sku
        rp << product.taxons.try(:first).parent.parent.name rescue "-"
        rp << price_details["selling_price"].to_f
        rp << lt.rcp.to_f
        rp << lt.number_of_item
        rp << lt.price_of_item 
        report << [rp, []]
      end # End of line items
      
      footer1 = ["Total","","","","",mp_total_order_volume,"$#{mp_total_orders_sales}"] 
      report << [footer1, []] if line_items.present?
      
      total_weekly_sales += mp_total_orders_sales 
      
      # Header2
      
      #Bundle code
      line_items_kit = Spree::LineItem.includes(:kit).where("order_id IN (?) AND kit_id IS NOT NULL",mp_orders.map(&:id)).group(:kit_id, :rcp).select("*,sum(quantity) as number_of_item, sum(rcp) as price_of_item")
      #line_items_kit = Spree::LineItem.includes(:kit).where("kit_id IS NOT NULL").group(:kit_id, :rcp).select("*,sum(quantity) as number_of_item")
      if line_items_kit.present?
        header7 = ["", "", "BUNDLES"]
        header8 = ["", "BUNDLE CONTENTS", "", "RSP", "CUSTOMER PAID", "QTY SOLD", "VALUE SALES"]
        header9 = ["DESCRIPTION", "SAP CODE", "CATEGORY"]
        report << [header7, []]
        report << [header8, []]
        report << [header9, []]
      end  
      
      line_items_kit.each do |ltk|
        kit = ltk.kit
        kit_products = kit.kit_products
        mp_total_order_volume_kit += (ltk.number_of_item.present? ? (ltk.number_of_item.to_i/kit_products.count) : 0)
        mp_total_orders_sales_kit += (ltk.price_of_item.present? ? (ltk.price_of_item.to_f/kit_products.count) : 0.0) 
        kit_products.each_with_index do |kp, index|
          rpk = []
          k_variant = kp.variant
          k_product = k_variant.product
          price_details = k_variant.price_details(mp.code)
          rpk << k_variant.name
          rpk << k_variant.sku
          rpk << k_product.taxons.try(:first).parent.parent.name rescue "-"
          rpk << price_details["selling_price"].to_f
          if index == 0
            rpk << ltk.rcp.to_f
            rpk << (ltk.number_of_item/kit_products.count)
            rpk << (ltk.price_of_item/kit_products.count)
          end
          report << [rpk, []]
        end
      end # End of Kit line items
      
      footer2 = ["Total","","","","",mp_total_order_volume_kit,"$#{mp_total_orders_sales_kit}"]
      total_weekly_sales += mp_total_orders_sales_kit
      footer3 = [mp.name.capitalize+" Total", "", "", "", "", (mp_total_order_volume+mp_total_order_volume_kit), "$#{(mp_total_orders_sales+mp_total_orders_sales_kit)}"]      
      report << [footer2, []] if line_items_kit.present?
      report << [blank_row]
      report << [footer3, []]
      report << [blank_row]
      report << [blank_row]
    end # End of market place
    
    # Adding header and total sale report 
    total_sales_data1 = ["Date", start_week.strftime("%d-%b-%Y"), "To", end_week.strftime("%d-%b-%Y")]
    total_sales_data2 = ["Total Orders", total_weekly_volumes]
    total_sales_data3 = ["Total Sales", "$#{total_weekly_sales}"]
    
    report = [[blank_row]] + report
    report = [[blank_row]] + report
    report = [[total_sales_data3, []]] + report
    report = [[total_sales_data2, []]] + report
    report = [[total_sales_data1, []]] + report
    report = [[blank_row]] + report
    report = [[header2, []]] + report
    report = [[blank_row]] + report
    report = [[header1, []]] + report
    file.merge!((start_week.strftime("%d %b %Y")+" - "+end_week.strftime("%d %b %Y"))=>report)
=begin    
    # Email
    body = "Dear Team,<br />"
    body += "<p>Please find the attached report for "+self.name.to_s.capitalize+" company. Attached file is sales report between dates "+start_week.strftime("%d %b %Y")+" to "+end_week.strftime("%d %b %Y")+"</p><br />PFA...<br /><br />"
    subject = "Channel Manager | Report "+self.name.to_s.capitalize
    att_name = "Channel_Manager_Report_"+self.name.to_s.capitalize+start_week.strftime("%d %b %Y")+" to "+end_week.strftime("%d %b %Y")
    emails = ["abhijeet.ghude@anchanto.com"]
    CustomMailer.custom_order_export(emails, subject, body, CustomJob.generate_excel(report, header1), att_name).deliver if report
=end    
    return file
  end
  
end
