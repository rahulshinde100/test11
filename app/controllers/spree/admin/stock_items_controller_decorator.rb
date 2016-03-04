Spree::Admin::StockItemsController.class_eval do
   before_filter :determine_backorderable, only: :update

        def out_of_stock
          @product = Spree::Product.find(params[:product_id])
          #stock_item = Spree::StockItem.find(params[:id])
          @stock_product = Spree::StockProduct.find(params[:stock_product_id])
          out_of_stock_per_location(@stock_product)
          redirect_to manage_stock_admin_product_path(@product)
          #redirect_to stock_admin_product_path(@product)
        end

        # Make product out of stock globally
        def out_of_stock_globally
          # status = params[:status] == "true" ? true : false
          # @product = Spree::Product.find(params[:product_id])
          # variants = @product.variants.present? ? @product.variants : [@product.master]
          # variants.each do |variant|
          #   Spree::StockItem.where(:variant_id => variant.id).each do |stock_item|
          #     stock_item.update_attributes(:virtual_out_of_stock => status)
          #   end
          # end
          # flash[:success] = status ? "Product #{@product.name} is Out of Stock" : "Product #{@product.name} is Available now"
          # redirect_to stock_admin_product_path(@product)

          status = params[:status] == "true" ? true : false
          @product = Spree::Product.find(params[:product_id])
          variants = @product.variants.present? ? @product.variants : [@product.master]
          variants.each do |variant|
            Spree::StockProduct.where(:variant_id => variant.id).each do |stock_product|
              stock_product.update_attributes(:virtual_out_of_stock => status)
            end
          end
          flash[:success] = status ? "Product #{@product.name} is Out of Stock" : "Product #{@product.name} is Available now"
          redirect_to manage_stock_admin_product_path(@product)

        end

        # Make product out of stock variant wise
        def out_of_stock_per_location(stock_product)
          # if stock_item.virtual_out_of_stock?
          #   stock_item.update_attributes(:virtual_out_of_stock => false)
          #   flash[:success] = "#{stock_item.variant.name} is available in Stock now"
          # else
          #   stock_item.update_attributes(:virtual_out_of_stock => true)
          #   flash[:success] = "#{stock_item.variant.name} is Out of Stock now"
          # end

          if stock_product.virtual_out_of_stock?
            stock_product.update_attributes(:virtual_out_of_stock => false)
            flash[:success] = "#{stock_product.variant.name} is available in Stock now"
          else
            stock_product.update_attributes(:virtual_out_of_stock => true)
            flash[:success] = "#{stock_product.variant.name} is Out of Stock now"
          end
        end

      def update
        stock_item.save
        respond_to do |format|
          format.js { head :ok }
        end
      end

      def create
        message = ""
        #params[:stock_movement][:quantity] = (params[:stock_movement][:quantity].to_i < 0 ? (params[:stock_movement][:quantity].to_i*-1) : params[:stock_movement][:quantity].to_i)
        variant = Spree::Variant.find(params[:variant_id])
        #final_stock=(variant.stock_products.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.product_id=? AND sellers_market_places_product_id=?", variant.product.id, params[:sellers_market_places_product_id]).first.count_on_hand.to_i + params[:stock_movement][:quantity].to_i.to_i)
        if params[:stock_movement][:quantity].to_i >= 0
          if (STOCKCONFIG[variant.product.stock_config_type] == "flat_quantity") || (STOCKCONFIG[variant.product.stock_config_type] == "default" && (STOCKCONFIG[variant.product.seller.stock_config_type] == "flat_quantity"))
            v_stock_products=variant.stock_products.includes(:sellers_market_places_product).where("spree_sellers_market_places_products.product_id=?", variant.product.id)
            if variant.fba_quantity >= params[:stock_movement][:quantity].to_i
                variant.stock_products.each_with_index do |sp, ind|
                  @stock_movements = Spree::StockMovement.get_parameters_in_request(sp.sellers_market_places_product_id, params[:variant_id], params[:stock_movement][:quantity].to_i)
                end
                flash[:success] = "Stock updated successfully"
            else
                flash[:error] = "Total allocated stock can't exceeding available stock limit"
            end
          else
            other_mp_count = variant.stock_products.where("sellers_market_places_product_id !=? AND variant_id=?", params[:sellers_market_places_product_id], params[:variant_id]).sum(&:count_on_hand)
            if variant.fba_quantity >= (params[:stock_movement][:quantity].to_i + other_mp_count)
                @stock_movements = Spree::StockMovement.get_parameters_in_request(params[:sellers_market_places_product_id], params[:variant_id], params[:stock_movement][:quantity].to_i)
                flash[:success] = "Stock updated successfully"
            else
                flash[:error] = "Total allocated stock can't exceeding available stock limit"
            end
          end
        else
          flash[:error] = "Total allocated stock can't be negative"
        end
        redirect_to :back
      end

      def destroy
        stock_item.destroy

        respond_with(@stock_item) do |format|
          format.html { redirect_to :back }
          format.js
        end
      end

        def stock_item
          @stock_item ||= Spree::StockItem.find(params[:id])
        end

        def determine_backorderable
          stock_item.backorderable = params[:stock_item].present? && params[:stock_item][:backorderable].present?
        end
end
