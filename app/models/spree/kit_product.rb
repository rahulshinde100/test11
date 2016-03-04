module Spree
  class KitProduct < ActiveRecord::Base
    belongs_to :kit, :foreign_key => :kit_id, :class_name => "Spree::Kit"
    belongs_to :product, :foreign_key => :product_id, :class_name => "Spree::Product"
    belongs_to :variant, :foreign_key => :variant_id, :class_name => "Spree::Variant"

    attr_accessible :kit_id, :product_id, :variant_id, :quantity
    validates_presence_of :kit_id, :product_id, :variant_id, :quantity
  
    after_save :allocate_stock_to_kit
    after_destroy :allocate_stock_to_kit_on_delete
  
    # re-allocate stock to kit after kit product add or update 
    def allocate_stock_to_kit
      kit = self.kit
      lowest_stock = (self.variant.fba_quantity/self.quantity).to_i
      kit.kit_products.each_with_index do |kp, ind|
        qty = (kp.variant.fba_quantity/kp.quantity).to_i
        if ind == 0
          lowest_stock = qty  
        elsif (ind!=0 && lowest_stock > qty)
          lowest_stock = qty
        end
      end
      kit.product.master.update_column(:fba_quantity, lowest_stock)
      kit.update_attributes!(:quantity=>lowest_stock)  
      msg = 'Model - Kit Product / allocate stock for kit'
      kit.product.master.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
    end
    
    # re-allocate stock to kit after kit product delete
    def allocate_stock_to_kit_on_delete
      kit = self.kit
      lowest_stock = 0
      kit.kit_products.each_with_index do |kp, ind|
        qty = (kp.variant.fba_quantity/kp.quantity).to_i
        if kp.id != self.id 
          if ind == 0
            lowest_stock = qty  
          elsif (ind!=0 && lowest_stock > qty)
            lowest_stock = qty
          end
        end  
      end
      kit.product.master.update_column(:fba_quantity, lowest_stock)
      kit.update_attributes!(:quantity=>lowest_stock)
      msg = 'Model - Kit Product / allocate stock for kit after delete product'
      kit.product.master.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
    end

  end
end
