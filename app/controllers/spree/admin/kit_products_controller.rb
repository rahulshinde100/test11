module Spree
  module Admin
    class KitProductsController < Spree::Admin::BaseController
      load_and_authorize_resource :class => Spree::KitProduct
      respond_to :html

      # Mehtod to load product variants on add product form in kit
      def load_variants
        @kit = Spree::Kit.find(params[:kit_id])
        @products = @kit.seller.products.where(:is_approved=>true, :kit_id=>nil)
        @product_hash = []
        @products.each do |product|
          product_variants = []
          product_variants << (product.variants.present? ? product.variants : product.master)
          product_variants = product_variants.flatten
          product_variants.each do |pv|
            if !pv.parent_id.present?
              if pv.option_values.present?
                @product_hash << {:name=> (product.name+" -> "+pv.option_values.first.presentation+" ("+pv.sku.to_s+")"), :id=>pv.id}
              else
                @product_hash << {:name=> (product.name+" ("+pv.sku.to_s+")"), :id=>pv.id}
              end
            end

          end
        end if @products.present?
        respond_to do |format|
          format.html { render :partial=>"add_products"}
        end
      end

      def product_variants_json
        @products_json = []
        @kit = Spree::Kit.find(params[:kit_id])
        @products = @kit.seller.products.where(:is_approved=>true, :kit_id=>nil)
        @products.each do |product|
          product_variants = []
          product_variants << (product.variants.present? ? product.variants : product.master)
          product_variants = product_variants.flatten
          product_variants.each do |pv|
            if !pv.parent_id.present?
            name = (pv.option_values.present? ? (product.name+" -> "+pv.option_values.first.presentation+" ("+pv.sku.to_s+")") : (product.name+" ("+pv.sku.to_s+")"))
            @products_json << {'label' => name, 'id' => pv.id} if name.downcase.include? params[:term].downcase
              end
          end
        end if @products.present?
        render :json=>@products_json.to_json
      end

     def add_variants
       @kit = Spree::Kit.find(params[:kit_id])
       @product = Spree::Variant.find(params[:variant_id]).product
       @kit.product.update_column(:brand_id, @product.brand_id) if !@kit.kit_products.present?
       @errors = ""
       respond_to do |format|
         if !@kit.is_common_stock?
           @market_places = @kit.market_places
           @market_places.each do |mp|
             @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @kit.seller_id, mp.id, @product.id).first
             if @sellers_market_places_product.present?
               @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, params[:variant_id]).first
               if @stock_product.present?
                 variant_qty = @stock_product.count_on_hand
                 requested_qty = params[:quantity]
                 kit_qty = @kit.quantity
                 overall_qty = (kit_qty.to_i * requested_qty.to_i)
                 if variant_qty < overall_qty
                   @errors = "Oops..This much quantity of products are not available"
                 else
                   # code for deduct the stock from product stock
                   qty_for_update = variant_qty - overall_qty
                   @stock_product.update_attributes(:count_on_hand => qty_for_update)
                 end
               end
             end
           end
           if @errors.length == 0
             @existing_kit_product = Spree::KitProduct.where("kit_id=? AND variant_id=?", params[:kit_id], params[:variant_id]).first
             if !@existing_kit_product.blank?
               old_qty = @existing_kit_product.quantity.to_i
               new_qty = params[:quantity].to_i
               total_qty = old_qty + new_qty
               @existing_kit_product.update_attributes(:quantity => total_qty)
             else
               @variant = Spree::Variant.find(params[:variant_id])
               @existing_kit_product = Spree::KitProduct.create(:kit_id=>params[:kit_id], :variant_id=>params[:variant_id], :product_id=>@variant.try(:product).id, :quantity=>params[:quantity])
             end
           end
         else
           @existing_kit_product = Spree::KitProduct.where("kit_id=? AND variant_id=?", params[:kit_id], params[:variant_id]).first
           if !@existing_kit_product.blank?
             old_qty = @existing_kit_product.quantity.to_i
             new_qty = params[:quantity].to_i
             total_qty = old_qty + new_qty
             @existing_kit_product.update_attributes(:quantity => total_qty)
           else
             @variant = Spree::Variant.find(params[:variant_id])
             @existing_kit_product = Spree::KitProduct.create(:kit_id=>params[:kit_id], :variant_id=>params[:variant_id], :product_id=>@variant.try(:product).id, :quantity=>params[:quantity])
           end
         end
         # render partial for kit products
         if @errors && @errors.length > 0
           format.html { render :text=>@errors }
         else
           @kit = @existing_kit_product.kit
           @kit_products = @kit.kit_products
           @kit_products = Kaminari.paginate_array(@kit_products).page(params[:page]).per(Spree::Config[:admin_products_per_page])
           format.html { render :partial=>"index"}
         end
       end
     end

      def destroy
        @kit_product = Spree::KitProduct.find(params[:id]) rescue nil
        respond_to do |format|
          if @kit_product.present?
            @kit = @kit_product.kit
            variant = @kit_product.variant
            if @kit_product.destroy
              @product = Spree::Variant.find(variant.id).product
              if !@kit.is_common_stock?
                @market_places = @kit.market_places
                @market_places.each do |mp|
                  @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @kit.seller_id, mp.id, @product.id).first
                  if @sellers_market_places_product.present?
                    @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, @kit_product.variant.id).first
                    if @stock_product.present?
                      variant_qty = @stock_product.count_on_hand
                      requested_qty = @kit_product.quantity
                      kit_qty = @kit.quantity
                      overall_qty = (kit_qty.to_i * requested_qty.to_i)
                      qty_for_update = variant_qty + overall_qty
                      @stock_product.update_attributes(:count_on_hand => qty_for_update)
                    end
                  end
                end
              end
              format.html { redirect_to admin_kit_path(@kit), notice: 'Product was successfully deleted.' }
              format.json { render json: @kit_product, status: :created, location: @kit_product }
            else
              format.html { redirect_to admin_kit_path(@kit), notice: 'Product was not successfully deleted.' }
              format.json { render json: @kit_product.errors, status: :unprocessable_entity }
            end
          else
            redirect_to :back, notice: 'Product was successfully deleted.'
          end # end for kit product condition
        end # end for respond format
      end

    end
  end
end
