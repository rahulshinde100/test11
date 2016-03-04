module Spree
	module Admin
		class SellerCategoriesController < Spree::Admin::ResourceController
                  before_filter :load_seller, :verify_seller

			def index
				@seller_categories = @seller.seller_categories
			end

			def new
			  @categories = []
        @render_breadcrumb = breadcrumb_path({@seller.name => admin_seller_path(@seller.id), :disable => "Select Categories"})
				@seller_category = @seller.seller_categories.build
				@categories = Spree::Taxonomy.categories.taxons.collect{|taxon| taxon if taxon.parent.nil? || taxon.parent.parent.nil?}.compact if Spree::Taxonomy.categories && Spree::Taxonomy.categories.taxons  
			end

			def create
				seller_category = []
				if params[:seller_category].present?
					params[:seller_category]["taxonomy_id"].each{|taxonomy| seller_category << {:taxon_id => taxonomy}}
					if @seller.seller_categories.create!(seller_category)
						unless @seller.is_completed?#spree_current_user.has_spree_role? 'admin'
							redirect_to new_admin_seller_seller_user_path(@seller), :notice => "Categories has been added"
						else
							redirect_to admin_seller_seller_categories_path(@seller), :notice => "Categories has been added"
						end
					else
						render :new
					end
                        else
                        	flash[:error] = "Please select at least one category"
                        	redirect_to admin_seller_seller_categories_path(@seller)
                        end
			end

			def destroy
				@seller_category = Spree::SellerCategory.find(params[:id])
				@seller_category.destroy
				redirect_to admin_seller_seller_categories_path(@seller)
			end

      private
      def load_seller
        @seller = Spree::Seller.find_by_permalink(params[:seller_id])
      end
		end
	end
end
