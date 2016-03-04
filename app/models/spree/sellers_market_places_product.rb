module Spree
  class SellersMarketPlacesProduct < ActiveRecord::Base
    attr_accessible :seller_id, :market_place_id, :product_id, :market_place_product_code, :stock_config_details, :is_active, :last_update_on_mp, :unmap_mail_sent_at

    belongs_to :market_place
    belongs_to :seller
    belongs_to :product
    has_many :stock_products, dependent: :destroy

    default_scope { where(is_active: true) }
    
    validates_presence_of :seller_id, :market_place_id, :product_id

    after_create :apply_default_stock_setting
    after_save :add_default_entries
    after_destroy :remove_dependent_entries

    # To remove dependent entries after delete product mapping with market places from table stock, title, price and description management
    def remove_dependent_entries
      product = self.product
      variants = (product.variants.present? ? product.variants : product.master)
      product.stock_products.where(:sellers_market_places_product_id=>self.id).destroy_all
      #product.title_managements.where(:market_place_id=>self.market_place_id).destroy_all
      #product.description_managements.where(:market_place_id=>self.market_place_id).destroy_all
      #variants.each do |variant|
       # variant.price_managements.where(:market_place_id=>self.market_place_id).destroy_all
      #end
    end

    # add default product name, stock, description and price as per market places
    def add_default_entries
      product = self.product
      begin
        # Title entry
        tm = Spree::TitleManagement.where("market_place_id=? AND product_id=?", self.market_place_id, self.product_id)
        if !tm.present?
          Spree::TitleManagement.create(:name=>product.name, :market_place_id=>self.market_place_id, :product_id=>product.id)
        else
          tm.update_all(:name=>product.name)
        end

        # Desctription entry
        dm = Spree::DescriptionManagement.where("market_place_id=? AND product_id=?", self.market_place_id, self.product_id)
        if !dm.present?
          Spree::DescriptionManagement.create(:description=>product.description, :market_place_id=>self.market_place_id, :product_id=>product.id, :meta_description=>product.meta_description, :package_content=>product.package_content)
        else
          dm.update_all(:description=>product.description, :meta_description=>product.meta_description, :package_content=>product.package_content)
        end

        # Price & Stock entry
        variants = []
        variants << (product.variants.present? ? product.variants : product.master)
        variants = variants.flatten
        variants.each do |variant|
          sp = variant.stock_products.where(:sellers_market_places_product_id=>self.id)
          if !sp.present?
            type = STOCKCONFIG[product.stock_config_type] == "default" ? STOCKCONFIG[product.seller.stock_config_type] : STOCKCONFIG[product.stock_config_type]
            count_on_hand = 0
            count_on_hand = variant.fba_quantity if (type == 'flat_quantity')
            Spree::StockProduct.create(:sellers_market_places_product_id=>self.id, :variant_id=>variant.id, :virtual_out_of_stock=>false, :count_on_hand=>count_on_hand)
          else
            sp.update_all(:count_on_hand=>0)
          end

          pm = Spree::PriceManagement.where("market_place_id=? AND variant_id=?", self.market_place_id, variant.id)
          if !pm.present?
            Spree::PriceManagement.create(:selling_price=>variant.selling_price.to_f, :special_price=>variant.special_price.to_f, :settlement_price=>0.0, :market_place_id=>self.market_place_id, :variant_id=>variant.id)
          else
            pm.update_all(:selling_price=>variant.selling_price.to_f, :special_price=>variant.special_price.to_f, :settlement_price=>0.0)
          end
        end
      rescue Exception=> e
      end
    end

    # Apply default setting as per seller current setting for stock setting management
    def apply_default_stock_setting
      self.product.update_attributes(:stock_config_type=>0)
      smp = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?",self.seller_id, self.market_place_id)
      self.update_attributes(:stock_config_details=>smp.first.stock_config_details) if smp.present?
    end

  end
end
