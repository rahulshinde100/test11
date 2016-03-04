module Spree
  module Admin
    ProductsController.class_eval do
      #after_filter :update_rcp, :only => [:create, :update]
      # Added By Pooja Dudhatra To get product list with SKU for promotion product rule

      def get_products_for_promotion
        if params[:ids]
          @products = product_scope.where(:kit_id=>nil,:id => params[:ids].split(",")).select([:id,:name,:permalink])
        else
            @products = Spree::Product.active.where(:kit_id=>nil).select(['spree_products.name','spree_products.permalink','spree_products.id']).ransack(params[:q]).result


        @products_json = []
        #@products = Spree::Product.active.where(:is_approved=>true, :kit_id=>nil)
        @products.each do |product|
        #  product_variants = []
        #  product_variants << (product.variants.present? ? product.variants : product.master)
        #  product_variants = product_variants.flatten
        #  product_variants.each do |pv|
        #    if !pv.parent_id.present?
        #      if !pv.parent_id.present?
        #        name = (pv.option_values.present? ? (product.name+" -> "+pv.option_values.first.presentation+" ("+pv.sku.to_s+")") : (product.name+" ("+pv.sku.to_s+")"))
               @products_json << product
             end
        #    end
        #  end
        #end if @products.present?
        respond_to do |format|
          format.json { render :json => {:products => @products} }
          # format.json { render :json => {:products => @products_json} }
        end
          end
      end
     # Added by Tejaswi ni Patil.
      # To import data from excel file
      # On 19 Aug 2015
      def import_data
        @seller = Spree::Seller.find(params[:seller_id])
        @message = ""
        @msg = ""
        if params[:action_name] == 'Impozrt Images' && File.extname(params[:attachment].original_filename) != ".zip"
          @message = "Please Upload .zip folder for images"
        elsif params[:action_name] != 'Import Images' && File.extname(params[:attachment].original_filename) != ".xls"
          @message = "Please Upload only excel file"
        elsif @seller.present?
          unless @seller.is_active
            @message = "The seller you have selected is not activated yet"
          end
        end
        unless @message.empty?
          flash[:error] = @message
          redirect_to admin_products_path
          return
        end

        file_path = params[:attachment].path
        name =  params[:attachment].original_filename
        directory = "/tmp/data_import"#{}"#{DATASHIFT_PATH}"

        # create the file path
        path = File.join(directory, name)

        # write the file
        FileUtils.mkdir_p(directory) unless File.directory?(directory)
        File.open(path, "wb") { |f| f.write(params[:attachment].read) }

        action_name = params[:action_name]
        case action_name
        when "Import Products"
          #ImportJob.delay.create_products(@seller, path, spree_current_user)
          ImportJob.create_products(@seller, path, spree_current_user)
        when "Import Variants"
          #ImportJob.delay.create_variants(@seller, path, spree_current_user)
          ImportJob.create_variants(@seller, path, spree_current_user)
        when "Quantity Inflation"
          @market_place = Spree::MarketPlace.find(params[:market_place_id])
          #ImportJob.delay.quantity_inflation(@seller, path, spree_current_user)
          ImportJob.quantity_inflation(@seller, @market_place, path, spree_current_user)  
        when "Import Images"
          # Unzip uploaded zip file
          unless extract(path)
            @msg = "Something went wrong while extracting file"
          end

          # Get path of unziped xsl file and images folder
          img_file_path = path.gsub(".zip","")+"/upload_images.xls"
          images_path = path.gsub(".zip","")+"/images/"
          img_folder = path.gsub(".zip","")

          # To remove first / from path
          img_file_path.slice!(0)
          images_path.slice!(0)
          img_folder.slice!(0)

          unless FileTest.exist?(img_file_path) && FileTest.exist?(images_path)
            @msg = "File with name 'upload_images.xls' Or 'images' folder not found in uploaded .zip file Or Uploaded excel file is empty"
          else
            ImportJob.create_images(@seller, img_file_path, images_path, spree_current_user)
            #ImportJob.delay.create_images(@seller, img_file_path, images_path, spree_current_user)
          end
        else
          @market_place = Spree::MarketPlace.find(params[:market_place_id])
          #ImportJob.delay.update_market_place_details(@seller, @market_place, path, spree_current_user)
          ImportJob.update_market_place_details(@seller, @market_place, path, spree_current_user)
        end
        # Remove tmp created folder
        dir_path = "#{Rails.root}"+"#{directory}"+"/"+"#{(name.gsub('.zip', ''))}"
        FileUtils.remove_dir(dir_path, force: true)
        if @msg.present?
          flash[:notice] = @msg
        else
          flash[:notice] = 'We are processing your data. We will email you final status after processing.'
        end
        redirect_to admin_products_path
      end

      def edit
        @gender = [["Select Gender", "NA"],['Male', 'Male'],['Female','Female'],['Unisex','Unisex'],['Boys','Boys'],['Girls','Girls'],['Unisex-kids','Unisex-kids']]
        respond_with(@object) do |format|
          format.html { render :layout => !request.xhr? }
          if request.xhr?
            format.js   { render :layout => false }
          end
        end
      end

      def update
        @gender = [["Select Gender", "NA"],['Male', 'Male'],['Female','Female'],['Unisex','Unisex'],['Boys','Boys'],['Girls','Girls'],['Unisex-kids','Unisex-kids']]
        old_taxons_ids = @object.taxons.map(&:id)
        old_option_ids = @object.option_types.map(&:id)
        if params[:product][:taxon_ids].present?
          params[:product][:taxon_ids] = params[:product][:taxon_ids].split(',')
        elsif params[:validate_on_taxons].present? #this object comes only when product is update from /product/:product_id/edit
          flash[:error] = "Please Select Taxon"
          render :edit
          return
        end

        if params[:product][:option_type_ids].present?
          params[:product][:option_type_ids] = params[:product][:option_type_ids].split(',')
        end
        if params[:product][:label_ids].present?
          params[:product][:label_ids] = params[:product][:label_ids].split(',')
        end
        invoke_callbacks(:update, :before)
        @old_description = @object.description
        @old_price = @object.price.to_f
        @selling_price = @object.selling_price.to_f
        @old_selling_price = @object.selling_price.to_f
        @old_special_price = @object.special_price.to_f
        if @object.update_attributes(params[:product])
          new_option_types = @object.option_types.map(&:id)
          new_taxon_ids = @object.taxons.map(&:id)
          new_selling_price = @object.selling_price.to_f
          new_special_price = @object.special_price.to_f
          if !(@old_selling_price == new_selling_price)
            if @object.market_places.map(&:code).include? 'qoo10'
              market_place = Spree::MarketPlace.find_by_code('qoo10')
              # desc = ProductJob.get_updated_fields('selling_price',market_place.code)
              desc = 'gp1,uidu1'
              v = @object.master
              v.recent_market_place_changes.create(:product_id => @object.id,:seller_id => @object.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
            end
          end
          # if !(@old_special_price == new_special_price) && @object.variants.present?
          #   if @object.market_places.map(&:code).include? 'qoo10'
          #     market_place = Spree::MarketPlace.find_by_code('qoo10')
          #     # desc = ProductJob.get_updated_fields('selling_price',market_place.code)
          #     desc = 'gp2'
          #     v = @object.master
          #     v.recent_market_place_changes.create(:product_id => @object.id,:seller_id => @object.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
          #   end
          # end
          new_price = @object.price.to_f
          if !(new_price == @old_price)
            variants = (@object.variants.present? ? (@object.variants) : (@object.master))
            market_places = @object.market_places
            if @object.variants.present? &&  (@object.market_places.map(&:code).include? 'qoo10')
              market_place = Spree::MarketPlace.find_by_code('qoo10')
              variants.each do |v|
                # market_places.each do |market_place|

                desc = ProductJob.get_updated_fields('price',market_place.code)
                  v.recent_market_place_changes.create(:product_id => @object.id,:seller_id => @object.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
                # end
              end
            else
              market_places.each do |market_place|
                desc = ProductJob.get_updated_fields('price',market_place.code)
                variants.recent_market_place_changes.create(:product_id => @object.id,:seller_id => @object.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
              end
            end
          end
          if !(old_option_ids == new_option_types)
            variants = (@object.variants.present? ? (@object.variants) : (@object.master))
            market_places = @object.market_places
            if @object.variants.present?
              variants.each do |v|
                market_places.each do |market_place|
                  desc = ProductJob.get_updated_fields('option_type',market_place.code)
                  v.recent_market_place_changes.create(:product_id => @object.id,:seller_id => @object.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
                end
              end
            else
              market_places.each do |market_place|
                desc = ProductJob.get_updated_fields('option_type',market_place.code)
                variants.recent_market_place_changes.create(:product_id => @object.id,:seller_id => @object.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
              end
            end
          end
          if !(old_taxons_ids == new_taxon_ids)
            variants = (@object.variants.present? ? (@object.variants) : (@object.master))
            market_places = @object.market_places
            if @object.variants.present?
              variants.each do |v|
                market_places.each do |market_place|
                  desc = ProductJob.get_updated_fields('category',market_place.code)
                  v.recent_market_place_changes.create(:product_id => @object.id,:seller_id => @object.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
                end
              end
            else
              market_places.each do |market_place|
                desc = ProductJob.get_updated_fields('category',market_place.code)
                variants.recent_market_place_changes.create(:product_id => @object.id,:seller_id => @object.seller.id, :market_place_id => market_place.id, :description => desc, :update_on_fba=>false) if (desc.present? && !desc.blank?)
              end
            end
          end
          @error_message = []
          begin
            invoke_callbacks(:update, :after)

            # Code to update the kit details while kit as a product
            if @object.kit.present?
               @kit = @object.kit
               @kit.update_attributes(:name => @object.name, :sku => @object.sku, :description => @object.description, :is_active => @object.is_approved)
            end

            # Listing products on market places
            # params[:market][:place_id].each do |id|
            #   @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", params[:product][:seller_id], Spree::Product.find_by_permalink(params[:id]).id.to_s, id)
            #   @sellers_market_places_product = Spree::SellersMarketPlacesProduct.create!(:seller_id=>params[:product][:seller_id], :market_place_id=>id, :product_id=>Spree::Product.find_by_permalink(params[:id]).id.to_s) if @sellers_market_places_product.blank?
            #   @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", params[:product][:seller_id], id, @object.id)
            #   market_place =  @market_place_product.first.market_place
            #   @taxon_market_plcaes = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", params[:product][:taxon_ids].first, id) if params[:product][:taxon_ids] && params[:market]
            #   user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", params[:product][:seller_id], id)
            #   if @taxon_market_plcaes && !@taxon_market_plcaes.blank?
            #     # This new product create condition on market place product
            #     if !@market_place_product.blank? && !@market_place_product.first.market_place_product_code.present? && !@taxon_market_plcaes.blank?
            #       if !user_market_place.blank? && !user_market_place.first.api_secret_key.nil?
            #         if market_place.present?
            #           case market_place.code
            #           when "qoo10"
            #             res = view_context.listing_product_qoo10(market_place.id, params, @object, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first)
            #           when "lazada","zalora"
            #             res = view_context.listing_product_lazada(market_place.id, params, @object, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first)
            #           end
            #           @error_message << (res == true ? "" : res)
            #           @market_place_product.first.delete if res != true
            #         end
            #       else
            #         @error_message << @sellers_market_places_product.market_place.name+": Api key or Secret key is missing"
            #       end
            #       # This product update condition on market place product
            #     elsif !@market_place_product.blank? && @market_place_product.first.market_place_product_code.present? && !@taxon_market_plcaes.blank?
            #       if !user_market_place.blank? && !user_market_place.first.api_secret_key.nil?
            #         if market_place.present?
            #           case market_place.code
            #           when "qoo10"
            #             res = view_context.update_product_qoo10(market_place.id, params, @object, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first, @old_description, @old_price, @old_special_price)
            #           when "lazada","zalora"
            #             res = view_context.update_product_lazada(market_place.id, params, @object, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first)
            #           end
            #           @error_message << (res == true ? "" : res)
            #         end
            #       else
            #         @error_message << @sellers_market_places_product.market_place.name+": Api key or Secret key is missing"
            #       end
            #     end
            #   else
            #     @error_message << market_place.name+": Please map market place category to list product."
            #   end
            # end if params[:market] && !params[:market][:place_id].blank?
           rescue Exception => e
               @error_message << e.message
           end
           @error_message = @error_message.compact.reject(&:blank?)
            if @error_message.length > 0
              flash[:error] = @error_message.join("; ")
              render :edit
              return
            end
            flash[:success] = flash_message_for(@object, :successfully_updated)
            respond_with(@object) do |format|
              format.html { redirect_to location_after_save }
              format.js   { render :layout => false }
            end
        else
            invoke_callbacks(:update, :fails)
            if params[:product][:product_properties_attributes].present?
              flash[:error] = "Value for a Property is mandatory, please provide proper information."
              redirect_to admin_product_product_properties_path(@object)
            else
              respond_with(@object)
            end
        end
      end

      def manage_stock
        @market_places = @product.market_places.where("spree_market_places.id IN (?)", @product.seller.seller_market_places.where(:is_active=>true).map(&:market_place_id))
        @stock_locations = StockLocation.accessible_by(current_ability, :read)
      end

      def manage_price
        @market_places = @product.market_places.where("spree_market_places.id IN (?)", @product.seller.seller_market_places.where(:is_active=>true).map(&:market_place_id))
      end

      def manage_description
        @market_places = @product.market_places.where("spree_market_places.id IN (?)", @product.seller.seller_market_places.where(:is_active=>true).map(&:market_place_id))
      end

      def manage_title
        @market_places = @product.market_places.where("spree_market_places.id IN (?)", @product.seller.seller_market_places.where(:is_active=>true).map(&:market_place_id))
      end

      def market_place_variants
        @smp = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", params[:seller_id], params[:product_id], params[:market_place_id]).first
        if @smp.present?
          @product = @smp.product
          @variants = @product.variants
          @variants = [@product.master] if @variants.empty?
          @stock_locations = StockLocation.accessible_by(current_ability, :read)
          respond_to do |format|
            format.html { render :partial=>"load_variants"}
          end
        else
          respond_to do |format|
            format.html {render :nothing=> true}
          end
        end
      end

      def create_marketplace_list
        @market_places = Spree::MarketPlace.all.collect{|c| [c.name, c.id]}
        @market_place_id = params[:market_place] || params[:market_place_id] || @market_places.first[1]
        @search_data = Spree::Product.not_listed_on_mp(@market_place_id)
        @search_data = @search_data.where("seller_id = ?", spree_current_user.seller.id) if spree_current_user.has_spree_role? 'seller'
        @search = @search_data.ransack(params[:q])
        # @search.build_condition
        # @search.build_sort if @search.sorts.empty?
        @products = @search.result(distinct: true)
        page = params[:page] || 0
        @page = (params[:page].present? ? params[:page] : 1).to_i
        @products = @products.page(params[:page]).per(Spree::Config[:admin_products_per_page])
        @collection = @products
      end

      def update_marketplace_list
        @market_places = Spree::MarketPlace.all.collect{|c| [c.name, c.id]}
        @market_place_id = params[:market_place] || params[:market_place_id] || @market_places.first[1]
        @search_data = Spree::Product.need_to_updated_on_mp(@market_place_id)
        @search_data = @search_data.where("seller_id = ?", spree_current_user.seller.id) if spree_current_user.has_spree_role? 'seller'
        @search = @search_data.ransack(params[:q])
        @products = @search.result(distinct: true)
        @page = (params[:page].present? ? params[:page] : 1).to_i
        @products = @products.page(params[:page]).per(Spree::Config[:admin_products_per_page])
        @collection = @products

      end

      def create_product_on_mp
        @products = Spree::Product.where("id in (?)", params[:product_ids].split(','))
        seller_ids = Spree::SellerMarketPlace.where("market_place_id=?", params[:market_place_id]).map(&:seller_id)
        market_place = Spree::MarketPlace.find(params[:market_place_id])
        @products.each do |product|
          if seller_ids.include? product.seller_id
            @sellers_market_places_product = Spree::SellersMarketPlacesProduct.unscoped.where("market_place_id=? AND product_id=? AND seller_id=?", params[:market_place_id], product.id, product.seller_id)
            @sellers_market_places_product = Spree::SellersMarketPlacesProduct.create!(:seller_id=>product.seller_id, :market_place_id=>params[:market_place_id], :product_id=>product.id) if !@sellers_market_places_product.present?
          end
        end
        res = ProductJob.create_products_on_mp(params[:product_ids],market_place,seller_ids,spree_current_user,request.host.to_s,request.port.to_s)
        @message = 'We are processing your request. We will let you know the status on you given emails.'
        if request.xhr?
          render :json => @message.to_json
        end
      end

      def update_product_on_mp
        @products = Spree::Product.where("id in (?)", params[:product_ids].split(','))
        market_place = Spree::MarketPlace.find(params[:market_place_id])
        res = ProductJob.update_products_on_mp(params[:product_ids],market_place, spree_current_user,request.host.to_s,request.port.to_s)
        @message = 'We are processing your request. We will let you know the status on you given emails.'
        if request.xhr?
          render :json => @message.to_json
        end
      end

      def error_message_for_mp
        product = Spree::Product.find(params[:product_id])
        @message = product.get_validation_msg(params[:market_place_id])
        if request.xhr?
          render :json => @message.to_json
        end
      end

      def get_updated_fields
        product = Spree::Product.find(params[:product_id])
        @message = product.get_updated_field_details(params[:product_id],params[:market_place_id])
        if request.xhr?
          render :json => @message.to_json
        end
      end
      
      # This method is used to end quantity inflation promotion
      def quantity_inflation_end_of_promotion
        ord_qty_hash = []
        variant = Spree::Variant.find(params[:variant_id])
        quantity_inflation = variant.quantity_inflations.where(:market_place_id=>params[:market_place_id]).try(:first)
        ord_qty_hash << quantity_inflation.end_of_promotion
        Spree::DataImportMailer::promotion_quantity_inflation_end(ord_qty_hash).deliver
        flash[:notice] = "Promotion is ended for selected product and all respective marketplaces"
        redirect_to :back
      end  
      
      def reject_marketplace_change
        product = Spree::Product.find(params[:product_id])
        Spree::RecentMarketPlaceChange.where(:product_id => product.id, :market_place_id => params[:market_place_id], :update_on_fba => false).update_all(:deleted_at => Date.today)
        @message = 'All these changes rejected.'
        if request.xhr?
          render :json => @message.to_json
        end
      end

     protected

        # Added by Tejaswini Patil
        # This method will extract the contents of uploaded zip file
        def extract(file_path)
          begin
            Archive::Zip.extract(file_path, "tmp/data_import", :symlinks => false, :directories => false)
            return true
          rescue Exception => e
            Delayed::Worker.logger.debug("== Extract error ============== \n #{e.message}")
            return false
          end
        end

        def collection
          return @collection if @collection.present?
          params[:q] ||= {}
          params[:q][:deleted_at_null] ||= "1"

          params[:q][:s] ||= "name asc"
          @collection = super
          @collection = @collection.with_deleted if params[:q].delete(:deleted_at_null).blank?
          # @search needs to be defined as this is passed to search_form_for
          @search = @collection.ransack(params[:q])
          @collection = @search.result.
            group_by_products_id.
            includes(product_includes).
            page(params[:page]).
            per(Spree::Config[:admin_products_per_page])

          if params[:q][:s].include?("master_default_price_amount")
            # PostgreSQL compatibility
            @collection = @collection.group("spree_prices.amount")
          end
          @collection
        end

        def product_includes
           [{:variants => [:images, {:option_values => :option_type}]}, {:master => [:images, :default_price]}, :seller]
        end

        def load_data
          @taxons = Taxon.order(:name)
          @option_types = OptionType.order(:name)
          @tax_categories = TaxCategory.order(:name)
          @shipping_categories = ShippingCategory.order(:name)
          @brands = Brand.order(:name)
        end

        def update_rcp
          #clear taxonomies caching
          expire_fragment("taxonomies")
          if @product.seller.type.price_based?
            @product.update_attributes(:rcp => @product.cost_price)
          else
            rcp = (@product.special_price || @product.price) * (1 - (@product.seller.revenue_share/100.to_f))
            rcp = (@product.special_price || @product.price) * (1 - (@product.seller.revenue_share_on_ware_house_sale/100.to_f)) if @product.is_warehouse
            @product.update_attributes(:rcp => rcp)
          end if @product.seller.type.present?
        end
      def product_scope
        if current_api_user.has_spree_role?("admin")
          scope = Product
          if params[:show_deleted]
            scope = scope.with_deleted
          end
        else
          scope = Product.active
        end

        scope.includes(:master)
      end
    end
  end
end
