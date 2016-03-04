module Spree
  class Product < ActiveRecord::Base

    acts_as_paranoid
    has_many :product_option_types, dependent: :destroy
    has_many :option_types, through: :product_option_types
    has_many :product_properties, dependent: :destroy
    has_many :properties, through: :product_properties

    has_many :classifications, dependent: :delete_all
    has_many :taxons, through: :classifications
    has_many :sellers_market_places_products, :dependent => :destroy
    has_many :market_places, :through => :sellers_market_places_products
    has_many :recent_market_place_changes, :class_name => "Spree::RecentMarketPlaceChange", :dependent => :destroy
    has_and_belongs_to_many :promotion_rules, join_table: :spree_products_promotion_rules

    belongs_to :tax_category, class_name: 'Spree::TaxCategory'
    belongs_to :shipping_category, class_name: 'Spree::ShippingCategory'
    belongs_to :kit, class_name: 'Spree::Kit'
    scope :sale_products, includes(:master, :variants).where("spree_variants.special_price != '' and spree_products.is_warehouse = 'false'")
    #scope :promo_products, Spree::Promotion::Rules::Product.where(:type => "Spree::Promotion::Rules::Product").collect(&:products).flatten

    #scope :discount_products, (Spree::Product.sale_products + Spree::Product.promo_products)
    #scope :discount_products, includes(:master, :variants).where("spree_products.id in (#{Spree::Product.promo_products.map(&:id).join(',')}) OR spree_variants.special_price != ''")

    has_one :master,
      class_name: 'Spree::Variant',
      conditions: { is_master: true },
      dependent: :destroy

    has_many :variants,
      class_name: 'Spree::Variant',
      conditions: { is_master: false, deleted_at: nil },
      order: "#{::Spree::Variant.quoted_table_name}.position ASC"
    has_many :quantity_inflations, through: :variants
    has_many :variants_including_master,
      class_name: 'Spree::Variant',
      dependent: :destroy,
      order: "#{::Spree::Variant.quoted_table_name}.position ASC"

    has_many :prices, through: :variants, order: 'spree_variants.position, spree_variants.id, currency'
    has_many :stock_items, through: :variants
    has_many :stock_products, through: :variants

    has_many :kit_products, :foreign_key => :product_id, :class_name => "Spree::KitProduct", :dependent => :destroy
    has_many :kits, :through => :kit_products

    delegate_belongs_to :master, :sku, :price, :currency, :display_amount, :display_price, :weight, :height, :width, :depth, :is_master, :has_default_price?, :cost_currency, :price_in, :amount_in, :rcp
    delegate_belongs_to :master, :cost_price, :special_price, :selling_price if Variant.table_exists? && (Variant.column_names.include?('cost_price') || Variant.column_names.include?('special_price') || Variant.column_names.include?('selling_price'))

    after_create :set_master_variant_defaults
    after_create :add_properties_and_option_types_from_prototype
    after_create :build_variants_from_option_values_hash, if: :option_values_hash
    after_save :save_master
    after_update :check_for_update

    # before_create :make_it_live
    # before_update :make_it_live

    delegate :images, to: :master, prefix: true
    alias_method :images, :master_images

    has_many :variant_images, source: :images, through: :variants_including_master, order: :position

    accepts_nested_attributes_for :variants, allow_destroy: true

    validates :name, presence: true
    validates :seller, presence: true
    validates :description, presence: true, :on=> :update
    validates :meta_description, presence: true, :on=> :update
    validates :package_content, presence: true, :on=> :update
    # validates_presence_of :taxon_ids, :on=>:update
    validates :permalink, presence: true
    validates :price, presence: true, if: proc { Spree::Config[:require_master_price] }
    #validates :shipping_category_id, presence: true

    attr_accessor :option_values_hash

    attr_accessible :available_on,
                    :cost_currency,
                    :deleted_at,
                    :depth,
                    :description,
                    :height,
                    :meta_description,
                    :meta_keywords,
                    :name,
                    :option_type_ids,
                    :option_values_hash,
                    :permalink,
                    :price,
                    :product_properties_attributes,
                    :prototype_id,
                    :shipping_category_id,
                    :sku,
                    :tax_category_id,
                    :taxon_ids,
                    :weight,
                    :width,
                    :variants_attributes,
                    :is_adult,
                    :total_in_hand_stock,
                    :kit_id,
                    :package_content,
                    :short_name,
                    :gender

    attr_accessible :cost_price, :special_price, :selling_price if Variant.table_exists? && (Variant.column_names.include?('cost_price') || Variant.column_names.include?('special_price') || Variant.column_names.include?('selling_price'))
    attr_accessible :rcp
    accepts_nested_attributes_for :product_properties, allow_destroy: true, reject_if: lambda { |pp| pp[:property_name].blank? }

    make_permalink order: :name

    alias :options :product_option_types

    after_initialize :ensure_master

    def variants_with_only_master
      ActiveSupport::Deprecation.warn("[SPREE] Spree::Product#variants_with_only_master will be deprecated in Spree 1.3. Please use Spree::Product#master instead.")
      master
    end

    def to_param
      permalink.present? ? permalink : (permalink_was || name.to_s.to_url)
    end
    
    # Check product's or its variant's quantity inflated
    def is_quantity_inflated
      qty_inf = Spree::QuantityInflation.includes(:variant).where("spree_variants.product_id=?", self.id)
      return qty_inf.present?
    end

    # the master variant is not a member of the variants array
    def has_variants?
      variants.present?
    end

    # Description details get by market place code
    def description_details(code)
      description = {}
      mp = Spree::MarketPlace.find_by_code(code)
      if mp.present?
        dm = Spree::DescriptionManagement.where("product_id=? AND market_place_id=?", self.id, mp.id)
        description.merge!("description"=>(dm.present? ? dm.first.description : self.description))
        description.merge!("meta_description"=>(dm.present? ? dm.first.meta_description : self.meta_description))
        description.merge!("package_content"=>(dm.present? ? dm.first.package_content : self.package_content))
      end
      return description
    end

    # Title details get by market place code
    def title_details(code)
      titles = {}
      mp = Spree::MarketPlace.find_by_code(code)
      if mp.present?
        tm = Spree::TitleManagement.where("product_id=? AND market_place_id=?", self.id, mp.id)
        titles.merge!("title"=>(tm.present? ? tm.first.name : self.name))
      end
      return titles
    end

    # def self.sale_products
    #   products = Spree::Product.active.includes(:master, :variants).where("spree_variants.special_price != ''")
    #   products << Spree::Promotion::Rules::Product.where(:type => "Spree::Promotion::Rules::Product").collect(&:products).flatten
    #   products.flatten
    # end

    def self.sale_products_by_category(cat_permalink)
      taxon= Spree::Taxon.find_by_permalink(cat_permalink)
      products = Spree::Product.sale_products.includes(:taxons).where("spree_taxons.id = #{taxon.id}")
      # products << Spree::Product.promo_products.includes(:taxons).where("spree_taxons.id = #{taxon.id}")
    end

    def self.sale_products_by_sellers(seller_permalink)
      seller = Spree::Seller.find_by_permalink(seller_permalink)
      products = Spree::Product.sale_products.where(:seller_id => seller.id)
      # products << Spree::Product.promo_products.where(:seller_id => seller.id)
    end

    def tax_category
      if self[:tax_category_id].nil?
        TaxCategory.where(is_default: true).first
      else
        TaxCategory.find(self[:tax_category_id])
      end
    end

    # Adding properties and option types on creation based on a chosen prototype
    attr_reader :prototype_id
    def prototype_id=(value)
      @prototype_id = value.to_i
    end

    # Ensures option_types and product_option_types exist for keys in option_values_hash
    def ensure_option_types_exist_for_values_hash
      return if option_values_hash.nil?
      option_values_hash.keys.map(&:to_i).each do |id|
        self.option_type_ids << id unless option_type_ids.include?(id)
        product_option_types.create({option_type_id: id}, without_protection: true) unless product_option_types.pluck(:option_type_id).include?(id)
      end
    end

    # for adding products which are closely related to existing ones
    # define "duplicate_extra" for site-specific actions, eg for additional fields
    def duplicate
      duplicator = ProductDuplicator.new(self)
      duplicator.duplicate
    end

    # use deleted? rather than checking the attribute directly. this
    # allows extensions to override deleted? if they want to provide
    # their own definition.
    def deleted?
      !!deleted_at
    end

    def available?
      !(available_on.nil? || available_on.future?)
    end

    # split variants list into hash which shows mapping of opt value onto matching variants
    # eg categorise_variants_from_option(color) => {"red" -> [...], "blue" -> [...]}
    def categorise_variants_from_option(opt_type)
      return {} unless option_types.include?(opt_type)
      variants.active.group_by { |v| v.option_values.detect { |o| o.option_type == opt_type} }
    end

    def self.like_any(fields, values)
      where_str = fields.map { |field| Array.new(values.size, "#{self.quoted_table_name}.#{field} #{LIKE} ?").join(' OR ') }.join(' OR ')
      self.where([where_str, values.map { |value| "%#{value}%" } * fields.size].flatten)
    end

    # Suitable for displaying only variants that has at least one option value.
    # There may be scenarios where an option type is removed and along with it
    # all option values. At that point all variants associated with only those
    # values should not be displayed to frontend users. Otherwise it breaks the
    # idea of having variants
    def variants_and_option_values(current_currency = nil)
      variants.includes(:option_values).active(current_currency).select do |variant|
        variant.option_values.any?
      end
    end

    def empty_option_values?
      options.empty? || options.any? do |opt|
        opt.option_type.option_values.empty?
      end
    end

    def property(property_name)
      return nil unless prop = properties.find_by_name(property_name)
      product_properties.find_by_property_id(prop.id).try(:value)
    end

    def set_property(property_name, property_value)
      ActiveRecord::Base.transaction do
        property = Property.where(name: property_name).first_or_create!(presentation: property_name)
        product_property = ProductProperty.where(product_id: id, property_id: property.id).first_or_initialize
        product_property.value = property_value
        product_property.save!
      end
    end

    def possible_promotions
      promotion_ids = promotion_rules.map(&:activator_id).uniq
      Spree::Promotion.advertised.where(id: promotion_ids).reject(&:expired?)
    end

    def total_on_hand
      if Spree::Config.track_inventory_levels
        self.stock_items.sum(&:count_on_hand)
      else
        Float::INFINITY
      end
    end

    def total_in_hand_stock
        self.stock_products.sum(&:count_on_hand)
    end

    def total_stock_in_kits
      self.kit_products.sum(&:quantity)
    end

    # Master variant may be deleted (i.e. when the product is deleted)
    # which would make AR's default finder return nil.
    # This is a stopgap for that little problem.
    def master
      super || variants_including_master.with_deleted.where(:is_master => true).first
    end

    private

      # Builds variants from a hash of option types & values
      def build_variants_from_option_values_hash
        ensure_option_types_exist_for_values_hash
        values = option_values_hash.values
        values = values.inject(values.shift) { |memo, value| memo.product(value).map(&:flatten) }

        values.each do |ids|
          variant = variants.create({ option_value_ids: ids, price: master.price, special_price: master.special_price }, without_protection: true)
        end
        save
      end

      def add_properties_and_option_types_from_prototype
        if prototype_id && prototype = Spree::Prototype.find_by_id(prototype_id)
          prototype.properties.each do |property|
            product_properties.create({property: property}, without_protection: true)
          end
          self.option_types = prototype.option_types
        end
      end

      # ensures the master variant is flagged as such
      def set_master_variant_defaults
        master.is_master = true
      end

      # there's a weird quirk with the delegate stuff that does not automatically save the delegate object
      # when saving so we force a save using a hook.
      def save_master
        master.save if master && (master.changed? || master.new_record? || (master.default_price && (master.default_price.changed || master.default_price.new_record)))
      end

      def ensure_master
        return unless new_record?
        self.master ||= Variant.new
      end

      #for time being, must be deleted after demo
      def make_it_live
        self.is_approved = true
      end

      # which fields have been changed - used fba - Added by Pooja Dudhatra
      def check_for_update
        changed_fields =  self.changed - ['updated_at','available_on','stock_config_type','is_approved']
        variants = (self.variants.present? ? (self.variants) : (self.master))
        market_places = self.market_places

        # update_hash.each do |k,v|
        #   desc = desc + k.to_s if c.include? v
        # end
        market_place_changes = self.changed - ['description','meta_description','package_content','name']
        if self.variants.present? && changed_fields.present?
          variants.each do |v|
            market_places.each do |market_place|
              @market_place_product = Spree::SellersMarketPlacesProduct.where(:product_id => self.id,:seller_id => self.seller_id, :market_place_id => market_place.id)
              if @market_place_product.present?
                desc = ProductJob.get_updated_fields(market_place_changes,market_place.code) if (changed_fields.present? && !changed_fields.blank?)
                v.recent_market_place_changes.create(:product_id => self.id,:seller_id => self.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
              end
            end
            if v.is_created_on_fba
              changed_fields = changed_fields &  ['width','height','depth','weight','cost_price','name','upc','sku']
              v.recent_market_place_changes.create(:product_id => self.id,:seller_id => self.seller.id, :description => changed_fields.join(','), :update_on_fba=>true) if (changed_fields.present? && !changed_fields.blank?)
              v.update_attributes(:updated_on_fba => false) if (changed_fields.present? && !changed_fields.blank?)
            end
          end
        else
          market_places.each do |market_place|
            @market_place_product = Spree::SellersMarketPlacesProduct.where(:product_id => self.id,:seller_id => self.seller_id, :market_place_id => market_place.id)
            if @market_place_product.present?
              desc = ProductJob.get_updated_fields(market_place_changes,market_place.code) if (changed_fields.present? && !changed_fields.blank?)
              variants.recent_market_place_changes.create(:product_id => self.id,:seller_id => self.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
            end
          end
          if (variants.is_created_on_fba rescue false) #&& !changed_fields.blank?
            changed_fields = changed_fields &  ['width','height','depth','weight','cost_price','name','upc','sku']
            variants.recent_market_place_changes.create(:product_id => self.id,:seller_id => self.seller.id, :description => changed_fields.join(','), :update_on_fba=>true) if (changed_fields.present? && !changed_fields.blank?)
            variants.update_attributes(:updated_on_fba => false) if (changed_fields.present? && !changed_fields.blank?)
          end
        end
      end
  end

end
require_dependency 'spree/product/scopes'
