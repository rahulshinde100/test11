module Spree
  class QuantityInflation < ActiveRecord::Base
    attr_accessible :variant_id, :market_place_id, :sku, :change_type, :next_type, :quantity, :previous_quantity, :end_date
    belongs_to :variant
    belongs_to :market_place
    
    validates :variant_id, presence: true
    validates :market_place_id, presence: true
    validates :sku, presence: true
    validates :change_type, presence: true
    validates :next_type, presence: true
    validates :quantity, presence: true
    validates :end_date, presence: true 
    
    # Stock inflation resent to zero on marketplaces
    def self.reset_quantity_to_zero(market_place, variants, seller_id)
      error = nil
      lazada_stock_hash = {}
      zalora_stock_hash = {}
      seller_market_place = Spree::SellerMarketPlace.where(:market_place_id=>market_place.id, :seller_id=>seller_id).try(:first)
      case market_place.code 
      when "lazada"
        variants.each do |variant|
          begin 
            product = variant.product
            stock_product = variant.stock_products.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.market_place_id=?", market_place.id).try(:first)
            stock_product.update_column(:count_on_hand, 0) if stock_product.present?
            if lazada_stock_hash[seller_market_place.id.to_s].present?
              lazada_stock_hash[seller_market_place.id.to_s].first.merge!(variant.sku.to_s=>0)
            else
              lazada_stock_hash.merge!(seller_market_place.id.to_s=>[{variant.sku.to_s=>0}])
            end
          rescue Exception => e  
          end  
        end
        # Update stock for lazada in bulk
        Spree::StockMovement.stock_update_lazada_bulk(lazada_stock_hash) if lazada_stock_hash.present?
      when "zalora"
        variants.each do |variant|
          begin 
            product = variant.product
            stock_product = variant.stock_products.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.market_place_id=?", market_place.id).try(:first)
            stock_product.update_column(:count_on_hand, 0) if stock_product.present?
            if zalora_stock_hash[seller_market_place.id.to_s].present?
              zalora_stock_hash[seller_market_place.id.to_s].first.merge!(variant.sku.to_s=>0)
            else
              zalora_stock_hash.merge!(seller_market_place.id.to_s=>[{variant.sku.to_s=>0}])
            end
          rescue Exception => e  
          end  
        end
        # Update stock for lazada in bulk
        Spree::StockMovement.stock_update_lazada_bulk(zalora_stock_hash) if zalora_stock_hash.present?
      when "qoo10"   
        variants.each do |variant|
          begin
            product = variant.product
            market_place_product = Spree::SellersMarketPlacesProduct.where(:seller_id => product.seller_id, :product_id => product.id, :market_place_id => market_place.id).try(:first)
            stock_product = variant.stock_products.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.market_place_id=?", market_place.id).try(:first)
            stock_product.update_column(:count_on_hand, 0)
            Spree::StockMovement.stock_update_qoo10(product, market_place.id, 0, stock_product, seller_market_place, market_place_product, 0)
          rescue Exception => e  
          end  
        end
      end
      return error
    end    
    
    # Stock inflation sync with fba on marketplaces 
    def self.sync_quantity_with_fba(market_place, variants, seller_id)
      error = nil
      seller_market_place = Spree::SellerMarketPlace.where(:market_place_id=>market_place.id, :seller_id=>seller_id).try(:first)
        variants.each do |variant|
          begin
            product = variant.product
            stock_product = variant.stock_products.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.market_place_id=?", market_place.id).try(:first)
            Spree::Variant.fetch_qty_from_fba(seller_market_place, variant)
          rescue Exception => e  
          end  
        end
      return error
    end
    
    # Stock inflation for promotion on marketplaces
    def self.inflate_quantity_on_mp(market_place, var_stock_hash, seller_id)
      error = nil
      lazada_stock_hash = {}
      zalora_stock_hash = {}
      seller_market_place = Spree::SellerMarketPlace.where(:market_place_id=>market_place.id, :seller_id=>seller_id).try(:first)
      case market_place.code 
      when "lazada"
        var_stock_hash.each do |id, stock|
          begin
            variant = Spree::Variant.includes(:quantity_inflations).find(id) 
            product = variant.product
            stock_product = variant.stock_products.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.market_place_id=?", market_place.id).try(:first)
            quantity_inflation = variant.quantity_inflations.where(:market_place_id=>market_place.id).try(:first)
            quantity_inflation.update_column(:previous_quantity, variant.fba_quantity)
            stock_product.update_column(:count_on_hand, stock)
            stock_product.reload
            if lazada_stock_hash[seller_market_place.id.to_s].present?
              lazada_stock_hash[seller_market_place.id.to_s].first.merge!(variant.sku.to_s=>stock)
            else
              lazada_stock_hash.merge!(seller_market_place.id.to_s=>[{variant.sku.to_s=>stock}])
            end
          rescue Exception => e  
          end  
        end
        # Update stock for lazada in bulk
        Spree::StockMovement.stock_update_lazada_bulk(lazada_stock_hash) if lazada_stock_hash.present?
      when "zalora"
        var_stock_hash.each do |id, stock|
          begin
            variant = Spree::Variant.includes(:quantity_inflations).find(id) 
            product = variant.product
            stock_product = variant.stock_products.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.market_place_id=?", market_place.id).try(:first)
            quantity_inflation = variant.quantity_inflations.where(:market_place_id=>market_place.id).try(:first)
            quantity_inflation.update_column(:previous_quantity, variant.fba_quantity)
            stock_product.update_column(:count_on_hand, stock)
            stock_product.reload
            if zalora_stock_hash[seller_market_place.id.to_s].present?
              zalora_stock_hash[seller_market_place.id.to_s].first.merge!(variant.sku.to_s=>stock)
            else
              zalora_stock_hash.merge!(seller_market_place.id.to_s=>[{variant.sku.to_s=>stock}])
            end
          rescue Exception => e  
          end  
        end
        # Update stock for lazada in bulk
        Spree::StockMovement.stock_update_lazada_bulk(zalora_stock_hash) if zalora_stock_hash.present?
      when "qoo10"   
        var_stock_hash.each do |id, stock|
          begin
            variant = Spree::Variant.includes(:quantity_inflations).find(id)
            product = variant.product
            market_place_product = Spree::SellersMarketPlacesProduct.where(:seller_id => product.seller_id, :product_id => product.id, :market_place_id => market_place.id).try(:first)
            stock_product = variant.stock_products.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.market_place_id=?", market_place.id).try(:first)
            quantity_inflation = variant.quantity_inflations.where(:market_place_id=>market_place.id).try(:first)
            quantity_inflation.update_column(:previous_quantity, stock_product.count_on_hand)
            stock_product.update_column(:count_on_hand, stock)
            stock_product.reload
            Spree::StockMovement.stock_update_qoo10(product, market_place.id, stock, stock_product, seller_market_place, market_place_product, stock)
          rescue Exception => e  
          end  
        end
      end
      return error
    end
    
    # This action is to end stock inflation promotion
    # def end_of_promotion
    #   variant = self.variant
    #   product = variant.product
    #   seller = product.seller
    #   ord_qty_hash = {}
    #   qty = 0
    #   new_stock = 0
    #   total_qty = 0
    #   orders = seller.orders.includes(:line_items).where(:order_date=>self.created_at..self.end_date.end_of_day).where("spree_line_items.variant_id=?", variant.id)
    #   ord_no = orders.map(&:cart_no).uniq.count
    #   orders.each do |ord|
    #     total_qty = total_qty + ord.line_items.map(&:quantity).sum
    #   end
    #   case self.next_type
    #   when "Revert to Previous Qty"
    #     new_stock = self.previous_quantity
    #     qty = total_qty
    #   when "Sync with FBA"
    #     new_stock = 0
    #     seller_market_place = Spree::SellerMarketPlace.where(:seller_id=>seller.id).try(:first)
    #     Spree::Variant.fetch_qty_from_fba(seller_market_place, variant)
    #     qty = total_qty - self.previous_quantity
    #   when "Reset to Zero"
    #     new_stock = 0
    #     qty = total_qty - self.previous_quantity
    #   else
    #     new_stock = 0
    #     qty = total_qty - self.previous_quantity
    #   end
    #   qty = qty < 0 ? 0 : qty
    #   ord_qty_hash.merge!(variant.id=>[total_qty, qty, ord_no])
    #   # To when one marketplace promotion ends its changes reflects to other marketplace also because of stock resent, so automatically end promotion on other marketplaces
    #   variant.quantity_inflations.destroy_all
    #   #self.destroy
    #   product.update_attributes!(:stock_config_type=> 0) if !product.quantity_inflations.present?
    #   variant.update_attributes!(:fba_quantity=>new_stock)
    #   variant.reload
    #   return ord_qty_hash
    # end
    def end_of_promotion
      variant = self.variant
        product = variant.product
        seller = product.seller
        ord_qty_hash = {}
        qty = 0
        new_stock = 0
        total_qty = 0
        orders = seller.orders.includes(:line_items).where(:order_date=>self.created_at..self.end_date.end_of_day).where("spree_line_items.variant_id=?", variant.id)
        ord_no = orders.map(&:cart_no).uniq.count
        orders.each do |ord|
          total_qty = total_qty + ord.line_items.map(&:quantity).sum
        end
        seller_market_place = Spree::SellerMarketPlace.where(:seller_id=>seller.id).try(:first)

        qty = total_qty - self.previous_quantity
        variant.reload
        new_stock = variant.fba_quantity
        qty = qty < 0 ? 0 : qty
        ord_qty_hash.merge!(variant.id=>[total_qty, qty, ord_no])
        # To when one marketplace promotion ends its changes reflects to other marketplace also because of stock resent, so automatically end promotion on other marketplaces
        variant.quantity_inflations.each {|q_inf| q_inf.destroy}
        variant.quantity_inflations.reload
        product.update_attributes!(:stock_config_type=> 0) if !product.quantity_inflations.present?
        Spree::Variant.fetch_qty_from_fba(seller_market_place, variant) if !variant.parent_id.present?
        #variant.update_attributes!(:fba_quantity=>new_stock)

      if variant.parent_id.present?
        parent = variant.get_parent
        Spree::Variant.fetch_qty_from_fba(seller_market_place, parent)
        parent.reload
        variant.update_attributes!(:fba_quantity=>parent.fba_quantity) if !variant.quantity_inflations.present?
        msg = 'Model - Quantity Inflation / end of promotion'
        variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
      end
      variant.update_stock_after_change if !variant.quantity_inflations.present?
      variant.reload
      return ord_qty_hash
    end

    # Check daily promotion report
    def daily_promotion_report
      variant = self.variant
      product = variant.product
      seller = product.seller
      ord_qty_hash = {}
      qty = 0
      total_qty = 0
      qty_daily = 0
      total_qty_daily = 0
      s_date = Time.now.beginning_of_day
      e_date = Time.now.end_of_day
      orders_daily = seller.orders.includes(:line_items).where(:order_date=>s_date..e_date).where("spree_line_items.variant_id=?", variant.id)
      orders = seller.orders.includes(:line_items).where(:order_date=>self.created_at..e_date).where("spree_line_items.variant_id=?", variant.id)
      ord_no = orders.map(&:cart_no).uniq.count
      ord_no_daily = orders_daily.map(&:cart_no).uniq.count
      orders.each do |ord|
        total_qty = total_qty + ord.line_items.map(&:quantity).sum
      end
      orders_daily.each do |ord|
        total_qty_daily = total_qty_daily + ord.line_items.map(&:quantity).sum
      end
      case self.next_type
      when "Revert to Previous Qty"
        qty = total_qty
        qty_daily = total_qty_daily
      when "Sync with FBA"
        qty = total_qty - self.previous_quantity
        qty_daily = total_qty_daily - self.previous_quantity
      when "Reset to Zero"
        qty = total_qty - self.previous_quantity
        qty_daily = total_qty_daily - self.previous_quantity
      else  
        qty = total_qty - self.previous_quantity
        qty_daily = total_qty_daily - self.previous_quantity
      end  
      qty = qty < 0 ? 0 : qty
      qty_daily = qty_daily < 0 ? 0 : qty_daily    
      ord_qty_hash.merge!(variant.id=>[seller.name.capitalize, variant.name, variant.sku, ord_no, total_qty, qty, ord_no_daily, total_qty_daily, qty_daily, self.end_date.strftime("%d/%m/%Y"), ])
      return ord_qty_hash
    end

    # Check daily promotion report
    def daily_promotion_report
      variant = self.variant
      product = variant.product
      seller = product.seller
      ord_qty_hash = {}
      qty = 0
      total_qty = 0
      qty_daily = 0
      total_qty_daily = 0
      s_date = Time.now.beginning_of_day
      e_date = Time.now.end_of_day
      orders_daily = seller.orders.includes(:line_items).where(:order_date=>s_date..e_date).where("spree_line_items.variant_id=?", variant.id)
      orders = seller.orders.includes(:line_items).where(:order_date=>self.created_at..e_date).where("spree_line_items.variant_id=?", variant.id)
      ord_no = orders.map(&:cart_no).uniq.count
      ord_no_daily = orders_daily.map(&:cart_no).uniq.count
      orders.each do |ord|
        total_qty = total_qty + ord.line_items.map(&:quantity).sum
      end
      orders_daily.each do |ord|
        total_qty_daily = total_qty_daily + ord.line_items.map(&:quantity).sum
      end
      case self.next_type
      when "Revert to Previous Qty"
        qty = total_qty
        qty_daily = total_qty_daily
      when "Sync with FBA"
        qty = total_qty - self.previous_quantity
        qty_daily = total_qty_daily - self.previous_quantity
      when "Reset to Zero"
        qty = total_qty - self.previous_quantity
        qty_daily = total_qty_daily - self.previous_quantity
      else  
        qty = total_qty - self.previous_quantity
        qty_daily = total_qty_daily - self.previous_quantity
      end  
      qty = qty < 0 ? 0 : qty
      qty_daily = qty_daily < 0 ? 0 : qty_daily    
      ord_qty_hash.merge!(variant.id=>[seller.name.capitalize, variant.name, variant.sku, ord_no, total_qty, qty, ord_no_daily, total_qty_daily, qty_daily, self.end_date.strftime("%d/%m/%Y"), ])
      return ord_qty_hash
    end
    
  end
end
