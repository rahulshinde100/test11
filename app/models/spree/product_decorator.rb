require 'base64'

Spree::Product.class_eval do
  attr_accessible :company, :website, :is_new_arrival, :is_featured, :url, :is_in_stock, :label_ids, :is_on_sale, :is_warehouse, :brand_id, :stock_config_type, :upc
  attr_accessible :warehouse_discount
  validates_presence_of :sku, :price
  validates_presence_of :special_price, :if => :is_warehouse

  #validate :special_price_is_less_than_or_equal_to_price
  validate :selling_price_is_less_than_or_equal_to_price
  validates_numericality_of :special_price, :less_than_or_equal_to => :selling_price, :allow_blank => true
  #validate :special_price_is_less_than_price
  #validate :retailer_price

  default_scope where("spree_products.seller_id in (?)", Spree::Seller.all.map(&:id)) if ActiveRecord::Base.connection.table_exists? 'spree_sellers' 

  scope :approve, where(:is_approved => true, :is_reject => false)
  scope :futured, where("available_on <= '#{Date.today} 00:00:00'")

  # default_scope order("RAND()")
  scope :in_99minute, lambda {where(:shipping_category_id => Spree::ShippingCategory.minutes99.try(:id))}
  scope :in_same_day, lambda{where(:shipping_category_id => Spree::ShippingCategory.same_day_shipping.try(:id))}

  # scope :not_listed_on_mp, where("spree_products.id not in (?)",Spree::SellersMarketPlacesProduct.all.map(&:product_id))
  # scope :not_listed_on_mp, -> (market_place) {where("spree_products.id not in (?)",Spree::SellersMarketPlacesProduct.where("market_place_id =? ", market_place).map(&:product_id))}
  validates_format_of :permalink, :with => /^[a-zA-Z0-9_]*[a-zA-Z0-9-]*$/,:message => "can only contain alphabets, numbers, and '_' & '-'."

  belongs_to :brand
  has_many :description_managements, :class_name => "Spree::DescriptionManagement", :dependent => :destroy
  has_many :title_managements, :class_name => "Spree::TitleManagement", :dependent => :destroy

  delegate_belongs_to :master, :upc

  validate :uniqueness_of_sku_on_create, :on => :create
  validate :uniqueness_of_sku_on_update, :on => :update

  #after_create :create_product_on_fba
  #after_update :update_product_on_fba

  def uniqueness_of_sku_on_create
    skus = Spree::Variant.all.map(&:sku)
    if skus.include?(self.sku)
      errors.add(sku, 'SKU already been used')
      false
    else
      true
    end
  end

  def uniqueness_of_sku_on_update
    skus = Spree::Variant.where(:sku=>self.sku)
    if skus.count > 1
      errors.add(sku, 'SKU already been used')
      false
    else
      true
    end
  end

  def self.active(currency = nil)
    not_deleted.available(nil, currency).approve.futured
  end
  def warehouse_discount
    if self.special_price.present?
      (100 - (self.special_price * 100 / self.price)).to_f.round(0)
    else
      0
    end
  end
  def save_images(image_data, index)
    @content = image_data

    @filename=  "#{Rails.root}/app/assets/images/temp/#{self.name}#{index}.jpg"
    File.open(@filename, 'wb') do|f|
      f.write(Base64.decode64(@content))
    end
    @filename
  end

  def add_image(image_name)
 		image = Spree::Image.create!({:attachment => open(image_name), :viewable => self.master}, :without_protection => true)
 		self.images << image
 		puts " ...added image: #{image_name.gsub(' ', '%20')}, for #{self.name}.  Image id: #{image.id}\n"
 		File.delete(image_name)
  end

  def is_in_stock
    self.in_stock?
  end

  #ware house pramotion (sale) page
      def is_on_sale
        if self.promotion_rules.map(&:promotion).collect{|pr| pr.name.downcase }.include?("warehouse sale".downcase)
          return true
        else
          return false
        end
      end

  def in_stock?
    #hISSUE IS HERE
    in_stock = true
    if self.variants.present?
      self.variants.each do |variant|
        if variant.in_stock?
          in_stock = true
          break
        else
          in_stock = false
        end
      end
    else
      in_stock = self.master.in_stock?
    end
    return in_stock
  end

  def out_of_stock_product_globally?
    out_of_stock = false
    variants = self.variants.present? ? self.variants : [self.master]
    variants.each do |variant|
      variant.stock_products.each do |product|
        if !product.virtual_out_of_stock
          out_of_stock = false
          break
        else
          out_of_stock = true
        end
      end
    end
    return out_of_stock
  end

  def out_of_stock_globally?
    out_of_stock = false
    variants = self.variants.present? ? self.variants : [self.master]
    variants.each do |variant|
      variant.stock_items.each do |item|
        if !item.virtual_out_of_stock
          out_of_stock = false
          break
        else
          out_of_stock = true
        end
      end
    end
    return out_of_stock
  end

  def stock_wise_variants
    variants = []
    variants_out_of_stcok = []
    variants_in_stcok = []
    if self.has_variants?
      self.variants.each do |variant|
        if variant.in_stock?
           variants_in_stcok << variant
        else
           variants_out_of_stcok << variant
        end
      end
    end
    variants = variants_in_stcok + variants_out_of_stcok
   end

  def sorted_images
    stock_wise_variants.collect{|var| var.images}.sum
  end

  def get_properties
    pr = []
    ap self.option_types
    self.option_types.each do |p|
      p.prototypes.each do |prototype|
        pr.push(prototype.properties)
      end
    end
    pr.flatten.uniq! if pr.flatten.present?
  end

  # list or products not listed on given market place - Added by Pooja Dudhatra
  def self.not_listed_on_mp(market_place_id)
    seller_ids = Spree::SellerMarketPlace.where(" market_place_id=?", market_place_id).map(&:seller_id)
    p_ids = Spree::SellersMarketPlacesProduct.where("market_place_id =? ", market_place_id).map(&:product_id)
    market_place = Spree::MarketPlace.find(market_place_id)
    if p_ids.present?
      return Spree::Product.where("is_approved is true and seller_id in (?) and spree_products.id not in (?)",seller_ids,p_ids)

    else
      return Spree::Product.where("is_approved is true and seller_id in (?) ",seller_ids)
    end
  end

  def self.need_to_updated_on_mp(market_place_id)
    Spree::Product.joins(:recent_market_place_changes).where("spree_recent_market_place_changes.deleted_at is null and spree_recent_market_place_changes.update_on_fba is false and spree_recent_market_place_changes.market_place_id =?",market_place_id).uniq
  end

  def delivery_time
    today = Time.now.strftime("%a")

    require 'time_difference'
    today = Time.now.strftime("%a")
    result = ""
    time = (Time.now.beginning_of_day + 10.hours) - Time.now.strftime("%H").to_i.hours - Time.now.strftime("%M").to_i.minutes
    time = time.strftime('%H').to_i > 0 ? (time.strftime('%M').to_i == 0 ? time.strftime('%H hrs') : time.strftime('%H hrs %M mins')) : time.strftime('%M mins')
    text1 = "Get it delivered by 11 pm today"

    time = TimeDifference.between((Time.now.beginning_of_day + 10.hours + 1.days), Time.now).in_hours
    min = ("0.#{time.to_s[3..5]}".to_f * 60).to_i
    time = time.to_i > 0 ? "#{time.to_i} hrs" + (min == 0 ? '' : " and #{min} mins") : "#{min} mins"
    text2 = "Get it delivered tomorrow"

    time = Time.now.beginning_of_day + 11.hours - 99.minutes
    time = time.strftime('%I:%M %P')
    text3 = "Get it delivered by 11 am today"

    time = Time.now + 99.minutes
    time = time.strftime('%I:%M %P')
    text4 = "Get it delivered by #{time} today"

    time = Time.now.beginning_of_day + 11.hours + 1.days - 99.minutes
    time = time.strftime('%I:%M %P')
    text5 = "11 am tomorrow"

    time = Time.now.beginning_of_day + 10.hours - Time.now.strftime("%H").to_i.hours - Time.now.strftime("%M").to_i.minutes
    time = time.strftime('%H').to_i > 0 ? (time.strftime('%M').to_i == 0 ? time.strftime('%H hrs') : time.strftime('%H hrs %M mins')) : time.strftime('%M mins')
    text6 = "Get it delivered by #{(Time.now + 3.days).strftime('%d %b')}"

    time = TimeDifference.between((Time.now.beginning_of_day + 10.hours + 1.days), Time.now).in_hours
    min = ("0.#{time.to_s[3..5]}".to_f * 60).to_i
    time = time.to_i > 0 ? "#{time.to_i} hrs" + (min == 0 ? '' : " and #{min} mins") : "#{min} mins"
    text7 = "Get it delivered by #{(Time.now + 3.days).strftime('%d %b')}"

    time = Time.now.beginning_of_day + 10.hours - Time.now.strftime("%H").to_i.hours - Time.now.strftime("%M").to_i.minutes
    time = time.strftime('%H').to_i > 0 ? (time.strftime('%M').to_i == 0 ? time.strftime('%H hrs') : time.strftime('%H hrs %M mins')) : time.strftime('%M mins')
    text8 = "Get it delivered by #{(Time.now + 4.days).strftime('%d %b')}"

    time = TimeDifference.between((Time.now.beginning_of_day + 10.hours + 1.days), Time.now).in_hours
    min = ("0.#{time.to_s[3..5]}".to_f * 60).to_i
    time = time.to_i > 0 ? "#{time.to_i} hrs" + (min == 0 ? '' : " and #{min} mins") : "#{min} mins"
    text9 = "Get it delivered by #{(Time.now + 4.days).strftime('%d %b')}"

    time = TimeDifference.between((Time.now.beginning_of_day + 10.hours + 2.days), Time.now).in_hours
    min = ("0.#{time.to_s[3..5]}".to_f * 60).to_i
    time = time.to_i > 0 ? "#{time.to_i} hrs" + (min == 0 ? '' : " and #{min} mins") : "#{min} mins"
    text10 = "Get it delivered day after tomorrow"

    time = Time.now.beginning_of_day + 11.hours - 99.minutes
    time = time.strftime('%I:%M %P')
    text11 = "Get it delivered day after tomorrow"

    case today
    when "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
      if self.shipping_category.present? && self.shipping_category.is_same_day_shipping?
        if Time.now > Time.now.beginning_of_day && Time.now < (Time.now.beginning_of_day + 10.hours)
          result = text1
        else
          result = text2
          result = text10 if today == "Sat"
        end
      elsif self.shipping_category.present? && self.shipping_category.is_99minute?
        if Time.now > Time.now.beginning_of_day && Time.now < (Time.now.beginning_of_day + 9.hours + 21.minutes)
          result = text3
        elsif Time.now > (Time.now.beginning_of_day + 9.hours + 21.minutes) && Time.now < (Time.now.beginning_of_day + 21.hours)
          result = text4
        else
          result = text5
          result = text11 if today == "Sat"
        end
      elsif self.shipping_category.present? && self.shipping_category.is_general?
        if Time.now > Time.now.beginning_of_day && Time.now < (Time.now.beginning_of_day + 10.hours)
          result = text6
          result = text8 if ["Wed", "Thu", "Fri", "Sat"].include? today
        else
          result = text7
          result = text9 if ["Wed", "Thu", "Fri", "Sat"].include? today
        end
      end
    when "Sun"
      if self.shipping_category.present? && self.shipping_category.present? && self.shipping_category.is_same_day_shipping?
        result = text2
      elsif self.shipping_category.present? && self.shipping_category.is_99minute?
        result = text5
      elsif self.shipping_category.present? && self.shipping_category.is_general?
        if Time.now > Time.now.beginning_of_day && Time.now < (Time.now.beginning_of_day + 10.hours)
          result = text8
        else
          result = text9
        end
      end
    end


    return result
  end

  def related_products
    self.relations.where(:relatable_id => self.id).collect(&:related_to).compact
  end

  # gives error message - product can not create on MP
  def get_validation_msg(market_place_id)
    product = self
    market_place = Spree::MarketPlace.find(market_place_id)
    market_place_code = market_place.code
    msg = []
    case market_place_code
      when "qoo10"
        if product.kit.present?
          if !(product.kit.products.present? rescue true)
            msg << 'Kit products are missing'
          end
        end
          if !product.taxons.present?
            msg << 'Category not added'
          end
          if !product.name.present?
            msg << 'Product Name is missing'
            # msg = msg.present? ? msg + ', Name is missing' : 'Name is missing'
          end
          if product.variant_images.nil? || product.variant_images.blank?
            msg << 'Product Image is missing'
            # msg = msg.present? ? msg + ', Product Image is missing' : 'Product Image is missing'
          end
          if !product.description_details('qoo10').present?
            # msg = msg.present? ? msg + ', Product Description is missing' : 'Product description is missing'
            msg << 'Product description is missing'
          end
          if !product.price.present?
            # msg = msg.present? ? msg + ', Retail Price is missing' : 'Retail Price is missing'
            msg <<  'Retail Price is missing'
          end
          if !product.selling_price.present?
            # msg = msg.present? ? msg + ', Selling Price is missing' : 'Selling Price is missing'
            msg << 'Selling Price is missing'
          else
            if product.selling_price <= 0
              msg << 'Selling Price must be greater than zero'
            end
          end

      when "lazada"
        if product.kit.present?
          if !(product.kit.products.present? rescue true)
            msg << 'Kit products are missing'
          end
        end
          if !product.sku.present?
            # msg = msg.present? ? msg + ', SKU is missing' : 'SKU is missing'
            msg << 'SKU is missing'
            # return false
          end
          if !product.name.present?
            # msg = msg.present? ? msg + ', Name' : 'Name'
            msg << 'Product Name is missing'
          end
          if !product.taxons.present?
            # msg = msg.present? ? msg + ', Category is missing' : 'Category is missing'
            msg << 'Category is missing'
          end
          if !product.description_details(market_place_code).present?
            # msg = msg.present? ? msg + ', Product Description is missing' : 'Product Description is missing'
            msg << 'Product Description is missing'
          end
          if !product.brand.present?
            # msg = msg.present? ? msg + ', Brand is missing' : 'Brand is missing'
            msg << 'Brand is missing'
          end
          if !product.price.present?
            # msg = msg.present? ? msg + ', Price is missing' : 'Price is missing'
            msg << 'Price is missing'
          end
        if product.variants.present?
          product.variants.each do |variant|
            if (!variant.weight.present? rescue true)
              msg << 'Weight is missing'
            end
            if (!variant.height.present? rescue true)
              msg << 'Height is missing'
            end
            if (!variant.width.present? rescue true)
              msg << 'Width is missing'
            end
            if (!variant.depth.present? rescue true)
              msg << 'depth is missing'
            end
          end
        else
          if (!product.weight.present? rescue true)
            msg << 'Weight is missing'
          end
          if (!product.height.present? rescue true)
            msg << 'Height is missing'
          end
          if (!product.width.present? rescue true)
            msg << 'Width is missing'
          end
          if (!product.depth.present? rescue true)
            msg << 'depth is missing'
          end
        end
      when 'zalora'
        if product.kit.present?
          if !(product.kit.products.present? rescue true)
            msg << 'Kit products are missing'
          end
        end
          if !product.sku.present?
            msg << 'SKU is missing'
          end
          if !product.name.present?
            msg << 'Product Name is missing'
          end
          if !product.taxons.present?
            msg << 'Category is missing'
          end
          if !product.description_details(market_place_code).present?
            msg << 'Product Description is missing'
          end
          if !product.brand.present?
            msg << 'Brand is missing'
          end
          if !product.price.present?
            msg << 'Price is missing'
          end
          if !product.gender.present?
            msg << 'Gender is missing'
          else
            if product.gender == 'NA'
              msg << 'Gender is not valid'
            end
          end
          if !product.option_types.present?
            #msg << 'Product Option type is missing'
          else
            mapped_type = Spree::OptionTypesMarketPlace.where(:market_place_id => market_place.id,:option_type_id => product.option_types.first.id).first rescue nil
            if !mapped_type.present?
              msg << 'Option type is not mapped'
            end
          end
          if !product.variants.present?
            #msg << 'Product variants missing'
          else
            product.variants.each do |variant|
              mapped_value = Spree::OptionValuesMarketPlace.where(:market_place_id => market_place.id,:option_value_id => variant.option_values.first.id).first rescue nil
              if !mapped_value.present?
                msg << 'Option Value not mapped'
                break
              end
            end
          end
    end
    # msg =  msg + 'missing' if msg.present?
    return msg.uniq
  end

  def get_updated_field_details(product,market_place_id)
    updated_fields = Spree::RecentMarketPlaceChange.where("product_id =? and market_place_id =? and update_on_fba = false",product,market_place_id).map(&:description).reject(&:empty?).join(',').gsub('-','').split(',').uniq
    updated_str = []
    updated_fields.each do |item|
      updated_str << UPDATEMESSAGE[item.squish.to_sym]
    end
    p updated_str
    return updated_str
  end
  private

  def special_price_is_less_than_price
    errors.add(:special_price, "should be less than price") if special_price.present? && special_price >= price
  end

  def special_price_is_less_than_or_equal_to_price
    errors.add(:special_price, "should be less than or equal to price") if special_price.present? && special_price.to_f > price.to_f
  end

  # added validation for selling price
  def selling_price_is_less_than_or_equal_to_price
    errors.add(:selling_price, "should be less than or equal to price") if selling_price.present? && selling_price.to_f > price.to_f
  end

  def retailer_price
    errors.add(:cost_price, "must enter") if cost_price.nil? && seller.type.try(:price_based?)
  end

end
