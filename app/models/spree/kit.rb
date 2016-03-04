module Spree
  class Kit < ActiveRecord::Base
  include ApplicationHelper
  attr_accessible :name, :sku, :description, :is_active, :is_common_stock, :quantity, :seller_id

  has_many :kit_products, :foreign_key => :kit_id, :class_name => "Spree::KitProduct", :dependent => :destroy
  has_many :products, :through => :kit_products
  has_many :sellers_market_places_kits, :dependent => :destroy
  has_many :market_places, :through => :sellers_market_places_kits
  belongs_to :seller, :foreign_key => :seller_id, :class_name => "Spree::Seller"
  has_one :product, class_name: 'Spree::Product'
  has_many :line_items
  
  validates_presence_of :name, :sku, :seller_id  
  validates :sku, uniqueness: true
  
  after_save :update_product_stock
  
  validate :uniqueness_of_product_sku_on_create, :on => :create
  validate :uniqueness_of_product_sku_on_update, :on => :update
  
  # Check uniqueness of product sku on create kit
  def uniqueness_of_product_sku_on_create
    skus = Spree::Variant.all.map(&:sku)
    if skus.include?(self.sku)
      errors.add(sku, 'SKU already been used')
      false
    else
      true
    end    
  end

  # Check uniqueness of product sku on update kit
  def uniqueness_of_product_sku_on_update
    skus = Spree::Variant.where(:sku=>self.sku)
    if skus.count > 1
      errors.add(sku, 'SKU already been used')
      false
    else
      true
    end    
  end
  
  # Update product stock on kit update
  def update_product_stock
    stok_values = {}
    if self.product.present?
      product = self.product
      variants = []
      variants << product.master
      self.kit_products.each do |kp|
        variants << kp.variant
      end
      variants.each do |variant|
        v_product = variant.product
        type = (STOCKCONFIG[v_product.stock_config_type] == "default" ? STOCKCONFIG[v_product.seller.stock_config_type] : STOCKCONFIG[v_product.stock_config_type])
        stock_products = variant.stock_products.where("sellers_market_places_product_id IN (?)",v_product.sellers_market_places_products.map(&:id))
        mps = Spree::MarketPlace.where("id IN (?)", v_product.sellers_market_places_products.map(&:market_place_id)) 
        if stock_products.present?
          case type
          when "fixed_quantity"
            #stok_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps))
          when "percentage_quantity"
            #stok_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps))
            stok_values.merge!(variant.id=>Spree::StockProduct.percentage_quantity_setting(stock_products, variant, mps))
          when "flat_quantity"      
            stok_values.merge!(variant.id=>Spree::StockProduct.flat_quantity_setting(stock_products, variant, mps))   
          end # end of case
        end
      end
      # Stock Allocate to MP  
      update_stock_market_places(stok_values)
    end  
  end
  
  end
end
