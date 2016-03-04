module Spree
  module Api
    VariantsController.class_eval do

      def index
         @variants = scope.includes(:option_values, :stock_items, :product, :images, :prices).ransack(params[:q]).result.
          page(params[:page]).per(params[:per_page])
         # @variants = Spree::Variant.unscoped.ransack(params[:q]).result.
         #     page(params[:page]).per(params[:per_page])
        respond_with(@variants)
      end
      def search_for_promotion
        if params[:ids]
          @variants = Spree::Variant.unscoped.where(:id => params[:ids].split(',')).ransack(params[:q]).result.
              page(params[:page]).per(params[:per_page])
        else
        ap params
        variants = []
        @products_json = []
        promotion = Spree::Promotion.find(params[:promotion_id]) rescue nil
        p promotion
        act = (promotion.event_name == 'spree.set_special_price') rescue false
        p act
        if act
          @products = Spree::Product.where(:is_approved=>true)

          @products.each do |product|
            product_variants = []
            product_variants << (product.variants.present? ? product.variants : product.master)
            product_variants = product_variants.flatten
            product_variants.each do |pv|
              # if !pv.parent_id.present?
                variants << pv.id
              # end
            end
          end if @products.present?

        else
          @products = Spree::Product.where(:is_approved=>true, :kit_id=>nil)

          @products.each do |product|
            product_variants = []
            product_variants << (product.variants.present? ? product.variants : product.master)
            product_variants = product_variants.flatten
            product_variants.each do |pv|
              if !pv.parent_id.present?
                variants << pv.id
              end
            end
          end if @products.present?

        end
        @variants = Spree::Variant.includes(:product).unscoped.where(:id => variants).ransack(params[:q]).result.
            page(params[:page]).per(params[:per_page])
        end
        respond_with(@variants)
      end
      def show
        @variant = scope.includes([:option_values, :stock_items]).find(params[:id])
        respond_with(@variant)
      end

      def create
        authorize! :create, Variant
        @product = Spree::Product.find(params[:product_id])
        @variant = @product.variants.build(params[:variant])
        @variant.option_values << Spree::OptionValue.where(:id => params[:option_values])
        Spree::Variant.transaction do
          @variant.save
          params[:stock_items].each do |item|
            stock_location = Spree::StockLocation.find(item["stock_location_id"].to_i)
            stock_movement = stock_location.stock_movements.build(:quantity => item["quantity"].to_i)
            stock_movement.stock_item = stock_location.set_up_stock_item(@variant)
            stock_movement.save
            #reset master variant as 0
            Spree::StockItem.where(:variant_id => @product.master).update_all(:count_on_hand => 0)
          end unless params[:stock_items].nil?
        end
      end

      def update
        authorize! :update, Variant
        @variant = scope.find(params[:id])
        if @variant.update_attributes(params[:variant])
          #UPDATE STOCK ITEM ENTRY WITH VARIANTS
          params[:stock_items].each do |item|
            stock_location = Spree::StockLocation.find(item["stock_location_id"].to_i)
            stock_movement = stock_location.stock_movements.build(:quantity => item["quantity"].to_i)
            stock_movement.stock_item = stock_location.set_up_stock_item(@variant)
            stock_movement.save
          end unless params[:stock_items].nil?
          respond_with(@variant, :status => 200, :default_template => :show)
        else
          invalid_resource!(@product)
        end
      end

      def destroy
        authorize! :delete, Variant
        @variant = scope.find(params[:id])
        @variant.destroy
        @response = {:response => "Deleted Succsessfuly"}
      end

      private
      def scope
        if @product
          unless current_api_user.has_spree_role?("admin") || params[:show_deleted]
            variants = @product.variants_including_master
          else
            variants = @product.variants_including_master.with_deleted
          end
        else
          variants = Spree::Variant.scoped
          current_user = spree_current_user.nil? ? current_api_user : spree_current_user
          if current_user.has_spree_role?("admin")
            unless params[:show_deleted]
              variants = Spree::Variant.active.available
            end
          elsif current_user.has_spree_role?("seller")
            unless params[:show_deleted]
              variants = Spree::Variant.active.available.where(:product_id => current_user.seller.products.map(&:id))
            end
          else
            variants = variants.active
          end
        end
          variants
      end
    end
  end
end
