module Spree
  module Admin
    class SellersController < Spree::Admin::ResourceController
      load_and_authorize_resource :class => Spree::Seller
    	respond_to :html
      before_filter :load_data, :only => [:new, :edit]
      before_filter :update_params, :only => :create

      def index
        @render_breadcrumb = breadcrumb_path({:disable => "Sellers"})
        if params[:seller] == "deactive"
          @sellers = Seller.is_deactive.order(:name)
        elsif params[:seller] == "active"
          @sellers = Seller.is_active.order(:name)
        else
          @sellers = Seller.order("deleted_at").order("name").where(:deleted_at => nil).order(:is_active)
        end
      end

      def new
        @render_breadcrumb = breadcrumb_path({:sellers => admin_sellers_path, :disable => "New"})
        @seller = Seller.new
      end

      def create
        @seller = Seller.new params[:seller]
        file_ext = [".jpg", ".png", ".gif", ".bmp", ".tiff"]
        if params[:seller][:logo].present? && params[:seller][:banner].present?
           if !file_ext.include?(File.extname(params[:seller][:logo].original_filename))
              redirect_to new_admin_seller_path(@seller.id)
              flash[:error] = "Please upload valid image file for logo"
              return
           else
             if !file_ext.include?(File.extname(params[:seller][:banner].original_filename))
                redirect_to new_admin_seller_path(@seller.id)
                flash[:error] = "Please upload valid image file for banner"
                return
             else
                if @seller.save
                    if spree_current_user.has_spree_role? 'admin'
                      redirect_to new_admin_seller_seller_user_path(@seller)
                      flash[:success] = "Seller Details added successfully"
                    else
                      redirect_to edit_admin_seller_path(@seller)
                      flash[:success] = "Seller Details added successfully"
                    end
                else
                      render :new
                end
             end
           end
        elsif params[:seller][:logo].present? && !params[:seller][:banner].present?
           if !file_ext.include?(File.extname(params[:seller][:logo].original_filename))
              redirect_to new_admin_seller_path(@seller.id)
              flash[:error] = "Please upload valid image file for logo"
              return
           else
              if @seller.save
                  if spree_current_user.has_spree_role? 'admin'
                     redirect_to new_admin_seller_seller_user_path(@seller)
                     flash[:success] = "Seller Details added successfully"
                  else
                     redirect_to edit_admin_seller_path(@seller)
                     flash[:success] = "Seller Details added successfully"
                  end
              else
                     render :new
              end
           end
        elsif !params[:seller][:logo].present? && params[:seller][:banner].present?
           if !file_ext.include?(File.extname(params[:seller][:banner].original_filename))
              redirect_to new_admin_seller_path(@seller.id)
              flash[:error] = "Please upload valid image file for banner"
              return
           else
              if @seller.save
                  if spree_current_user.has_spree_role? 'admin'
                     redirect_to new_admin_seller_seller_user_path(@seller)
                     flash[:success] = "Seller Details added successfully"
                  else
                     redirect_to edit_admin_seller_path(@seller)
                     flash[:success] = "Seller Details added successfully"
                  end
              else
                     render :new
              end
           end
        elsif !params[:seller][:logo].present? && !params[:seller][:banner].present?
          if @seller.save
              if spree_current_user.has_spree_role? 'admin'
                 redirect_to new_admin_seller_seller_user_path(@seller)
                 flash[:success] = "Seller Details added successfully"
              else
                 redirect_to edit_admin_seller_path(@seller)
                 flash[:success] = "Seller Details added successfully"
              end
          else
              render :new
          end
        end
      end

      def edit
        @render_breadcrumb = breadcrumb_path({:sellers => admin_sellers_path, :disable => "Edit"})
      end

      def import_stock
        @sellers = Spree::Seller.where(:is_active => true)
      end

      def show
         @orders = @seller.orders.where("email!=?", 'spree@example.com').order("spree_orders.created_at DESC")
         @orders = @orders.page(params[:page]).per(10)
         @products = @seller.products.approved.page(params[:page]).per(10)
      end

      def update
        @seller = Seller.find(params[:id])
        file_ext = [".jpg", ".png", ".gif", ".bmp", ".tiff"]
        if params[:seller][:logo].present? && params[:seller][:banner].present?
           if !file_ext.include?(File.extname(params[:seller][:logo].original_filename))
              redirect_to edit_admin_seller_path(@seller.id)
              flash[:error] = "Please upload valid image file for logo"
              return
           else
             if !file_ext.include?(File.extname(params[:seller][:banner].original_filename))
                redirect_to edit_admin_seller_path(@seller.id)
                flash[:error] = "Please upload valid image file for banner"
                return
             else
                if @seller.update_attributes(params[:seller])
                 if @seller.seller_users.present?
                    redirect_to admin_sellers_path
                    flash[:success] = "Seller Details updated successfully"
                 else
                    redirect_to new_admin_seller_seller_user_path(@seller)
                    flash[:success] = "Seller Details updated successfully"
                 end
               else
                    render "edit"
               end
             end
           end
        elsif params[:seller][:logo].present? && !params[:seller][:banner].present?
           if !file_ext.include?(File.extname(params[:seller][:logo].original_filename))
              redirect_to edit_admin_seller_path(@seller.id)
              flash[:error] = "Please upload valid image file for logo"
              return
           else
              if @seller.update_attributes(params[:seller])
                 if @seller.seller_users.present?
                    redirect_to admin_sellers_path
                    flash[:success] = "Seller Details updated successfully"
                 else
                    redirect_to new_admin_seller_seller_user_path(@seller)
                    flash[:success] = "Seller Details updated successfully"
                 end
               else
                    render "edit"
               end
           end
        elsif !params[:seller][:logo].present? && params[:seller][:banner].present?
           if !file_ext.include?(File.extname(params[:seller][:banner].original_filename))
              redirect_to edit_admin_seller_path(@seller.id)
              flash[:error] = "Please upload valid image file for banner"
              return
           else
              if @seller.update_attributes(params[:seller])
                 if @seller.seller_users.present?
                    redirect_to admin_sellers_path
                    flash[:success] = "Seller Details updated successfully"
                 else
                    redirect_to new_admin_seller_seller_user_path(@seller)
                    flash[:success] = "Seller Details updated successfully"
                 end
               else
                    render "edit"
               end
           end
        elsif !params[:seller][:logo].present? && !params[:seller][:banner].present?
          if @seller.update_attributes(params[:seller])
             if @seller.seller_users.present?
                redirect_to admin_sellers_path
                flash[:success] = "Seller Details updated successfully"
             else
                redirect_to new_admin_seller_seller_user_path(@seller)
                flash[:success] = "Seller Details updated successfully"
             end
          else
                render "edit"
          end
        end
      end

      def destroy
        @seller = Seller.find(params[:id])
        @seller.destroy
        redirect_to admin_sellers_path
        flash[:success] = "Seller deleted successfully"
      end

      def active
       @seller = Seller.find(params[:id])
        if @seller.is_completed?
          if @seller.update_attributes({:is_active => true, :deleted_at => nil, :deactivated_at => nil, :comment => nil})
              redirect_to admin_sellers_path
              flash[:success] = "Seller has been activated"
          else
              redirect_to admin_sellers_path
              flash[:error] = "Ooops!! Something wrong!"
          end
        else
             redirect_to admin_sellers_path
             flash[:error] = "Seller registration is not complete, please complete all the required informations"
        end
      end

      def deactive
       @seller = Seller.find(params[:id])
        if request.xhr?
           respond_to :js
        end
      end

      def deactivated
        @seller = Seller.find(params[:id])
        if @seller.update_attributes(params[:seller])
           @seller.products.update_all({:is_approved => false})
            redirect_to admin_sellers_path
            flash[:success] = "Seller has been de-activated"
        else
            redirect_to admin_sellers_path
            flash[:error] = "Ooops!! Something wrong!"
        end
      end

      def destroy
        @seller = Seller.find(params[:id])
        if @seller.update_attributes({:is_active => false, :deleted_at => Time.now, :deactivated_at => Time.now})
           @seller.products.update_all({:is_approved => false, :deleted_at => Time.now, :is_reject => false})
            redirect_to admin_sellers_path
            flash[:success] = "Seller has been deleted"
        else
            redirect_to admin_sellers_path
            flash[:error] = "Ooops!! Something wrong!"
        end
      end

      def add_warehouse_sale
        params[:products].each do |pr|
          product = Spree::Product.find(pr[1].first);
          product.update_attributes({:id => pr[1].first,:is_warehouse => pr[1].second, :special_price => pr[1].last})
        end if params[:products].present?
        flash[:error] = "Products are added into ware house sale"
        redirect_to admin_products_path
      end

      def list_product
        if (defined? params[:market][:place_id])
          @selected_mp_ids = params[:market][:place_id]
        else
          flash[:error] = "Please choose at least one Market Place"
          redirect_to admin_products_path
          return
        end

        if spree_current_user.has_spree_role? 'admin'
          @seller = Spree::Seller.find(params[:seller_id_list])
        else
          @seller = spree_current_user.seller
        end

        @product_not_found = []
        @list_product_exist_error = []
        @market_place = []
        @api_response = []
        error_hash = []
        excel_row = ""
        @resp = ""

        @product_skus = params[:product_skus].to_s.split(',') if params[:product_skus].present?
        @product_skus.each_with_index do |pk, index|
          @variant = Spree::Variant.find_by_sku(pk)
          if @variant.present?
            @product = @variant.product
            @product_variants = @product.variants
            @selected_mp_ids.each do |mpc|
              if @product.present? && @product_variants.present?
                # code for product with variant creation
                @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", @seller.id, @product.id, mpc)
                if @sellers_market_places_product.present?
                  @list_product_exist_error << "Product is already listed"
                  @product_not_found << ""
                  @api_response << ""
                  @market_place << @sellers_market_places_product.first.market_place.name
                  error_hash << pk if !error_hash.include?(pk)
                  next
                end
                if @sellers_market_places_product.blank? || (!@sellers_market_places_product.blank? && @sellers_market_places_product.first.market_place_product_code.nil?)
                  # mapped market place to product
                  @sellers_market_places_product = Spree::SellersMarketPlacesProduct.create(:seller_id=> @seller.id, :market_place_id=> mpc, :product_id=> @product.id)
                  @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, @variant.id)
                  # check stock for product
                  if !@stock_product.present?
                    # added stock for product
                    @stock_product = Spree::StockProduct.create(:sellers_market_places_product_id => @sellers_market_places_product.id, :variant_id => @variant.id, :count_on_hand => 0, :virtual_out_of_stock => false)
                  end
                  sellers_market_places_product = @sellers_market_places_product
                  if sellers_market_places_product.present?
                    case sellers_market_places_product.market_place.code
                    # check code for qoo10
                    when "qoo10"
                      # call listing api for qoo10
                      @resp = listing_products_qoo10(@product, sellers_market_places_product)
                    when "lazada"
                      # call listing api for lazada
                      @resp = view_context.listing_products_lazada(@product, sellers_market_places_product, option_name=nil, option_value=nil, variant_price=nil, variant_selling_price=nil, quantity=nil, variant_sku=nil)
                    end
                      if @resp != true
                        @api_response << sellers_market_places_product.market_place.name+ ": " + @resp
                        @market_place << sellers_market_places_product.market_place.name
                         error_hash << pk if !error_hash.include?(pk)
                         @product_not_found << ""
                         @list_product_exist_error << ""
                         @market_place << ""
                         # remove mapping of sellers_market_places_product and stock
                         sellers_market_places_product.delete
                         @stock_product.delete
                       else
                         @resp = ""
                         @product_variants.each do |pv|
                            # refreshing the object
                            sellers_market_places_product.reload
                            # code for variant creation
                            @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", sellers_market_places_product.id, pv.id)
                            # check stock for product
                            if !@stock_product.present?
                              # added stock for product
                              @stock_product = Spree::StockProduct.create(:sellers_market_places_product_id => sellers_market_places_product.id, :variant_id => pv.id, :count_on_hand => 0, :virtual_out_of_stock => false)
                            end
                            user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", sellers_market_places_product.seller_id, sellers_market_places_product.market_place_id)
                            option_name = pv.option_values.first.option_type.presentation
                            option_value = pv.option_values.first.presentation
                            product_selling_price = pv.product.selling_price.present? ? pv.product.selling_price : pv.product.price
                            variant_selling_price = pv.selling_price
                            price = variant_selling_price.to_f - product_selling_price.to_f
                            quantity = @stock_product.present? ? @stock_product.count_on_hand.to_i : 0
                            if sellers_market_places_product.present?
                              case sellers_market_places_product.market_place.code
                              # check code for qoo10
                              when "qoo10"
                                # call variant listing api for qoo10
                                @resp = product_variant_add_qoo10(sellers_market_places_product, user_market_place, option_name, option_value, price, quantity)
                              when "lazada"
                                variant_price = pv.price
                                #variant_selling_price = pv.selling_price
                                variant_selling_price = pv.special_price.to_f
                                variant_sku = pv.sku
                                # code to insert variant entry whenever failed to list the variants on lazada
                                @sync_maket_place_variant = SyncMarketPlaceVariant.create(:seller_id => sellers_market_places_product.seller_id, :market_place_id => sellers_market_places_product.market_place_id, :product_id => sellers_market_places_product.product_id, :variant_id => pv.id, :variant_sku => variant_sku)
                                #@resp = listing_products_lazada(@product, sellers_market_places_product, option_name, option_value, variant_price, variant_selling_price, quantity, variant_sku)
                                @resp = true
                              end
                                if @resp != true
                                  @api_response << sellers_market_places_product.market_place.name+ ": " + @resp
                                  @market_place << sellers_market_places_product.market_place.name
                                  error_hash << pk if !error_hash.include?(pk)
                                  @product_not_found << ""
                                  @list_product_exist_error << ""
                                  @market_place << ""
                                else
                                  @resp = ""
                                end
                            end # end of product variant loop
                          end # end of success response of
                      end # end of seller market place product condition inner
                    end # end of seller market place product condition outer
                  end # end of market place loop
                elsif @product.present? && !@product_variants.present?
                  # code for only product creation
                  @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", @seller.id, @product.id, mpc)
                  if @sellers_market_places_product.present?
                     @list_product_exist_error << "Product is already listed"
                     @product_not_found << ""
                     @api_response << ""
                     @market_place << @sellers_market_places_product.first.market_place.name
                     error_hash << pk if !error_hash.include?(pk)
                     next
                  end
                  if @sellers_market_places_product.blank? || (!@sellers_market_places_product.blank? && @sellers_market_places_product.first.market_place_product_code.nil?)
                    # mapped market place to product
                    @sellers_market_places_product = Spree::SellersMarketPlacesProduct.create(:seller_id=> @seller.id, :market_place_id=> mpc, :product_id=> @product.id)
                    @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, @variant.id)
                    # check stock for product
                    if !@stock_product.present?
                        # added stock for product
                        @stock_product = Spree::StockProduct.create(:sellers_market_places_product_id => @sellers_market_places_product.id, :variant_id => @variant.id, :count_on_hand => 0, :virtual_out_of_stock => false)
                    end
                    sellers_market_places_product = @sellers_market_places_product
                    if sellers_market_places_product.present?
                      case sellers_market_places_product.market_place.code
                      # check code for qoo10
                      when "qoo10"
                        # call listing api for qoo10
                        @resp = listing_products_qoo10(@product, sellers_market_places_product)
                      when "lazada"
                        # call listing api for lazada
                        @resp = view_context.listing_products_lazada(@product, sellers_market_places_product, option_name=nil, option_value=nil, variant_price=nil, variant_selling_price=nil, quantity=nil, variant_sku=nil)
                      end
                        if @resp != true
                          @api_response << sellers_market_places_product.market_place.name+ ": " + @resp
                          @market_place << sellers_market_places_product.market_place.name
                          error_hash << pk if !error_hash.include?(pk)
                          @product_not_found << ""
                          @list_product_exist_error << ""
                          @market_place << ""
                          # remove mapping of sellers_market_places_product and stock
                          sellers_market_places_product.delete
                          @stock_product.delete
                         else
                            @resp = ""
                         end
                      end
                    end
                  end
              end
           else
              @product_not_found << "No product with this SKU"
              @list_product_exist_error << ""
              @market_place << ""
              @api_response << ""
              error_hash << pk if !error_hash.include?(pk)
              next
           end

       end

        if error_hash.present? && error_hash.size > 0
           listing_products_errors(error_hash, @api_response, @list_product_exist_error, @product_not_found, @market_place)
        else
           redirect_to admin_products_path, :notice => "Product Listed Successfully!"
           return
        end
      end

      def listing_products_errors(error_hash, api_response, list_product_exist_error, product_not_found, market_place)
        errors = Spreadsheet::Workbook.new
        error = errors.create_worksheet :name => 'listing_errors'
        error.row(0).push "#", "Product SKU", "Availability Error", "Already Present Error", "API Errors", "Market Place"
        error_hash.each_with_index do |err, index|
          err.to_s.split(",").each do |r|
            next unless r.present?
              error.row(index+1).push index+1, err, product_not_found.length > 0 ? product_not_found.fetch(index) : "", list_product_exist_error.length > 0 ? list_product_exist_error.fetch(index) : "", (api_response.present? && api_response.length > 0) ? api_response.fetch(index) : "", (market_place.present? && market_place.length > 0) ? market_place.fetch(index) : ""
          end
        end
        blob = StringIO.new("")
        errors.write blob
        # respond with blob object as a file
        send_data blob.string, :type => :xls, :filename => "listing_products_errors.xls"
        return
      end

      def upload_product
        if params[:xls] == 'xls'
           seller_market_place_products = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=?", params[:seller_id_export], params[:market_place_id])
           if seller_market_place_products.present?
             export_to_excel(seller_market_place_products)
           else
             flash[:error] = "No product found!"
             redirect_to admin_products_path
           end
           return
        else
          unless File.extname(params[:attachment].original_filename) == ".zip"
             flash[:error] = "Please upload a valid zip file"
             redirect_to admin_products_path
             return
          end

          # logic for mapping of product to sellers to market places while bulk import
          if (defined? params[:market][:place_id])
            @selected_mp_ids = params[:market][:place_id]
          end

          tmp = params[:attachment].tempfile
          filename =  params[:attachment].original_filename.gsub('.zip','')

          # create a new dir in tmp if not exist
          create_import_data_dir("#{DATASHIFT_PATH}")

          file = File.join("#{DATASHIFT_PATH}", params[:attachment].original_filename)
          FileUtils.cp tmp.path, file

          unless extract(tmp.path)
            flash[:error] = "Ooops!! Something wrong!"
            redirect_to :action => :index
            return
          end

        if FileTest.exists?("#{DATASHIFT_PATH}/#{filename}/product_import_with_images.xls")
          products = Spreadsheet.open "#{DATASHIFT_PATH}/#{filename}/product_import_with_images.xls"
          if spree_current_user.has_spree_role? 'admin'
            @seller = Spree::Seller.find(params[:seller_id])
          else
            @seller = spree_current_user.seller
          end
          if @seller.stock_locations.blank?
            stock_location = @seller.stock_locations.build(
              :admin_name => @seller.name,
              :name => @seller.name,
              :address1 => @seller.address_1,
              :address2 => @seller.try(:address_2),
              :city => @seller.city,
              :state_name => @seller.state,
              :country_id => @seller.country_id,
              :phone => @seller.try(:phone),
              :zipcode => @seller.try(:zip),
              :active => true,
              :email => @seller.contact_person_email,
              :pickup_at => true,
              :backorderable_default => true,
              :propagate_all_variants => true,
              :operating_hours => "10 AM to 06 PM",
              :is_warehouse => true
              )
            stock_location.save!
            stock_location.try(:update_lat_lng)
          end
          product_sheet = products.worksheet(0)
          file_path = "#{DATASHIFT_PATH}/#{filename}/images/"

          # Product and Variant format for listing

          # row[00] => Index No / Sr.No
          # row[01] => Name*
          # row[02] => SKU*
          # row[03] => Available Date
          # row[04] => Description*
          # row[05] => Cost Price
          # row[06] => Retail Price*
          # row[07] => Selling Price [New field 'Selling Price' added]
          # row[08] => Special Price
          # row[09] => Image 1*
          # row[10] => Image 2
          # row[11] => Brand / Manufaturer
          # row[12] => Quantity*
          # row[13] => Main Category*
          # row[14] => Sub Category
          # row[15] => Sub Sub Category
          # row[16] => Adult*
          # row[17] => Tax Category
          # row[18] => Meta Key
          # row[19] => Meta Description
          # row[20] => New Arrival
          # row[21] => Featured
          # row[22] => Option Type* [In case of variant]
          # row[23] => Option Value* [In case of variant]
          # row[24] => Property [We can add as many columns for properties]

          error_hash = []
          product_sheet.each_with_index do |row, index|
            row[100] = ""
            @product_exist_error = ""
            @product = Spree::Product.find_by_name(row[1].to_s)
            @variant = Spree::Variant.find_by_sku(row[2].to_s)
             if @product.present?
                if (@product.present? || @variant.present?) && @product.seller.id != @seller.id
                      @product_exist_error = @product.name + " is already exist for " + @product.seller.name + " seller"
                      row[100] += ",25"
                      error_hash << row
                      next
                end
            end

            if !row[13].nil?
               main_cat = @seller.categories.find_by_name(row[13].to_s)
            end
            option_type = false
            option_value = false
            if !row[22].nil?
                @option_types = Spree::OptionType.where(:presentation => row[22].to_s) unless row[22].nil?
                option_type = true
            end
            if !row[23].nil?
                @option_values = Spree::OptionValue.where(:presentation => row[23].to_s) unless row[23].nil?
                option_value = true
            end

            if option_type == true || option_value == true
                if index == 0 || row[1].nil? || row[2].nil? || row[4].nil? || row[6].nil? || main_cat.nil? || @option_types.blank? || @option_values.blank?
                  row[100] += "1" if row[1].nil?
                  row[100] += ",2" if row[2].nil?
                  row[100] += ",4" if row[4].nil?
                  row[100] += ",6" if row[6].nil?
                  row[100] += ",13" if main_cat.nil?
                  row[100] += ",22" if @option_types.blank?
                  row[100] += ",23" if @option_values.blank?
                  error_hash << row
                  next
                end
            elsif option_type == false || option_value == false
                 if index == 0 || row[1].nil? || row[2].nil? || row[4].nil? || row[6].nil? || main_cat.nil?
                  row[100] += "1" if row[1].nil?
                  row[100] += ",2" if row[2].nil?
                  row[100] += ",4" if row[4].nil?
                  row[100] += ",6" if row[6].nil?
                  row[100] += ",13" if main_cat.nil?
                  error_hash << row
                  next
                end
            end

            stock = {"quantity"=> row[12].nil? ? 0 : row[12]}
            @stock = row[12].nil? ? 0 : row[12]
            @is_variant = false
            stock_location = @seller.stock_locations.first
            stock_movement = stock_location.stock_movements.build(stock)
            if @product.nil? || (@product.present? && @variant.try(:is_master))
              product_hash = {
                :name => row[1],
                :sku => row[2],
                :available_on => row[3].nil? ? Time.now.to_date : row[3].to_date,
                :description => row[4],
                :cost_price => row[5],
                :price => row[6].to_f,
                :selling_price => row[7],
                :special_price => row[8],
                :created_by => spree_current_user.id,
                :updated_by => spree_current_user.id,
                :is_approved => 1,
                :brand_id => row[11].nil? ? '' : Spree::Brand.find_by_name(row[11]).try(:id),
                :is_adult => row[16].to_s.downcase,
                :tax_category_id => row[17].nil? ? '' : Spree::TaxCategory.find_by_name(row[17]).try(:id),
                :meta_keywords => row[18],
                :meta_description => row[19],
                :is_new_arrival => row[20].to_s.downcase,
                :is_featured => row[21].to_s.downcase,
                :shipping_category_id => Spree::ShippingCategory.general.nil? ? Spree::ShippingCategory.first.try(:id) : Spree::ShippingCategory.general.try(:id)
              }

              if @product.present?
                @product.update_attributes(product_hash)
                if row[13].nil? && row[14].nil?
                  row[100] += ",13,14"
                  error_hash << row
                  next
                end
              else
                @product = @seller.products.build(product_hash)
              end
              @product.save!
              excel_update_rcp(@product.master)
              @product.option_types.destroy_all if @product.option_types.present?
              @product.product_properties.destroy_all if @product.product_properties.present?
              # update & upload category to product
              @product.taxons.destroy_all if @product.taxons.present?
                main_cat = @seller.categories.find_by_name(row[13].to_s)
                sub_cat = nil
                sub_cat = main_cat.children.find_by_name(row[14].to_s) if main_cat.present?
                sub_sub_cat = nil
                sub_sub_cat = sub_cat.children.find_by_name(row[15].to_s) if sub_cat.present?
                if sub_sub_cat.nil?
                  if sub_cat.nil?
                    @product.taxons << main_cat
                  else
                    @product.taxons << sub_cat
                  end
                else
                  if sub_cat.nil?
                    @product.taxons << main_cat
                  else
                    @product.taxons << sub_sub_cat
                  end
                end
                @product.option_types << Spree::OptionType.where(:presentation => row[22].to_s) unless row[22].nil?
                @product.product_properties << Spree::Property.find_by_presentation("Brand").product_properties.build(:value => row[11]) if row[11].present? && Spree::Property.find_by_presentation("Brand").present?
                stock_movement.stock_item = stock_location.set_up_stock_item(@product.master)
                @variant = @product.master
                @variant.option_values.destroy_all if @variant.option_values.present?
                @variant.option_values << Spree::OptionValue.where(:presentation => row[23].to_s) unless row[23].nil?
                property_id = 24
                while product_sheet.first[property_id].present?
                  @product.product_properties << Spree::Property.find_by_presentation(product_sheet.first[property_id]).product_properties.build(:value => row[property_id]) if Spree::Property.find_by_presentation(product_sheet.first[property_id]).present? && row[property_id].present?
                  property_id += 1
                end
                else
                  if @product.option_types.blank?
                     @product.option_types << @option_types
                  end
                  next if @product.option_types.blank?
                  var_hash = {
                    :sku => row[2],
                    :cost_price => row[5],
                    :price => row[6],
                    :selling_price => row[7],
                    :special_price => row[8]
                  }
                  if @variant.nil?
                     @variant = @product.variants.build(var_hash)
                  else
                     @variant.update_attributes(var_hash)
                  end
                  @variant.save!
                  @variant.option_values.destroy_all if @variant.option_values.present?
                  @variant.option_values << Spree::OptionValue.where(:presentation => row[23].to_s) unless row[23].nil?
                  stock_movement.stock_item = stock_location.set_up_stock_item(@variant)
                  excel_update_rcp(@variant)
                  @is_variant = true
                end
                stock_movement.save!
                image1 = nil
                image2 = nil
                image_error = false
                 if FileTest.exists?("#{file_path}#{row[9]}")
                  image1 = Spree::Image.create!({:attachment => open("#{file_path}#{row[9]}"), :viewable => @variant}, :without_protection => true) unless row[9].nil?
                else
                  image_error = true
                  row[100] += ",9"
                end
                if FileTest.exists?("#{file_path}#{row[10]}")
                  image2 = Spree::Image.create!({:attachment => open("#{file_path}#{row[10]}"), :viewable => @variant}, :without_protection => true) unless row[10].nil?
                else
                  image_error = true
                  row[100] += ",10"
                end
                error_hash << row if image_error
                @variant.images << image1 unless image1.nil?
                @variant.images << image2 unless image2.nil?

                #Logic for mapping of product to sellers to market places while bulk import
                if @selected_mp_ids.present?
                @selected_mp_ids.each do |mpc|
                  @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", params[:seller_id], @product.id, mpc)
                  if !@is_variant && @sellers_market_places_product.blank? || (!@sellers_market_places_product.blank? && @sellers_market_places_product.first.market_place_product_code.nil?)
                     @sellers_market_places_product = Spree::SellersMarketPlacesProduct.create(:seller_id=>params[:seller_id], :market_place_id=>mpc, :product_id=>@product.id)
                      @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, @variant.id)
                      if @stock_product.present?
                        old_stock_count = @stock_product.count_on_hand
                        new_stock_count = @stock.to_i
                        total_stock_count = old_stock_count.to_i + new_stock_count.to_i
                        @stock_product.update_attributes(:count_on_hand => total_stock_count)
                      else
                        @stock_product = Spree::StockProduct.create(:sellers_market_places_product_id => @sellers_market_places_product.id, :variant_id => @variant.id, :count_on_hand => @stock.to_i, :virtual_out_of_stock => false)
                      end
                    sellers_market_places_product = @sellers_market_places_product
                    if sellers_market_places_product.present?
                      case sellers_market_places_product.market_place.code
                      when "qoo10"
                        @res = listing_products_qoo10(@product, sellers_market_places_product)
                      when "lazada"
                        quantity = !@product.stock_products.blank? ? @product.stock_products.where(:sellers_market_places_product_id=>sellers_market_places_product.id).sum(&:count_on_hand) : 0
                        @res = view_context.listing_products_lazada(@product, sellers_market_places_product, option_name=nil, option_value=nil, variant_price=nil, variant_selling_price=nil, quantity, variant_sku=nil)
                      end
                      if @res != true
                        @res = sellers_market_places_product.market_place.name + ": " + @res
                        row[100] += ",24"
                        error_hash << row if !error_hash.include?(row)
                      else
                        @res = ""
                      end
                    end
                  elsif @is_variant
                    @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.first.id, @variant.id)
                    if @stock_product.present?
                      old_stock_count = @stock_product.count_on_hand
                      new_stock_count = @stock.to_i
                      total_stock_count = old_stock_count.to_i + new_stock_count.to_i
                      @stock_product.update_attributes(:count_on_hand => total_stock_count)
                    else
                      @stock_product = Spree::StockProduct.create(:sellers_market_places_product_id => @sellers_market_places_product.first.id, :variant_id => @variant.id, :count_on_hand => @stock.to_i, :virtual_out_of_stock => false)
                    end
                    # Added logic to detect master variant & delete their stock after adding the variants
                    if @product.variants.present?
                      @product.stock_products.each do |sp|
                      @is_master_variant = sp.variant.is_master?
                      if @is_master_variant
                        if sp.present? && @sellers_market_places_product.present?
                          sp.update_attributes(:count_on_hand => 0)
                        end
                      end
                    end
                  end
                  sellers_market_places_product = @sellers_market_places_product.first if @sellers_market_places_product.present?
                  user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", sellers_market_places_product.seller_id, sellers_market_places_product.market_place_id)
                  option_name = @variant.option_values.first.option_type.presentation
                  option_value = @variant.option_values.first.presentation
                  product_price = @variant.product.price
                  variant_price = @variant.price
                  product_selling_price = @variant.product.selling_price.present? ? @variant.product.selling_price : @variant.product.price
                  variant_selling_price = @variant.selling_price
                  quantity = @stock_product.present? ? @stock_product.count_on_hand.to_i : 0
                  variant_sku = @variant.sku
                  if sellers_market_places_product.present?
                    case sellers_market_places_product.market_place.code
                    when "qoo10"
                      price = variant_selling_price.to_f - product_selling_price.to_f
                      @res = product_variant_add_qoo10(sellers_market_places_product, user_market_place, option_name, option_value, price, quantity)
                    when "lazada"
                      # code to insert variant entry whenever failed to list the variants on lazada
                      @sync_maket_place_variant = SyncMarketPlaceVariant.create(:seller_id => sellers_market_places_product.seller_id, :market_place_id => sellers_market_places_product.market_place_id, :product_id => sellers_market_places_product.product_id, :variant_id => @variant.id, :variant_sku => variant_sku)
                      #@res = listing_products_lazada(@product, sellers_market_places_product, option_name, option_value, variant_price, variant_selling_price, quantity, variant_sku)
                      @res = true
                    end
                    if @res != true
                      @res = sellers_market_places_product.market_place.name + ": " + @res
                      row[100] += ",24"
                      error_hash << row if !error_hash.include?(row)
                    else
                      @res = ""
                    end
                  end
                end
               end
              end
            end
            FileUtils.rm_rf("#{DATASHIFT_PATH}/#{filename}/.", secure: true)
            if error_hash.present? && error_hash.size >=2
              products_errors(error_hash, @res, @product_exist_error)
            else
              redirect_to admin_products_path, :notice => "Product Uploaded Successfully!"
              return
            end
          else
            flash[:error] = "Ooops..Excel file with name product_import_with_images.xls not found"
            redirect_to admin_products_path
            return
          end
        end
      end

      # Listing of products through excel on qoo10
      def listing_products_qoo10(product, sellers_market_places_product)
        @error_message = ""
        begin
            @sellers_market_places_product = sellers_market_places_product
            @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @sellers_market_places_product.seller_id, @sellers_market_places_product.market_place_id, product.id)
            @taxon_market_plcaes = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", product.taxons.first.id, @sellers_market_places_product.market_place_id) if product.taxons.present?
            if @taxon_market_plcaes && !@taxon_market_plcaes.blank?
              if !@market_place_product.blank? && !@market_place_product.first.market_place_product_code.present? && !@taxon_market_plcaes.blank?
                adult = product.is_adult ? 'Y' : 'N'
                item_title = product.name
                image_url = ""
                if !product.variant_images.nil? && !product.variant_images.blank?
                  size = 0
                  product.variant_images.each do |mg|
                    if mg.attachment_file_name.split("_").first.capitalize == "qoo10".capitalize && size < mg.attachment_file_size
                      image_url = mg.attachment.url(:original)
                      size = mg.attachment_file_size
                    end
                  end
                end
                image_url = image_url.present? ? image_url : (request.host.to_s+":"+request.port.to_s+"/assets/noimage/large.png")
                item_description = product.description
                @item_type = ""
                product.variants.each do |v|
                  @item_type = @item_type + v.option_values.first.option_type.name + "||*"
                  @item_type = @item_type + v.option_values.first.name + "||*" + (v.cost_price.nil? ? v.prices.first.amount : v.cost_price).to_s + "||*"
                  @item_type = @item_type + v.count_on_hand.to_s + "||*"+(v.sku.present? ? v.sku.to_s : "0")
                  @item_type = @item_type + ((v == product.variants.last) ? "" : "$$")  #@object <= product
                end if product.variants.present?
                item_type = @item_type #'Color/Size||*White/100||*1000||*10||*0$$Color/Size||*Black/100||*1000||*10||*0'
                retail_price = product.price.to_f
                item_price = product.selling_price.present? ? product.selling_price.to_f : product.price.to_f
                item_quantity = !product.stock_products.blank? ? product.stock_products.where(:sellers_market_places_product_id=>@sellers_market_places_product.id).sum(&:count_on_hand) : 0
                expiry_date = (Time.now + 1.year).strftime("%Y-%m-%d")
                user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", @sellers_market_places_product.seller_id, @sellers_market_places_product.market_place_id)
                seller_code = sellers_market_places_product.product.sku.present? ? sellers_market_places_product.product.sku : "" rescue ""
                if !user_market_place.blank? && !user_market_place.first.api_secret_key.nil?
                  shipping_no = user_market_place.first.shipping_code.to_s #"418422" # '0' :=> 'Free Shiping', '400896' :=> 'Free on condition' where '400896' is SR code of Qoo10 backend for Others, '418422' :=> 'Free on condition' where '418422' is SR code of Qoo10 backend for Qxpress.
                  uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/SetNewGoods')
                  req = Net::HTTP::Post.new(uri.path)
                  req.set_form_data({'key'=>user_market_place.first.api_secret_key.to_s,'SecondSubCat'=>@taxon_market_plcaes.first.market_place_category_id.to_s,'ManufactureNo'=>'','BrandNo'=>'','ItemTitle'=>item_title.to_s,'SellerCode'=>seller_code.to_s,'IndustrialCode'=>'','ProductionPlace'=>'','AudultYN'=>adult.to_s,'ContactTel'=>'','StandardImage'=>image_url.to_s,'ItemDescription'=>item_description.to_s,'AdditionalOption'=>'','ItemType'=>item_type.to_s,'RetailPrice'=>retail_price.to_s,'ItemPrice'=>item_price.to_s,'ItemQty'=>item_quantity.to_s,'ExpireDate'=>expiry_date.to_s,'ShippingNo'=>shipping_no.to_s,'AvailableDateType'=>'','AvailableDateValue'=>''})
                  res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
                  if res.code == "200"
                    res_body = Hash.from_xml(res.body).to_json
                    res_body = JSON.parse(res_body, :symbolize_names=>true)
                    mp_product_code = res_body[:StdCustomResultOfGoodsResultModel][:ResultObject][:GdNo]
                    if mp_product_code.nil?
                      @error_message = res_body[:StdCustomResultOfGoodsResultModel][:ResultMsg]
                    else
                      @market_place_product.first.update_attributes(:market_place_product_code=>mp_product_code) if !@market_place_product.blank?
                    end
                  else
                    @error_message = res.message
                  end
                else
                  @error_message = "Api key or Secret key is missing"
                end
              end
            else
              @error_message = "Please map market place category to list product."
            end
         rescue Exception => e
           @error_message << e.message
         end
        return @error_message && @error_message.length > 0 ? @error_message : true
      end

      # Listing of products variants through excel on qoo10
      def product_variant_add_qoo10(market_place_product, user_market_place, option_name, option_value, price, quantity)
         @error_message = ""
         begin
           seller_code = market_place_product.product.sku.present? ? market_place_product.product.sku : "" rescue ""
            uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/GoodsBasicService.api/InsertInventoryDataUnit')
            req = Net::HTTP::Post.new(uri.path)
            req.set_form_data({'key'=>user_market_place.first.api_secret_key.to_s,'ItemCode'=>market_place_product.market_place_product_code,'SellerCode'=>seller_code.to_s,'OptionName'=>option_name,'OptionValue'=>option_value,'OptionCode'=>'','Price'=>price.to_s,'Qty'=>quantity.to_s})
            res = Net::HTTP.start(uri.hostname, uri.port) do |http| http.request(req) end
             if res.code != "200"
               @error_message << res.message
             end
         rescue Exception => e
           @error_message << e.message
         end
         return @error_message && @error_message.length > 0 ? @error_message : true
      end

      # Change stock setting from seller setting
      def manage_stock_settings
        smp = Spree::SellerMarketPlace.find(params[:seller_market_place_stock_config_details].keys.first)
        seller = smp.seller
        seller.update_attributes(:stock_config_type => STOCKCONFIG.key(params[:seller][:stock_config_type]).to_i)
        if !params["apply_to_all"].nil? && params["apply_to_all"] == "true"
          inf_variant_ids = Spree::QuantityInflation.pluck(:variant_id)
          var_ids = Spree::Variant.where(:id=>inf_variant_ids).pluck(:product_id)
          # products = inf_variant_ids.present? ? (seller.products.where("is_approved=true AND kit_id IS NULL").where("id NOT IN (?)", var_ids)) : (seller.products.where("is_approved=true AND kit_id IS NULL"))
          products = inf_variant_ids.present? ? (seller.products.where("is_approved=true").where("id NOT IN (?)", var_ids)) : (seller.products.where("is_approved=true"))
          products.each do |product|
            product.update_column(:stock_config_type, 0)
          end 
        end
         
        if params[:seller][:stock_config_type] == "percentage_quantity"
          params[:seller_market_place_stock_config_details].each do |key, value|
            smp = Spree::SellerMarketPlace.find(key)
            smp.update_attributes(:stock_config_details=>value)
            if !params["apply_to_all"].nil? && params["apply_to_all"] == "true"
              smpps = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=?", smp.seller_id, smp.market_place_id)
              smpps.update_all(:stock_config_details=>value)
            end
          end
        end
        res = view_context.update_stock_for_seller(seller, false)
        if res == "fail"
          redirect_to admin_seller_seller_market_places_path(seller.id), :error => "Stock can not be updated properly"
        else
          redirect_to admin_seller_seller_market_places_path(seller.id), :notice => "Stock setting updated seccessfully"
        end
      end

      # stock setting page method
      def stock_setting
        @seller = Spree::Seller.find(params[:id])
      end

    protected

      def extract(zip_file)
        begin
          Archive::Zip.extract(zip_file, DATASHIFT_PATH, :symlinks => false, :directories => false)
          return true
        rescue Exception => e
          Rails.logger.info "===============================================\n #{e.message}"
          return false
        end
      end

      def create_import_data_dir(directory_name)
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
      end

      def products_errors(error_hash, api_errors, product_exist_error)
        errors = Spreadsheet::Workbook.new
        error = errors.create_worksheet :name => 'errors'
        red = Spreadsheet::Format.new :color => 'black', :size => 10, :align => 'center', :pattern_fg_color => :red, :pattern => 1
        error_hash.each_with_index do |err, index|
          error.row(index).push err[0], err[1], err[2], err[3], err[4], err[5], err[6], err[7], err[8], err[9], err[10], err[11], err[12], err[13], err[14], err[15], err[16], err[17], err[18], err[19], err[20], err[21], err[22], err[23]
          err[100].to_s.split(",").each do |r|
            next unless r.present?
            error.row(index).set_format(r.to_i,red) unless index == 0
            error.row(index).push api_errors if api_errors.present? && api_errors.length > 0 && index != 0
            error.row(index).push product_exist_error if product_exist_error.present? && product_exist_error.length > 0 && index != 0
          end
        end
        blob = StringIO.new("")
        errors.write blob
        #respond with blob object as a file
        send_data blob.string, :type => :xls, :filename => "products_errors.xls"
        return
      end

      def export_to_excel(collection)
        products = Spreadsheet::Workbook.new
        product = products.create_worksheet :name => 'products'
        product.row(0).push "Name", "SKU", "UPC", "Available On", "Description", "Cost Price", "Retail Price", "Selling Price", "Special Price", "Brand", "Quantity", "Category", "Is Adult", "Tax Category", "Meta Keyword", "Meta Description", "New Arrival", "Featured", "Option Type", "Option Value"
        i = 1
        collection.each_with_index do |pr, index|
          if pr.product.present?
              product.row(i).push pr.product.name, pr.product.sku, pr.product.upc, pr.product.available_on.present? ? pr.product.available_on.strftime("%d %b %y") : '', pr.product.description, pr.product.cost_price, pr.product.price, pr.product.selling_price, pr.product.special_price, pr.product.brand.try(:name), pr.product.total_in_hand_stock, pr.product.taxons.collect(&:name).join(","), pr.product.is_adult, pr.product.tax_category.try(:name), pr.product.try(:meta_keywords), pr.product.try(:meta_description), pr.product.is_new_arrival, pr.product.is_featured, pr.product.option_types.map(&:presentation).join(","), ""
              i += 1
              pr.product.variants.each do |variant|
                product.row(i).push '', variant.sku, variant.upc, '', '', variant.cost_price, variant.price, variant.selling_price, variant.special_price, '', variant.stock_products.sum(&:count_on_hand),'', '', '', '', '', '', '', '', variant.option_values.map(&:presentation).join(",")
                i += 1
              end if pr.product.variants.present?
          end
        end if collection.present?
        blob = StringIO.new("")
        products.write blob
        #respond with blob object as a file
        send_data blob.string, :type => :xls, :filename => "products.xls"
        return
      end

      def load_data
        @types = Spree::BusinessType.all
      end

      def excel_update_rcp(variant)
        if variant.product.seller.type.price_based?
          variant.update_attributes(:rcp => variant.cost_price)
        else
          rcp = (variant.special_price || variant.price) * (1 - (variant.product.seller.revenue_share/100.to_f))
          rcp = (variant.special_price || variant.price) * (1 - (variant.product.seller.revenue_share_on_ware_house_sale/100.to_f)) if variant.product.is_warehouse
          variant.update_attributes(:rcp => rcp)
        end if variant.product.seller.type.present?
      end

      def update_rcp
        begin
          if @seller.type.price_based?
            @seller.variants.each{|variant| variant.update_attributes(:rcp => variant.cost_price)}
            @seller.products.each{|product| product.update_attributes(:rcp => product.cost_price)}
          else
            @seller.variants.each do |variant|
              rcp = (variant.special_price || variant.price) * (1 - (@seller.revenue_share/100.to_f))
              rcp = (variant.special_price || variant.price) * (1 - (@seller.revenue_share_on_ware_house_sale/100.to_f)) if variant.product.is_warehouse
              variant.update_attributes(:rcp => rcp)
            end
            @seller.products.each do |product|
              rcp = (product.special_price || product.price) * (1 - (@seller.revenue_share/100.to_f))
              rcp = (product.special_price || product.price) * (1 - (@seller.revenue_share_on_ware_house_sale/100.to_f)) if product.is_warehouse
              product.update_attributes(:rcp => rcp)
            end
          end if @seller.type.present?
        rescue Exception => e
          logger.infoRails.logger.info "===============================================\n #{e.message}"
          #TODO
          #SEND EMAIL TO ADMIN ABOUT ERROR LOG
          flash[:error] = "error --- #{e.message}"
          return false
        end
      end

        private
        def update_params
          if spree_current_user.has_spree_role?("admin")
            params[:seller].merge!(:establishment_date => Time.now()) if params[:seller][:establishment_date].blank?
          end
          return params[:seller]
        end
    end
  end
end
