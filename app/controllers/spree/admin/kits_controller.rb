module Spree
  module Admin
    class KitsController < Spree::Admin::BaseController
      #before_filter :authenticate_spree_user!
      load_and_authorize_resource :class => Spree::Kit

      respond_to :html

      # Load category list to select 
      def taxonomies_json
        @taxons_json = []
        query_string = "%#{params[:term]}%"
        @taxons = Spree::Taxonomy.categories.taxons#.where("name like ? OR id like ?", query_string, query_string)
        @taxons.collect{ |taxon|
          if (taxon.parent.present? && taxon.parent.parent.present? && taxon.parent.parent.parent.present?)
            name = (taxon.parent.parent.name+" -> "+taxon.parent.name+" -> "+taxon.name)
            @taxons_json << {'label' => name, 'id' => taxon.id} if name.downcase.include? params[:term].downcase
          end
        }
        render :json=>@taxons_json.to_json
      end

     # Modified by Tejaswini Patil
     # To make it work according to ability
     # Search code needs to optimize but due less time not doing that
     def index
      if params[:name].present? || params[:sku].present? || params[:seller].present?
            if params[:seller].present? && params[:seller][:id].present?
                  @seller = Spree::Seller.find(params[:seller][:id])
               if params[:name].present? && !params[:sku].present?
                  @kits = @seller.kits.where('name LIKE ?', "%#{params[:name]}%")
               elsif !params[:name].present? && params[:sku].present?
                  @kits = @seller.kits.where('sku LIKE ?', "%#{params[:sku]}%")
               elsif params[:name].present? && params[:sku].present?
                  @kits = @seller.kits.where('name LIKE ? AND sku LIKE ?', "%#{params[:name]}%", "%#{params[:sku]}%")
               else
                  @kits = @seller.kits
               end
            else
               if params[:name].present? && !params[:sku].present?
                  @kits = @kits.where('name LIKE ?', "%#{params[:name]}%")
               elsif !params[:name].present? && params[:sku].present?
                  @kits = @kits.where('sku LIKE ?', "%#{params[:sku]}%")
               elsif params[:name].present? && params[:sku].present?
                  @kits = @kits.where('name LIKE ? AND sku LIKE ?', "%#{params[:name]}%", "%#{params[:sku]}%")
               end
            end
      end
      @selected_name = params[:name] ? params[:name] : nil
      @selected_sku = params[:sku] ? params[:sku] : nil
      @selected_seller = params[:seller] ? params[:seller][:id] : nil
      @kits = Kaminari.paginate_array(@kits).page(params[:page]).per(Spree::Config[:admin_products_per_page])
      respond_to do |format|
        format.html
      end
    end

    def new
      @sellers = Spree::Seller.is_active
      @product = nil
      @taxons = []
      @categories = Spree::Taxonomy.categories
       if @categories.present?
          Spree::Taxonomy.categories.taxons.each do |t|
           if t.parent.present? && t.parent.parent.present? && t.parent.parent.parent.present?
            @taxons  << {:name=>(t.parent.parent.name+' -> '+t.parent.name+' -> '+t.name), :id=>t.id}
           # elsif t.parent.present? && t.parent.parent.present?
            # @taxons  << {:name=>(t.parent.parent.name+' -> '+t.parent.name+' -> '+t.name), :id=>t.id}
           # elsif t.parent.present?
            # @taxons  << {:name=>(t.parent.name+' -> '+t.name), :id=>t.id}
           end
          end
       end
      @kit = Kit.new
      respond_to do |format|
        format.html
        format.js
      end
    end

    def edit
      @render_breadcrumb = breadcrumb_path({:kits => admin_kits_path, :disable => "Edit"})
      @sellers = Spree::Seller.is_active
      @kit = Kit.find(params[:id])
      @product = @kit.product
      @selected_taxon = @product.taxons.first
      @taxons = []
      @seller = @kit.seller
      Spree::Taxonomy.categories.taxons.each do |t|
        if t.parent.present? && t.parent.parent.present? && t.parent.parent.parent.present?
          @taxons  << {:name=>(t.parent.parent.name+' -> '+t.parent.name+' -> '+t.name), :id=>t.id}
        # elsif t.parent.present? && t.parent.parent.present?
          # @taxons  << {:name=>(t.parent.parent.name+' -> '+t.parent.name+' -> '+t.name), :id=>t.id}
        # elsif t.parent.present?
          # @taxons  << {:name=>(t.parent.name+' -> '+t.name), :id=>t.id}
        end
      end
      respond_to do |format|
        format.html
      end
    end

    def show
      @kit = Kit.find(params[:id])
      @kit_products = @kit.kit_products
      @kit_products = Kaminari.paginate_array(@kit_products).page(params[:page]).per(Spree::Config[:admin_products_per_page])
      @render_breadcrumb = breadcrumb_path({:kits => admin_kits_path, :disable => @kit.name})
      respond_to do |format|
        format.html
      end
    end

   def create
     error = nil
     begin
       if params[:kit][:cost_price].present? && (params[:kit][:price].to_f < params[:kit][:cost_price].to_f)
         error = "Retail price alway greater than or equanl to cost price"
       end
       if params[:kit][:special_price].present? && (params[:kit][:special_price].to_f > params[:kit][:price].to_f)
         error = "Retail price alway greater than or equanl to spacial price"
       end
       if params[:kit][:price].to_f < params[:kit][:selling_price].to_f
         error = "Retail price alway greater than or equanl to selling price"
       end
       if !error.present?
         @kit = Kit.create(:seller_id => params[:kit][:seller_id], :name => params[:kit][:name], :sku => params[:kit][:sku], :description => params[:kit][:description], :quantity => params[:kit][:quantity], :is_common_stock =>params[:kit][:is_common_stock], :is_active =>params[:kit][:is_active])
         # Code for creating kit as product and list
         @product = Product.create!(:name => @kit.name, :description => @kit.description, :seller_id => params[:kit][:seller_id], :is_adult => 0, :kit_id => @kit.id, :cost_currency => params[:kit][:cost_currency], :sku => @kit.sku, :price => params[:kit][:price], :cost_price => params[:kit][:cost_price], :special_price => params[:kit][:special_price], :selling_price => params[:kit][:selling_price], :taxon_ids => params[:kit_taxon_id], :is_approved => @kit.is_active)
         # Code for adding image to kit as product
         if params[:kit] && !params[:kit][:attachment].blank?
           kit_product_image = Spree::Image.create!({:attachment => params[:kit][:attachment], :viewable_id => @product.id}, :without_protection => true)
           @product.images << kit_product_image
         end
       end
       if !error.present? && @kit.present? && @kit.save!
         respond_to do |format|
           format.html { redirect_to admin_kit_path(@kit), notice: 'Kit was successfully created.' }
           format.json { render json: @kit, status: :created, location: @kit }
           #format.json { redirect_to json: admin_kit_path(params[:kit]), notice: error }
         end
       else
         flash[:error] = error
         redirect_to :action=>"new", :controller=>"kits"
       end
     rescue Exception => e
       flash[:error] = e.message
       redirect_to :action=>"new", :controller=>"kits"
     end

    end

    def update
      @kit = Kit.find(params[:id])
      @kit_before_update_qty = @kit.quantity
      if !params[:market].nil? || (params[:market] && !params[:market][:place_id].blank?)
         @selected_mp_ids = params[:market][:place_id]
      end

      respond_to do |format|
        if @kit.update_attributes(:name => params[:kit][:name], :sku => params[:kit][:sku], :description => params[:kit][:description], :quantity => params[:kit][:quantity], :is_common_stock =>params[:kit][:is_common_stock], :is_active =>params[:kit][:is_active])
           @product = @kit.product
           @old_description = @product.description
           @old_price = @product.price.to_f
           @old_special_price = @product.special_price.to_f
           @product.update_attributes(:name => @kit.name, :description => @kit.description, :cost_currency => params[:kit][:cost_currency], :sku => @kit.sku, :price => params[:kit][:price], :cost_price => params[:kit][:cost_price], :special_price => params[:kit][:special_price], :selling_price => params[:kit][:selling_price], :taxon_ids => params[:kit_taxon_id], :is_approved => @kit.is_active)
           # Code for adding image to kit as product
           if params[:kit] && !params[:kit][:attachment].blank?
             kit_product_image = Spree::Image.create!({:attachment => params[:kit][:attachment], :viewable_id => @product.id}, :without_protection => true)
             @product.images << kit_product_image
           end


           begin
           if @selected_mp_ids.present?
             if params[:kit] && !params[:kit][:attachment].blank?
               kit_product_image = Spree::Image.create!({:attachment => params[:kit][:attachment], :viewable_id => @product.id}, :without_protection => true)
               @product.images << kit_product_image
             end
              @selected_mp_ids.each do |mp|
                   @error_message = []
                   @sellers_market_places_kit = Spree::SellersMarketPlacesKit.where("seller_id=? AND kit_id=? AND market_place_id=?", params[:kit][:seller_id], @kit.id, mp)
                   @sellers_market_places_kit = Spree::SellersMarketPlacesKit.create(:seller_id=> params[:kit][:seller_id], :market_place_id=> mp,
                       :kit_id=> @kit.id) if @sellers_market_places_kit.blank?
                    # Code to attach market places to kit as product
                   @sellers_market_places_kit_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", params[:kit][:seller_id], @product.id, mp)
                   @sellers_market_places_kit_product = Spree::SellersMarketPlacesProduct.create!(:seller_id=> params[:kit][:seller_id], :market_place_id=> mp, :product_id=> @product.id) if @sellers_market_places_kit_product.blank?
                    # Code to list product on market places
                   @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", params[:kit][:seller_id], mp, @product.id)
                    market_place =  @market_place_product.first.market_place
                   @taxon_market_plcaes = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", @product.taxons.first.id, mp)
                    user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", params[:kit][:seller_id], mp)

                    product_params = {}
                    product_params[:product] = {}
                    product_params[:product][:name] = params[:kit][:name]
                    product_params[:product][:description] = params[:kit][:description]
                    product_params[:product][:price] = params[:kit][:price]
                    product_params[:product][:selling_price] = params[:kit][:selling_price]

                    if @taxon_market_plcaes && !@taxon_market_plcaes.blank?
                      # This new product create condition on market place product
                      # if !@market_place_product.blank? && !@market_place_product.first.market_place_product_code.present? && !@taxon_market_plcaes.blank?
                      #   if !user_market_place.blank? && !user_market_place.first.api_secret_key.nil?
                      #     if market_place.present?
                      #       case market_place.code
                      #       when "qoo10"
                      #         res = view_context.listing_product_qoo10(market_place.id, product_params, @product, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first)
                      #       when "lazada", "zalora"
                      #         res = view_context.listing_product_lazada(market_place.id, product_params, @product, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first)
                      #       end
                      #       @error_message << (res == true ? "" : res)
                      #     end
                      #   else
                      #     @error_message << @sellers_market_places_kit_product.market_place.name+": Api key or Secret key is missing"
                      #   end
                      #   # This product update condition on market place product
                      # elsif !@market_place_product.blank? && @market_place_product.first.market_place_product_code.present? && !@taxon_market_plcaes.blank?
                      #   if !user_market_place.blank? && !user_market_place.first.api_secret_key.nil?
                      #     if market_place.present?
                      #       case market_place.code
                      #       when "qoo10"
                      #         res = view_context.update_product_qoo10(market_place.id, product_params, @product, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first, @old_description, @old_price, @old_special_price)
                      #       when "lazada" , "zalora"
                      #         res = view_context.update_product_lazada(market_place.id, product_params, @product, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first)
                      #       end
                      #       @error_message << (res == true ? "" : res)
                      #     end
                      #   else
                      #     @error_message << @sellers_market_places_kit_product.market_place.name+": Api key or Secret key is missing"
                      #   end
                      # end
                    else
                      @error_message << market_place.name+": Please map market place category to list product"
                       format.html { redirect_to admin_kits_path, notice: @error_message }
                       format.json { render json: @kit, status: :created, location: @kit }
                    end
               end #end loop
            end #end if
           rescue Exception => e
               @error_message << e.message
           end

            if @kit.kit_products.present?
             if @kit.is_common_stock?
                  #ap "----Common Stock : Products Found----"
                  @variant_ids = @kit.try(:kit_products).map(&:variant).map(&:id)
                  #ap @variant_ids
                  @variant_qtys =@kit.try(:kit_products).map(&:quantity)
                  #ap @variant_qtys

                  @kit.update_attributes(:quantity => nil)
                  @variant_ids.each_with_index do |v, index|
                     #ap v
                     @product = Spree::Variant.find(v).product
                     #ap @product
                     @market_places = @kit.market_places
                     #ap @market_places.count
                     @market_places.each_with_index do |mp, index|
                         @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @kit.seller_id, mp.id, @product.id).first
                         #ap @sellers_market_places_product
                          if @sellers_market_places_product.present?
                             @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, v).first
                              if @stock_product.present?
                                   #ap @stock_product
                                   variant_qty = @stock_product.count_on_hand
                                   #ap '--variant_qty--'
                                   #ap variant_qty
                                   requested_qty = @variant_qtys[index]
                                   #ap '--requested_qty--'
                                   #ap requested_qty.to_i
                                   kit_qty = @kit_before_update_qty.to_i
                                   #ap '--kit_qty--'
                                   #ap kit_qty
                                   overall_qty = (kit_qty.to_i * requested_qty.to_i)
                                   #ap '--overall_qty--'
                                   #ap overall_qty

                                   # code for add the stock into product stock
                                   #ap '----need to add logic to add stock into product stock----'
                                   qty_for_update = variant_qty + overall_qty
                                   #ap qty_for_update
                                   @stock_product.update_attributes(:count_on_hand => qty_for_update)
                                   #ap '----added stock successfully----'
                                   #ap @stock_product
                              end
                          end
                        end
                end
             else
               #ap "----Seperate Stock : Products Found----"
               @variant_ids = @kit.try(:kit_products).map(&:variant).map(&:id)
               #ap @variant_ids
               @variant_qtys =@kit.try(:kit_products).map(&:quantity)
               #ap @variant_qtys
               @variant_ids.each_with_index do |v, index|
                     #ap v
                     @product = Spree::Variant.find(v).product
                     #ap @product
                     @market_places = @kit.market_places
                     #ap @market_places.count
                     @market_places.each_with_index do |mp, index|
                         @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @kit.seller_id, mp.id, @product.id).first
                         #ap @sellers_market_places_product
                          if @sellers_market_places_product.present?
                              @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, v).first
                              if @stock_product.present?
                                 #ap @stock_product
                                 variant_qty = @stock_product.count_on_hand
                                 #ap '--variant_qty--'
                                 #ap variant_qty
                                 requested_qty = @variant_qtys[index]
                                 #ap '--requested_qty--'
                                 #ap requested_qty.to_i
                                 kit_qty = @kit.quantity
                                 #ap '--kit_qty--'
                                 #ap kit_qty
                                 overall_qty = (kit_qty.to_i * requested_qty.to_i)
                                 #ap '--overall_qty--'
                                 #ap overall_qty
                                 if variant_qty < overall_qty
                                    #ap '----qty less-----'
                                    format.html { redirect_to edit_admin_kit_path(@kit), notice: 'Oops..This much quantity of products are not available' }
                                 else
                                    #ap '----qty more----'
                                    # code for deduct the stock from product stock
                                    #ap '----need to add logic to deduct stock from product stock----'
                                    qty_for_update = variant_qty - overall_qty
                                    #ap qty_for_update
                                    @stock_product.update_attributes(:count_on_hand => qty_for_update)
                                    #ap '----deducted stock successfully----'
                                    #ap @stock_product
                                 end
                             end
                          end
                        end
                end
             end
          else
             if @kit.is_common_stock?
               #ap "----Common Stock : Products Not Found----"
               @kit.update_attributes(:quantity => nil)
               #ap '---Kit updated successfully'
             end
          end

          format.html { redirect_to admin_kits_path, notice: 'Kit was successfully updated.' }
          format.json { render json: @kit, status: :created, location: @kit }
        else
          format.html { render action: "edit" }
          format.json { render json: @kit.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @kit = Kit.find(params[:id])
      respond_to do |format|
        if @kit.destroy
          format.html { redirect_to admin_kits_path, notice: 'Kit was successfully deleted.' }
          format.json { render json: @kit, status: :created, location: @kit }
        else
          format.html { redirect_to admin_kits_path, notice: 'Kit was not successfully deleted.' }
          format.json { render json: @kit.errors, status: :unprocessable_entity }
        end
      end
    end

    def load_market_places_for_kit
        @market_places = []
        @seller = Spree::Seller.where("id=?", params[:seller_id]).first
        @market_places = @seller.market_places.where('is_active=?', true) if !@seller.blank?
        @selected_mp_ids = Spree::SellersMarketPlacesKit.where("seller_id=? AND kit_id=?", params[:seller_id], params[:kit_id])
        @selected_mp_ids = @selected_mp_ids.pluck(:market_place_id) if !@selected_mp_ids.blank?
         respond_to do |format|
            format.html { render :partial=>"load_market_places_for_kit"}
         end
     end

     def load_market_places_for_bulk_kit_upload
        @market_places = []
        @seller = Spree::Seller.where("id=?", params[:seller_id]).first
        @market_places = @seller.market_places.where('is_active=?', true) if !@seller.blank?
         respond_to do |format|
            format.html { render :partial=>"load_market_places_for_bulk_kit"}
         end
     end

    def upload_kit
      # for exporting xls for Kit
      if params[:xlsx] == 'xlsx'
          sellers_market_places_kit = Spree::SellersMarketPlacesKit.where("seller_id=? AND market_place_id=?", params[:seller_id_export], params[:market_place_id])
          if sellers_market_places_kit.present?
             export_to_excel(sellers_market_places_kit)
          else
             flash[:error] = "No kit found!"
             redirect_to admin_kits_path
          end
          return
      end

      # check file is .xls or other
      unless File.extname(params[:attachment].original_filename) == ".zip"
        flash[:error] = "Please upload a valid zip file"
        redirect_to admin_kits_path
        return
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

      # open excel file and get all worksheets array
      kits = Spreadsheet.open "#{DATASHIFT_PATH}/#{filename}/kit_import_with_images.xls"
      file_path = "#{DATASHIFT_PATH}/#{filename}/images/"

      # select first worksheet
      kit_sheet = kits.worksheet(0)
      error_hash = []

      kit_sheet.each_with_index do |row, index|
        if row.compact.empty?
           break;
        end

        if spree_current_user.has_spree_role? 'admin'
          @seller = Spree::Seller.find(params[:seller_id])
        else
          @seller = spree_current_user.seller
        end

        if !row[8].nil?
            main_cat = @seller.categories.find_by_name(row[8].to_s)
        end

        row[100] = ""
        if index == 0
           error_hash << row
           next
        end

        # row[00] => Kit Name*
        # row[01] => Kit SKU*
        # row[02] => Description
        # row[03] => Stock Option*
        # row[04] => Kit Quantity
        # row[05] => Is active
        # row[06] => Product SKU's
        # row[07] => Product QTY's
        # row[08] => Main Category*
        # row[09] => Sub Category
        # row[10] => Sub Sub Category
        # row[11] => Cost Currency*
        # row[12] => Cost Price
        # row[13] => Retail Price*
        # row[14] => Selling Price*
        # row[15] => Special Price
        # row[16] => Image

        if index == 0 || row[0].nil? || row[1].nil? || row[3].nil? || main_cat.nil? || row[11].nil? || row[13].nil? || row[14].nil? || row[16].nil? # || row[6].nil? || row[7].nil?
          row[100] += "0" if row[0].nil?
          row[100] += ",1" if row[1].nil?
          row[100] += ",3" if row[3].nil?
          # row[100] += ",6" if row[6].nil?
          # row[100] += ",7" if row[7].nil?
          row[100] += ",8" if main_cat.nil?
          row[100] += ",11" if row[11].nil?
          row[100] += ",13" if row[13].nil?
          row[100] += ",14" if row[14].nil?
          row[100] += ",16" if row[16].nil?
          error_hash << row
          next
        else
          @kit_exist = @seller.kits.find_by_sku(row[1]) rescue nil
          @variant_skus = row[6].to_s.split(',') unless row[6].nil?
          @variant_qtys = row[7].to_s.split(',') unless row[7].nil?
          cost_currency = row[11].to_s
          cost_price = row[12]
          retail_price = row[13]
          selling_price = row[14]
          special_price = row[15]
          kit_image = nil
          image_error = false

          if @kit_exist.present?
             @kit_prev_qty = @kit_exist.quantity
             @kit_exist.update_attributes(:name => row[0],
              :description => row[2],
              :is_common_stock => row[3].to_s == "Common Stock" ? 1 : row[3].to_s == "Seperate Stock" ? 0 : 1,
              :quantity => row[3].to_s == "Common Stock" ? nil : row[3].to_s == "Seperate Stock" ? row[4].nil? ? 1 : row[4].to_i : nil,
              :is_active => row[5].to_s.downcase)
             @kit = @kit_exist
             @product = @kit.product
             @old_description = @product.description
             @old_price = @product.price.to_f
             @old_special_price = @product.special_price.to_f
             # code for updating kit as product and list
             @product.update_attributes(:name => @kit.name, :description => @kit.description, :cost_currency => cost_currency,
                                                           :sku => @kit.sku, :price => retail_price, :cost_price => cost_price,
                                                           :special_price => special_price, :selling_price => selling_price,
                                                           :is_approved => @kit.is_active)
              # update & upload category to kit as product
              @product.taxons.destroy_all if @product.taxons.present?
              main_cat = @seller.categories.find_by_name(row[8].to_s)
              sub_cat = nil
              sub_cat = main_cat.children.find_by_name(row[9].to_s) if main_cat.present?
              sub_sub_cat = nil
              sub_sub_cat = sub_cat.children.find_by_name(row[10].to_s) if sub_cat.present?
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
              # attach image to kit as product
              if FileTest.exists?("#{file_path}#{row[16]}")
                 kit_image = Spree::Image.create!({:attachment => open("#{file_path}#{row[16]}"), :viewable_id => @product.id}, :without_protection => true) unless row[16].nil?
              else
                 image_error = true
                 row[100] += ",16"
              end
              error_hash << row if image_error
              @product.images << kit_image unless kit_image.nil?
              @kit_updatation = true
          else
              kit_hash = {
              :name => row[0],
              :sku => row[1],
              :description => row[2],
              :is_common_stock => row[3].to_s == "Common Stock" ? 1 : row[3].to_s == "Seperate Stock" ? 0 : 1,
              :quantity => row[3].to_s == "Common Stock" ? nil : row[3].to_s == "Seperate Stock" ? row[4].nil? ? 1 : row[4].to_i : nil,
              :is_active => row[5].to_s.downcase
              }
              @kit = @seller.kits.build(kit_hash)
              @kit.save!
               # code for creating kit as product and list
              @product = Product.create!(:name => @kit.name, :description => @kit.description, :seller_id => params[:seller_id], :is_adult => 0, :kit_id => @kit.id,
                                                           :cost_currency => cost_currency, :sku => @kit.sku, :price => retail_price,
                                                           :cost_price => cost_price, :special_price => special_price,
                                                           :selling_price => selling_price, :is_approved => @kit.is_active)
              # update & upload category to kit as product
              @product.taxons.destroy_all if @product.taxons.present?
              main_cat = @seller.categories.find_by_name(row[8].to_s)
              sub_cat = nil
              sub_cat = main_cat.children.find_by_name(row[9].to_s) if main_cat.present?
              sub_sub_cat = nil
              sub_sub_cat = sub_cat.children.find_by_name(row[10].to_s) if sub_cat.present?
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
              # attach image to kit as product
              if FileTest.exists?("#{file_path}#{row[16]}")
                 kit_image = Spree::Image.create!({:attachment => open("#{file_path}#{row[16]}"), :viewable_id => @product.id}, :without_protection => true) unless row[16].nil?
              else
                 image_error = true
                 row[100] += ",16"
              end
              error_hash << row if image_error
              @product.images << kit_image unless kit_image.nil?
              @kit_updatation = false
         end # end if

         if !params[:market].nil? || (params[:market] && !params[:market][:place_id].blank?)
            @selected_mp_ids = params[:market][:place_id]
         end

         begin
           if @selected_mp_ids.present?
              @selected_mp_ids.each do |mp|
                   @error_message = []
                   @sellers_market_places_kit = Spree::SellersMarketPlacesKit.where("seller_id=? AND kit_id=? AND market_place_id=?", params[:seller_id], @kit.id, mp)
                   @sellers_market_places_kit = Spree::SellersMarketPlacesKit.create(:seller_id=> params[:seller_id], :market_place_id=> mp,
                       :kit_id=> @kit.id) if @sellers_market_places_kit.blank?
                    # Code to attach market places to kit as product
                   @sellers_market_places_kit_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND product_id=? AND market_place_id=?", params[:seller_id], @product.id, mp)
                   @sellers_market_places_kit_product = Spree::SellersMarketPlacesProduct.create!(:seller_id=> params[:seller_id], :market_place_id=> mp, :product_id=> @product.id) if @sellers_market_places_kit_product.blank?
                    # Code to list product on market places
                   @market_place_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", params[:seller_id], mp, @product.id)
                    market_place =  @market_place_product.first.market_place
                   @taxon_market_plcaes = Spree::TaxonsMarketPlace.where("taxon_id=? AND market_place_id=?", @product.taxons.first.id, mp)
                    user_market_place = Spree::SellerMarketPlace.where("seller_id=? AND market_place_id=?", params[:seller_id], mp)

                    product_params = {}
                    product_params[:product] = {}
                    product_params[:product][:name] = @product.name
                    product_params[:product][:description] = @product.description
                    product_params[:product][:price] = @product.price
                    product_params[:product][:selling_price] = @product.selling_price

                    # if @taxon_market_plcaes && !@taxon_market_plcaes.blank?
                    #   # This new product create condition on market place product
                    #   if !@market_place_product.blank? && !@market_place_product.first.market_place_product_code.present? && !@taxon_market_plcaes.blank?
                    #     if !user_market_place.blank? && !user_market_place.first.api_secret_key.nil?
                    #       if market_place.present?
                    #         case market_place.code
                    #         when "qoo10"
                    #           res = view_context.listing_product_qoo10(market_place.id, product_params, @product, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first)
                    #         when "lazada" , "zalora"
                    #           res = view_context.listing_product_lazada(market_place.id, product_params, @product, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first)
                    #         end
                    #         if res != true
                    #            @error_message << res
                    #            row[100] += ",17"
                    #            error_hash << row if !error_hash.include?(row)
                    #         end
                    #       end
                    #     else
                    #       @error_message << @sellers_market_places_kit_product.market_place.name+": Api key or Secret key is missing"
                    #       row[100] += ",17"
                    #       error_hash << row if !error_hash.include?(row)
                    #     end
                    #     # This product update condition on market place product
                    #   elsif !@market_place_product.blank? && @market_place_product.first.market_place_product_code.present? && !@taxon_market_plcaes.blank?
                    #     if !user_market_place.blank? && !user_market_place.first.api_secret_key.nil?
                    #       if market_place.present?
                    #         case market_place.code
                    #         when "qoo10"
                    #           res = view_context.update_product_qoo10(market_place.id, product_params, @product, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first, @old_description, @old_price, @old_special_price)
                    #         when "lazada" , "zalora"
                    #           res = view_context.update_product_lazada(market_place.id, product_params, @product, user_market_place.first, @taxon_market_plcaes.first, @market_place_product.first)
                    #         end
                    #         if res != true
                    #            @error_message << res
                    #            row[100] += ",17"
                    #            error_hash << row if !error_hash.include?(row)
                    #         end
                    #       end
                    #     else
                    #       @error_message << @sellers_market_places_kit_product.market_place.name+": Api key or Secret key is missing"
                    #       row[100] += ",17"
                    #       error_hash << row if !error_hash.include?(row)
                    #     end
                    #   end
                    # else
                    #   @error_message << market_place.name+": Please map market place category to list product"
                    #   row[100] += ",17"
                    #   error_hash << row if !error_hash.include?(row)
                    # end
               end #end loop
            end #end if
           rescue Exception => e
               @error_message << e.message
               row[100] += ",17"
               error_hash << row if !error_hash.include?(row)
           end

        if @variant_skus.present?
        @variant_skus.each_with_index do |vs, index|
         @variant = Spree::Variant.find_by_sku(vs)
         variant_id = @variant.id
         product_id = @variant.product.id
         kit_id = @kit.id
         qty = @variant_qtys[index].to_i
         #ap '-----all parameters come properly-----'

         @product = Spree::Product.find(product_id)
         #ap @product

         if @kit_updatation == true
          #ap '---kit update time---'

          if !@kit.is_common_stock?
           #ap "----Seperate Stock----"
           @market_places = @kit.market_places
           #ap @market_places.count
           @market_places.each do |mp|
                       @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @kit.seller_id, mp.id, @product.id).first
                       #ap @sellers_market_places_product
                       if @sellers_market_places_product.present?
                           @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, variant_id).first
                           if @stock_product.present?
                               #ap @stock_product
                               variant_qty = @stock_product.count_on_hand
                               #ap '--variant_qty--'
                               #ap variant_qty
                               requested_qty = qty
                               #ap '--requested_qty--'
                               #ap requested_qty.to_i
                               kit_qty = @kit.quantity
                               #ap '--kit_qty--'
                               #ap kit_qty
                               overall_qty = (kit_qty.to_i * requested_qty.to_i)
                               #ap '--overall_qty--'
                               #ap overall_qty
                               if variant_qty < overall_qty
                                    #ap '----qty less-----'
                                    #ap '----need to add validation for qty field----'
                                    @kit_product_updatation = false
                               else
                                    # code for deduct the stock from product stock
                                    #ap '----need to add logic to deduct stock from product stock----'
                                    qty_for_update = variant_qty - overall_qty
                                    #ap qty_for_update
                                    @stock_product.update_attributes(:count_on_hand => qty_for_update)
                                    #ap '----deducted stock successfully----'
                                    #ap @stock_product
                                    @kit_product_updatation = true
                              end
                           end
                        end
                     end

                        if @kit_product_updatation == true
                         #ap '--kit_product_updation--'
                         @existing_kit_product = Spree::KitProduct.where("kit_id=? AND variant_id=?", @kit.id, variant_id).first
                         if !@existing_kit_product.blank?
                          #ap '----update----'
                          old_qty = @existing_kit_product.quantity.to_i
                          #ap old_qty
                          new_qty = qty
                          #ap new_qty
                          total_qty = old_qty + new_qty
                          #ap total_qty
                          @existing_kit_product.update_attributes(:quantity => total_qty)
                          #ap @existing_kit_product
                          #ap '-----Updated product quantity successfully into kit-----'
                        else
                          @kit_product = Spree::KitProduct.create(:kit_id => @kit.id, :variant_id => variant_id, :product_id => product_id, :quantity=> qty)
                          #ap @kit_product
                          #ap '-----Added product successfully into kit-----'
                        end
                      end

                    else
                     #ap "----Common Stock----"
                     @market_places = @kit.market_places
                     #ap @market_places.count
                     @market_places.each do |mp|
                       @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @kit.seller_id, mp.id, @product.id).first
                       #ap @sellers_market_places_product
                       if @sellers_market_places_product.present?
                         @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, variant_id).first
                         if @stock_product.present?
                           #ap @stock_product
                           variant_qty = @stock_product.count_on_hand
                           #ap '--variant_qty--'
                           #ap variant_qty
                           requested_qty = qty
                           #ap '--requested_qty--'
                           #ap requested_qty.to_i
                           kit_qty = @kit_prev_qty
                           #ap '--kit_qty--'
                           #ap kit_qty
                           overall_qty = (kit_qty.to_i * requested_qty.to_i)
                           #ap '--overall_qty--'
                           #ap overall_qty

                           # code for add the stock into product stock
                           #ap '----need to add logic to add stock into product stock----'
                           qty_for_update = variant_qty + overall_qty
                           #ap qty_for_update
                           @stock_product.update_attributes(:count_on_hand => qty_for_update)
                           #ap '----added stock successfully----'
                           #ap @stock_product
                        end
                      end
                    end

                       @existing_kit_product = Spree::KitProduct.where("kit_id=? AND variant_id=?", @kit.id, variant_id).first
                       if !@existing_kit_product.blank?
                        #ap '----update----'
                        old_qty = @existing_kit_product.quantity.to_i
                        #ap old_qty
                        new_qty = qty
                        #ap new_qty
                        total_qty = old_qty + new_qty
                        #ap total_qty
                        @existing_kit_product.update_attributes(:quantity => total_qty)
                        #ap @existing_kit_product
                        #ap '-----Updated product quantity successfully into kit-----'
                      else
                        @kit_product = Spree::KitProduct.create(:kit_id => @kit.id, :variant_id => variant_id, :product_id => product_id, :quantity=> qty)
                        #ap @kit_product
                        #ap '-----Added product successfully into kit-----'
                      end
                    end

                  else
                    #ap '---kit create time---'
                    if !@kit.is_common_stock?
                     #ap "----Seperate Stock----"
                     @market_places = @kit.market_places
                     #ap @market_places.count
                     @market_places.each do |mp|
                       @sellers_market_places_product = Spree::SellersMarketPlacesProduct.where("seller_id=? AND market_place_id=? AND product_id=?", @kit.seller_id, mp.id, @product.id).first
                       #ap @sellers_market_places_product
                       if @sellers_market_places_product.present?
                          @stock_product = Spree::StockProduct.where("sellers_market_places_product_id=? AND variant_id=?", @sellers_market_places_product.id, variant_id).first
                           if @stock_product.present?
                               #ap @stock_product
                               variant_qty = @stock_product.count_on_hand
                               #ap '--variant_qty--'
                               #ap variant_qty
                               requested_qty = qty
                               #ap '--requested_qty--'
                               #ap requested_qty.to_i
                               kit_qty = @kit.quantity
                               #ap '--kit_qty--'
                               #ap kit_qty
                               overall_qty = (kit_qty.to_i * requested_qty.to_i)
                               #ap '--overall_qty--'
                               #ap overall_qty
                               if variant_qty < overall_qty
                                  #ap '----qty less-----'
                                  #ap '----need to add validation for qty field----'
                                  @kit_product_creation = false
                               else
                                  #ap '----qty more----'
                                  # code for deduct the stock from product stock
                                  #ap '----need to add logic to deduct stock from product stock----'
                                  qty_for_update = variant_qty - overall_qty
                                  #ap qty_for_update
                                  @stock_product.update_attributes(:count_on_hand => qty_for_update)
                                  #ap '----deducted stock successfully----'
                                  #ap @stock_product
                                  @kit_product_creation = true
                               end
                           end
                        end
                      end

                        if @kit_product_creation == true
                         #ap '--kit_product_creation--'
                         @existing_kit_product = Spree::KitProduct.where("kit_id=? AND variant_id=?", @kit.id, variant_id).first
                         if !@existing_kit_product.blank?
                          #ap '----update----'
                          old_qty = @existing_kit_product.quantity.to_i
                          #ap old_qty
                          new_qty = qty
                          #ap new_qty
                          total_qty = old_qty + new_qty
                          #ap total_qty
                          @existing_kit_product.update_attributes(:quantity => total_qty)
                          #ap @existing_kit_product
                          #ap '-----Updated product quantity successfully into kit-----'
                        else
                          @kit_product = Spree::KitProduct.create(:kit_id => @kit.id, :variant_id => variant_id, :product_id => product_id, :quantity=> qty)
                          #ap @kit_product
                          #ap '-----Added product successfully into kit-----'
                        end
                      end

                    else
                      #ap "----Common Stock----"
                      @existing_kit_product = Spree::KitProduct.where("kit_id=? AND variant_id=?", @kit.id, variant_id).first
                      if !@existing_kit_product.blank?
                        #ap '----update----'
                        old_qty = @existing_kit_product.quantity.to_i
                        #ap old_qty
                        new_qty = qty
                        #ap new_qty
                        total_qty = old_qty + new_qty
                        #ap total_qty
                        @existing_kit_product.update_attributes(:quantity => total_qty)
                        #ap @existing_kit_product
                        #ap '-----Updated product quantity successfully into kit-----'
                      else
                        @kit_product = Spree::KitProduct.create(:kit_id => @kit.id, :variant_id => variant_id, :product_id => product_id, :quantity=> qty)
                        #ap @kit_product
                        #ap '-----Added product successfully into kit-----'
                      end
                    end
                  end
                end # end loop
              end # end if variant_skus present

               end # end if kit_exist
             end # end if index

            @error_message = @error_message.reject(&:empty?)
            if error_hash.present? && error_hash.size >= 2 && @error_message.present?
               excel_error(error_hash, @error_message)
            else
               redirect_to admin_kits_path, :notice => "Kit Uploaded Successfully!"
               return
            end
      end

      def excel_error(error_hash, error_message)
        errors = Spreadsheet::Workbook.new
        error = errors.create_worksheet :name => "errors"
        red = Spreadsheet::Format.new :color => 'black', :size => 10, :align => 'center', :pattern_fg_color => :red, :pattern => 1
        error_hash.each_with_index do |err, index|
          error.row(index).push err[0], err[1], err[2], err[3], err[4], err[5], err[6], err[7], err[8], err[9], err[10], err[11], err[12], err[13], err[14], err[15], err[16]
          errors_test = err[100].split(",")
          err[100].split(",").each do |r|
            next unless r.present?
            error.row(index).set_format(r.to_i, red) unless index == 0
            error.row(index).push error_message.fetch(0) if error_message.present? && index != 0
          end
        end
        blob = StringIO.new("")
        errors.write blob
        send_data blob.string, :type => :xls, :filename => "kit_errors.xls"
        return
      end

       def export_to_excel(collection)
          kits = Spreadsheet::Workbook.new
          kit = kits.create_worksheet name: 'kits'
          kit.row(0).push '#', 'Kit Name', 'Kit SKU', 'Kit Description', 'Kit Quantity', 'Stock Option', 'Is Active', 'Total Products', 'Product SKUs', 'Product Qtys', 'Category', 'Cost Currency', 'Cost Price', 'Retail Price', 'Selling Price', 'Special Price'
          i = 1
          collection.each_with_index do |pr, index|
            kit.row(i).push i, pr.kit.name, pr.kit.sku, pr.kit.description, pr.kit.quantity.present? ? pr.kit.quantity : "-", pr.kit.is_common_stock? ? "Common Stock" : "Seperate Stock", pr.kit.is_active, pr.kit.try(:products).present? ? pr.kit.try(:products).count : 0 , pr.kit.try(:kit_products).present? ? pr.kit.try(:kit_products).map(&:variant).map(&:sku).join(', ') : "-", pr.kit.try(:kit_products).present? ? pr.kit.try(:kit_products).pluck(:quantity).join(', ') : "-",
                                      pr.kit.product.present? ? pr.kit.product.taxons.collect(&:name).join(",") : "-", pr.kit.product.present? ? pr.kit.product.cost_currency : "-", pr.kit.product.present? ? pr.kit.product.cost_price : "-", pr.kit.product.present? ? pr.kit.product.price : "-", pr.kit.product.present? ? pr.kit.product.selling_price : "-", pr.kit.product.present? ? pr.kit.product.special_price : "-"
            i += 1
          end if collection.present?
          blob = StringIO.new('')
          kits.write blob
          send_data blob.string, :type => :xls, filename: "kits.xls"
      end

      protected

      def extract(zip_file)
        begin
          Archive::Zip.extract(zip_file, DATASHIFT_PATH, :symlinks => false, :directories => false)
          return true
        rescue Exception => e
          Rails.logger.info "================================\n #{e.message}"
          return false
        end
      end

      def create_import_data_dir(directory_name)
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
      end

       private
        def model_class
          Kit
        end

    end
  end
end
