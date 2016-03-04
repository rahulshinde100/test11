module Spree
  class AbilityDecorator
    include CanCan::Ability

    def initialize(user)
      if user.has_spree_role?('seller') && user.seller
        if user.seller.is_active
          # Added By Tejaswini for seller role and Order permissions
          can :manage, Spree::Order, :id => user.seller.orders.map(&:id)
          can :update, Spree::Order, :id => user.seller.orders.map(&:id)
          cannot :partial_orders, Spree::Order
          
          # Added by Tejaswini Patil for Product permissions
          can :manage, Spree::Product, :seller_id => user.seller.id
          can :collection, Spree::Product, :seller_id => user.seller.id
          can :create, Spree::Product
          can :update, Spree::Product

          # Added By Tejaswini for Seller
          can :manage, Seller, Seller.where(:id => user.seller.id) do |s| 
            s.id == user.seller.id
          end
          can :manage, SellerCategory, SellerCategory.where(:seller_id => user.seller.id) do |seller_category|
            seller_category.seller.id == user.seller.id
          end
          can :manage, BankDetail, BankDetail.where(:seller_id => user.seller.id) do |bank_detail|
            unless bank_detail.seller.nil?
              bank_detail.seller.id == user.seller.id
            end
          end

          # Added by Tejaswini for Market place
          can [:admin,:manage], Spree::MarketPlace, :id => user.seller.market_places.map(&:id)
          
          can [:admin,:manage,:generate_api_secret_key], Spree::SellerMarketPlace, :seller_id => user.seller.id
          can [:admin,:create], Spree::SellerMarketPlace

          can [:admin,:manage], Spree::SellersMarketPlacesProduct, :seller_id => user.seller.id
    

          # Added by Tejaswini for Image and variant creation
          can :manage, Variant, :id => Variant.includes(:product).where(:product_id => user.seller.products.map(&:id)).map(&:id)
          can [:create,:edit,:update,:delete, :get_new_variants, :get_updated_variants, :create_on_fba, :update_on_fba], Variant
          
          can :manage, Image, :viewable_type => "Spree::Variant", :id => Variant.includes(:product).where(:product_id => user.seller.products.map(&:id)).map(&:id)
          can [:create,:edit,:update,:delete], Image
          can [:admin, :manage, :get_new_variants]#, Variant, :id => Variant.includes(:product).where(:product_id => user.seller.products.map(&:id)).map(&:id)         
          
          # Added by Tejaswini
          # Seller and its users
          can :create, Spree::SellerUser, :id => user.seller_user.id  
          can :manage, Spree::SellerUser, :id => user.seller_user.id  
          can :manage, Spree::User, :id => user.seller.users.map(&:id)

          # Added by Tejaswini
          # Kit access
          can [:admin,:manage], Spree::Kit, :seller_id => user.seller.id    
          can [:admin,:create], Spree::Kit  
          # can :manage, Spree::KitProduct, :kit_id => user.seller.kits.map(&:id)

          can [:admin,:manage], Spree::StockTransfer 

          can [:admin,:manage], Spree::DescriptionManagement, :market_place_id => user.seller.market_places.map(&:id)
          can [:admin,:manage], Spree::PriceManagement, :market_place_id => user.seller.market_places.map(&:id)
          can [:admin,:manage], Spree::TitleManagement, :market_place_id => user.seller.market_places.map(&:id)
        end
    	end
    end
  end
    Spree::Ability.register_ability(AbilityDecorator)
end
