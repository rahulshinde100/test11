module Spree
  WishedProductsController.class_eval do

    def create
      @wished_product = Spree::WishedProduct.new(params[:wished_product])
      @wishlist = spree_current_user.wishlist

      if @wishlist.include? params[:wished_product][:variant_id]
        flash[:success] = "Product already exists in your wishlist"
        @wished_product = @wishlist.wished_products.detect {|wp| wp.variant_id == params[:wished_product][:variant_id].to_i }
      else
        flash[:success] = "Product has been added to your wishlist"
        @wished_product.wishlist = spree_current_user.wishlist
        @wished_product.save
      end

      respond_with(@wished_product) do |format|
        format.html { redirect_to request.referrer }
      end
    end

    def wished_product
      if spree_current_user.present?
        @wished_product = Spree::WishedProduct.create!(:variant_id => params[:variant_id])
        @wishlist = spree_current_user.wishlist
        unless @wishlist.include? params[:variant_id].to_i
           flash[:success] = "Product has been added to your wishlist"
           @wished_product.wishlist = spree_current_user.wishlist
           @wished_product.save
          if request.xhr?
            render :text => "register"
            return
          end
        else
          flash[:success] = "Product already exists in your wishlist"
          @wished_product = @wishlist.wished_products.detect {|wp| wp.variant_id == params[:variant_id].to_i }
          if request.xhr?
            render :text => "already_register"
            return
          end
        end
         respond_with(@wished_product) do |format|
            format.html { redirect_to request.referrer }
          end
      else
        render :text => "login"
      end
        return
    end
    
    def destroy
      @wished_product = Spree::WishedProduct.find(params[:id])
      @wished_product.destroy

      respond_with(@wished_product) do |format|
        format.html { redirect_to wishlist_url(@wished_product.wishlist) }
        format.js
      end
    end

  end
end