module Spree
  module Admin
    LineItemsController.class_eval do
      respond_to :html
      load_and_authorize_resource :class => Spree::LineItem

      # code to delete line items from order
      def destroy
            @line_item = Spree::LineItem.find_by_id(params[:id])
            @order = Spree::Order.find_by_number(params[:order_id])
             # code to find the order_total
             if @order.market_place.present?
                case @order.market_place.code
                when "qoo10"
                    order_total = @order.market_place_details.present? ? @order.market_place_details["total"] : @order.total
                when "lazada" , "zalora"
                    order_total = @order.total
                end
             end
             if @line_item.present?
                 increased_qty = @line_item.quantity
                 @variant = @line_item.variant
                 @product = @variant.product if @variant.present?
                 @line_item.destroy
                 @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @order.seller_id, @order.market_place_id, @product.id).try(:first)
                  if @sellers_market_places_product.present?
                     @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, @variant.id).try(:first)
                      if @stock_product.present?
                         @stock_product.update_attributes(:count_on_hand=>@stock_product.count_on_hand + increased_qty.to_i)
                         @variant.update_attributes(:fba_quantity=>@variant.fba_quantity + increased_qty.to_i) if !@variant.quantity_inflations.present?
                         msg = 'Line Items Controller destroy'
                         @variant.add_log_on_update(msg) rescue QTY_LOG.error "#{Time.zone.now} Error --  #{msg}"
                      end
                  end
             end
             # code to update order total after creating line item for order
            @order.update_column(:total, order_total)
            @order.reload
             respond_to do |format|
                  format.html { redirect_to modify_order_admin_order_path(@order), notice: 'Product is successfully deleted' }
             end
      end

   end
  end
end