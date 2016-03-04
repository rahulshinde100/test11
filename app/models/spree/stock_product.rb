module Spree
  class StockProduct < ActiveRecord::Base
    include ApplicationHelper 
    attr_accessible :sellers_market_places_product_id, :variant_id, :count_on_hand, :virtual_out_of_stock

    belongs_to :sellers_market_places_product

    belongs_to :stock_location, class_name: 'Spree::StockLocation'
    belongs_to :variant, class_name: 'Spree::Variant'
    has_many :stock_movements

    default_scope {includes(:sellers_market_places_product).where("spree_sellers_market_places_products.is_active=?",true)}

    validates_presence_of :sellers_market_places_product_id, :variant_id
    
    after_update :update_stock_on_stock_change
    before_create :check_for_duplicate_entry
    
    #Check for existing entry for the stock
    def check_for_duplicate_entry
      stock_product = Spree::StockProduct.includes(:sellers_market_places_product).unscoped.where("sellers_market_places_product_id=? AND variant_id=?", self.sellers_market_places_product_id, self.variant_id)
      return false if stock_product.present?
    end
    
    # Update stock on maket place on stock update
    def update_stock_on_stock_change
      #if (STOCKCONFIG[self.variant.product.stock_config_type] == "flat_quantity") || (STOCKCONFIG[self.variant.product.stock_config_type] == "default" && STOCKCONFIG[self.variant.product.seller.stock_config_type] == "flat_quantity")
        stock_values = {}      
        variant = self.variant
        product = variant.product
        smps = product.seller.seller_market_places.where(:is_active=>true)
        mps = product.market_places.uniq
        type = STOCKCONFIG[product.stock_config_type] == "default" ? STOCKCONFIG[product.seller.stock_config_type] : STOCKCONFIG[product.stock_config_type]
        case type
          when "flat_quantity"
            stock_products = variant.stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id IN (?)", smps.map(&:market_place_id))
            stock_values.merge!(variant.id=>Spree::StockProduct.flat_quantity_setting(stock_products, variant, mps))
          when "fixed_quantity"
            #stock_products = variant.stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id IN (?) AND sellers_market_places_product_id = ?", smps.map(&:market_place_id), self.sellers_market_places_product_id)
            #stock_values.merge!(variant.id=>Spree::StockProduct.fixed_quantity_setting(stock_products, variant, mps))
          when "percentage_quantity"  
            stock_products = variant.stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id IN (?)", smps.map(&:market_place_id))
            stock_values.merge!(variant.id=>Spree::StockProduct.percentage_quantity_setting(stock_products, variant, mps))
        end
        # Stock update to marketplaces 
        update_stock_market_places(stock_values) if stock_values.present?
      #end
    end
    
    # Method to return flat quantity for stock products
    def self.flat_quantity_setting(stock_products, variant, mps)
      variant_sp_stock = {}
      sell_count = {}
      fba_quantity = variant.fba_quantity
      mps.each do |mp|
       sell_count.merge!(mp.id=>Spree::Order.includes("line_items").where("spree_line_items.variant_id=? AND market_place_id=?", variant.id, mp.id).count)  
      end
      sell_count = sell_count.sort{|x,y|y[1]<=>x[1]}
      sell_count = Hash[*sell_count.flatten]
      sell_count.each_with_index do |(key, value), ind|
        sp = stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id=?",key).first
        if sp.present?
          sp.update_column(:count_on_hand, fba_quantity)
          sps = sp.variant.stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id IN (?) AND sellers_market_places_product_id != ?", mps.map(&:id), sp.sellers_market_places_product_id)
          sps.each do |p|
            p.update_column(:count_on_hand, fba_quantity)
            variant_sp_stock.merge!(p.id=>fba_quantity)
          end
          variant_sp_stock.merge!(sp.id=>fba_quantity)
        end  
      end  
      return variant_sp_stock 
    end
    
    # Method to return percentage quantity for stock products
    def self.percentage_quantity_setting(stock_products, variant, mps)
      variant_sp_stock = {}
      sell_count = {}
      fba_quantity = variant.fba_quantity
      allocated_stock = 0
      mps.each do |mp|
       sell_count.merge!(mp.id=>Spree::Order.includes("line_items").where("spree_line_items.variant_id=? AND market_place_id=?", variant.id, mp.id).count)  
      end
      sell_count = sell_count.sort{|x,y|y[1]<=>x[1]}
      sell_count = Hash[*sell_count.flatten]
      sell_count.each_with_index do |(key, value), ind|
        sp = stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id=?",key).try(:first)
        if sp.present?
          type = STOCKCONFIG[variant.product.stock_config_type]
          if type == "default"
            stock_details = sp.sellers_market_places_product.stock_config_details
            stock_details = variant.product.seller.seller_market_places.where("market_place_id=?",key).first.stock_config_details if !stock_details.present?
          else
            stock_details = sp.sellers_market_places_product.stock_config_details
          end    
          quantity = ((stock_details/100.00)*fba_quantity).floor
          # if (stock_products.count > fba_quantity) && (ind < fba_quantity)
          #   sp.update_column(:count_on_hand,quantity.ceil)
          #   variant_sp_stock.merge!(sp.id=>quantity.ceil)
          # else
            sp.update_column(:count_on_hand,quantity)
            variant_sp_stock.merge!(sp.id=>quantity)
          allocated_stock = allocated_stock + quantity
          # end
        end  
      end
      extra_quantity = fba_quantity - allocated_stock
      sell_count.each_with_index do |(key, value), ind|

        sp = stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id=?",key).try(:first)
        if sp.present? && extra_quantity > 0
          sp.update_column(:count_on_hand,(variant_sp_stock[sp.id] + 1))
          variant_sp_stock[sp.id] = variant_sp_stock[sp.id] + 1
          extra_quantity = extra_quantity - 1
        end
        # variant_sp_stock
      end if extra_quantity > 0
      return variant_sp_stock 
    end
    
    # Method to return fixed quantities for stock products
    def self.fixed_quantity_setting(stock_products, variant, mps)
      variant_sp_stock = {}
      sell_count = {}
      v_sp_count = variant.stock_products.where("spree_stock_products.id NOT IN (?)",stock_products.map(&:id)).sum(:count_on_hand)
      sp_count = (stock_products.count == 0 ? 1 : stock_products.count)
      fba_quantity = (variant.fba_quantity-v_sp_count)
      fq_per = 100.00/sp_count
      quantity = ((fq_per/100)*fba_quantity).floor
      allocated_stock = quantity*mps.count
      extra_quantity = fba_quantity-allocated_stock
      mps.each do |mp|
       sell_count.merge!(mp.id=>Spree::Order.includes("line_items").where("spree_line_items.variant_id=? AND market_place_id=?", variant.id, mp.id).count)  
      end
      sell_count = sell_count.sort{|x,y|y[1]<=>x[1]}
      sell_count = Hash[*sell_count.flatten]
      sell_count.each_with_index do |(key, value), ind|
        sp = stock_products.includes("sellers_market_places_product").where("spree_sellers_market_places_products.market_place_id=?",key).first
        if sp.present?
          # if (stock_products.count.even? && ind < (stock_products.count/2)) || (!stock_products.count.even? && ind < (stock_products.count/2).floor) || (!stock_products.count.even? && ind == (stock_products.count/2).floor)
          if extra_quantity > 0
            sp.update_column(:count_on_hand,(quantity+1))
            variant_sp_stock.merge!(sp.id=>(quantity+1))
            extra_quantity = extra_quantity - 1
          else
            sp.update_column(:count_on_hand,quantity)
            variant_sp_stock.merge!(sp.id=>quantity)
          end
        end   
      end  
      return variant_sp_stock 
    end
    
  end
end
