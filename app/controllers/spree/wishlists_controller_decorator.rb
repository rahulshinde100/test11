module Spree
  WishlistsController.class_eval do

    def clear
      spree_current_user.wishlist.wished_products.delete_all
      flash[:success] = "All Products are removed from your wishlist"
      redirect_to user_root_path
    end

  end
end