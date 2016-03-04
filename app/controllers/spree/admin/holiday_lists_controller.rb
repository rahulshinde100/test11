module Spree
	module Admin
    class HolidayListsController < Spree::Admin::BaseController
      before_filter :load_seller, :verify_seller
      
      def index
        @holiday_lists = Kaminari.paginate_array(@seller.holiday_lists).page(params[:page]).per(50)
        respond_to do |format|
          format.html
          format.json { render json: @holiday_lists }
        end
      end

      def show
        redirect_to edit_admin_seller_holiday_list_path(@seller, params[:id])
        return
      end

      def new
        @holiday_list = HolidayList.new

        respond_to do |format|
          format.html # new.html.erb
          format.json { render json: @holiday_list }
        end
      end

      def edit
        @holiday_list = HolidayList.find(params[:id])
      end

      def create
        @holiday_list = HolidayList.new(params[:holiday_list].merge!(:seller_id => @seller.id))
        if params[:store].blank?
          @holiday_list.errors[:stock_locations] = "Please select atleast one stock location"
          render action: "new"
          return
        end

        respond_to do |format|
          if @holiday_list.save
            @holiday_list.stock_locations << @seller.stock_locations.where(:id => params[:store].keys) unless params[:store].blank?
            format.html { redirect_to admin_seller_holiday_lists_path(@seller), notice: 'Holiday list was successfully created.' }
            format.json { render json: @holiday_list, status: :created, location: @holiday_list }
          else
            format.html { render action: "new" }
            format.json { render json: @holiday_list.errors, status: :unprocessable_entity }
          end
        end
      end

      def update
        @holiday_list = HolidayList.find(params[:id])
        respond_to do |format|
          if @holiday_list.update_attributes(params[:holiday_list])
            @holiday_list.stock_location_holiday_lists.delete_all
            @holiday_list.stock_locations << @seller.stock_locations.where(:id => params[:store].keys)
            format.html { redirect_to admin_seller_holiday_lists_path(@seller), notice: 'Holiday list was successfully updated.' }
            format.json { head :no_content }
          else
            format.html { render action: "edit" }
            format.json { render json: @holiday_list.errors, status: :unprocessable_entity }
          end
        end
      end

      # DELETE /holiday_lists/1
      # DELETE /holiday_lists/1.json
      def destroy
        @holiday_list = HolidayList.find(params[:id])
        @holiday_list.destroy

        respond_to do |format|
          format.html { redirect_to admin_seller_holiday_lists_path(@seller) }
          format.json { head :no_content }
        end
      end
      
      def import
        authorize! :import, Spree::HolidayList 
        begin
          if params[:file] && params[:file].content_type == 'text/csv' || params[:file].content_type == "application/vnd.ms-excel"
            HolidayList.import(params[:file])
            redirect_to admin_seller_holiday_lists_path(@seller), notice: "Holiday List imported."
          else
            flash[:error] = "Invalid file formate, Please select CSV file."
            redirect_to admin_seller_holiday_lists_path(@seller)
          end
        rescue
          # handle the exception here; the entire transaction gets rolled-back
          flash[:error] = "Please check the CSV file contents or You may be uploading the same holiday "
          redirect_to admin_seller_holiday_lists_path(@seller)
          return
        end
      end

      def authorize_admin
        authorize! params[:action].to_sym, Spree::HolidayList #, @seller.id
      end

      private
      def load_seller
        @seller = Spree::Seller.find_by_permalink(params[:seller_id])
      end
    end
   end
end
