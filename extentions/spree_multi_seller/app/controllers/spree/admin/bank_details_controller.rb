module Spree
	module Admin
		class BankDetailsController < Spree::Admin::ResourceController
      before_filter :load_seller, :verify_seller

      def index
        unless @seller.bank_detail.nil?
          redirect_to admin_seller_bank_detail_path(@seller, @seller.bank_detail)
        else
          redirect_to new_admin_seller_bank_detail_path(@seller), :notice => "Bank details is not available"
        end
        return
      end

			def new
        @render_breadcrumb = breadcrumb_path({@seller.name => admin_seller_path(@seller.id),:disable => "Bank Deatils"})
			end

      def show
        @bank_detail = @seller.bank_detail
      end

			def create
				@bank_detail = @seller.build_bank_detail(params[:bank_detail])
				if @bank_detail.save
					if spree_current_user.has_spree_role? 'admin'
						redirect_to new_admin_seller_seller_category_path(@seller), :notice => "Bank Detail has been added"
					else
						redirect_to edit_admin_seller_path(@seller), :notice => "Bank Detail has been added"
					end
				else
					render :new
				end
			end

			def edit
				@bank_detail = Spree::BankDetail.find(params[:id])
			end

			def update
				@seller_bank_detail = Spree::BankDetail.find(params[:id])
        if@seller_bank_detail.update_attributes(params[:bank_detail])
          if @seller.is_completed?
            redirect_to admin_seller_bank_detail_path(@seller, @seller_bank_detail), :notice => "Bank Detail has been added"
          else
            redirect_to new_admin_seller_seller_category_path(@seller), :notice => "Bank Detail has been added"
          end
        else
          render :edit
        end
			end

			def destroy
        @bank_detail.destroy
				redirect_to admin_seller_bank_details_path(@seller), :notice => "Bank Detail has been deleted"
			end

      private
      def load_seller
        @seller = Spree::Seller.find_by_permalink(params[:seller_id])
      end
		end
	end
end
