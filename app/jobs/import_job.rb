# Added By Tejaswini Patil
# To add delayed methods for importing data
class ImportJob
	require 'archive/zip'
      require 'spreadsheet'

	# This methos will import products from uploaded excel file
	def self.create_products(seller,file_path,current_user)
	  @empty_msg = ""
		Delayed::Worker.logger.debug("================ Product creation logs starts at #{Time.now}")

		processing_start_time = Time.zone.now
		Delayed::Worker.logger.debug("#{processing_start_time} Product creation Process Starts at Sec.")

		Delayed::Worker.logger.debug("#{Time.now} Opening Xls File")
	    products = Spreadsheet.open file_path

	    Delayed::Worker.logger.debug("#{Time.now} Xls File Opened")

	    # select first worksheet
	    product_sheet = products.worksheet(0)

	    error_hash = []
	    total_products = 0
	    unless product_sheet.rows.count >= 2
	    	@empty_msg = "Channel Manager | Empty file can not be processed !"
      else
        p '--------else'
		    product_sheet.each_with_index do |row, index|
				if row.compact.empty?
          p '----------'
					break;
				end

				row[100] = ""
				row[21] = ""
				# next if first row
				if index == 0
					row[21] = "Please find the errors below."
					error_hash << row
					next
				end

				# push row into invalid if row is nil
				if row[0].nil?
					row[100] += "0"
					row[21].empty? ? row[21] += "Product Name missing" : row[21] += " ,Product Name missing"
				end
				if row[1].nil?
					row[100] += "1"
					row[21].empty? ? row[21] += "Short Name missing" : row[21] += " ,Short Name missing"
				end
				if row[2].nil?
					row[100] += "2"
					row[21].empty? ? row[21] += "SKU missing" : row[21] += " ,SKU missing"
				end
				if row[4].nil?
					row[100] += "4"
					row[21].empty? ? row[21] += "Product Description missing" : row[21] += " ,Product Description missing"
				end
				if row[5].nil?
					row[100] += "5"
					row[21].empty? ? row[21] += "Highlights missing" : row[21] += " ,Highlights missing"
				end
				if row[6].nil?
					row[100] += "6"
					row[21].empty? ? row[21] += "Whats in a box missing" : row[21] += " ,Whats in a box missing"
				end
				if row[8].nil?
					row[100] += "8"
					row[21].empty? ? row[21] += "Retail price missing" : row[21] += " ,Retail price missing"
				end
				if row[9].nil?
					row[100] += "9"
					row[21].empty? ? row[21] += "Selling Price missing" : row[21] += " ,Selling Price missing"
				end
				if row[11].nil?
					row[100] += "11"
					row[21].empty? ? row[21] += "Brand Name missing" : row[21] += " ,Brand Name missing"
				end
				if row[12].nil?
					row[100] += "12"
					row[21].empty? ? row[21] += "Main category missing" : row[21] += " ,Main category missing"
				end
				if row[13].nil?
					row[100] += "13"
					row[21].empty? ? row[21] += "Sub category missing" : row[21] += " ,Sub category missing"
				end
				if row[14].nil?
					row[100] += "14"
					row[21].empty? ? row[21] += "Sub sub category missing" : row[21] += " ,Sub sub category missing"
				end
				if row[15].nil?
					row[100] += "15"
					row[21].empty? ? row[21] += "Is Adult missing" : row[21] += " ,Is Adult missing"
				end
				if row[16].nil?
					row[100] += "16"
					row[21].empty? ? row[21] += "Weight missing" : row[21] += " ,Weight missing"
				end
				if row[17].nil?
					row[100] += "17"
					row[21].empty? ? row[21] += "Height missing" : row[21] += " ,Height missing"
				end
				if row[18].nil?
					row[100] += "18"
					row[21].empty? ? row[21] += "Width missing" : row[21] += " ,Width missing"
				end
				if row[19].nil?
					row[100] += "19"
					row[21].empty? ? row[21] += "Depth missing" : row[21] += " ,Depth missing. "
				end

				brand = Spree::Brand.find_by_name(row[11])
				if !brand.present?
          row[21].empty? ? row[21] += "Specified Brand not found" : row[21] += " ,Specified Brand not found"
				end

				unless row[21].empty?
					error_hash << row
				end
				if error_hash.present? && !row[21].empty?
					next
        else
          p '---------- second else'
					is_adult = row[15].to_s.downcase == "yes" ? 1 : 0
          gender = row[20].present? ? row[20] : 'NA'
          p gender
          product_hash = {
            :name => row[0],
            :short_name => row[1],
            :sku => row[2],
            :upc => row[3],
            :description => row[4],
            :meta_description => row[5],
            :package_content => row[6],
		        :cost_price => row[7].to_f,
            :price => row[8].to_f,
            :selling_price => row[9].to_f,
            :special_price => row[10].to_f,
            :brand_id => brand.try(:id),
            :is_adult => is_adult,
            :weight => row[16],
            :height => row[17] ,
            :width => row[18],
            :depth => row[19],
            :created_by => current_user.id,
            :updated_by => current_user.id,
            :is_approved => 1,
            :available_on => Time.now.to_date,
            :gender => gender
					}
          p product_hash
					begin
						# create product form product_hash
						Spree::Product.transaction do
							product = seller.products.build(product_hash)
							# Add categories to uploaded product
							main_category = Spree::Taxon.find_by_name(row[12].to_s)
							if main_category.present?
				        sub_category = nil
				        sub_category = main_category.children.find_by_name(row[13].to_s)
				        if sub_category.present?
				          sub_sub_category = nil
				          sub_sub_category = sub_category.children.find_by_name(row[14].to_s)
				          if sub_sub_category.present?
                    p '----- present'
				            product.taxons << sub_sub_category
				            product.save!
				            Delayed::Worker.logger.debug("================== Saved Product")
										Delayed::Worker.logger.debug("#{product}")
                  else
                    p 'not present'
				            row[21].empty? ? row[21] += "Specified Sub sub category not found" : row[21] += " ,Specified sub sub category not found"
				          end
				        else
				          row[21].empty? ? row[21] += "Specified Sub category not found" : row[21] += " ,Specified sub category not found"
				        end
				      else
				        row[21].empty? ? row[21] += "Specified Category not found" : row[21] += " ,Specified Category not found"
				      end
				      error_hash << row if row[21].present?
						end
					rescue Exception => e
						Delayed::Worker.logger.debug("************** Exception Message *******************")
						Delayed::Worker.logger.debug("*********************** #{e.message}**************************")
						Delayed::Worker.logger.debug("*********************** #{e.backtrace.inspect}**************************")
						puts "==================================================================="
						ap e.message
						puts "==================================================================="
						msg = e.message
						row[21].empty? ? row[21] += msg.split(':', 2).last : row[21] += " ,"+msg.split(':', 2).last
						error_hash << row
						next
					end
				end
			end
		end

		Delayed::Worker.logger.debug("#{Time.now} Xls File processing Ends, Row-wise takes time #{Time.now - processing_start_time}")

		Delayed::Worker.logger.debug("================== Error Hash")
		Delayed::Worker.logger.debug("#{error_hash}")

		message = @empty_msg.present? ? @empty_msg : "Channel Manager | Product Import Successful !"
    	body = ""
    	file = nil

    	if error_hash.present? && error_hash.size >= 2
      		message = "Channel Manager | Product Import Failed !"
      		file = ImportJob.generate_excel(error_hash)
    	end
    	end_time = Time.zone.now
    	Spree::DataImportMailer::data_imported(current_user.try(:email), message,seller, file, File.basename(file_path)).deliver

	    Delayed::Worker.logger.debug("=====================Import Products completed")
	end

	# This method will import variants from given excel file
	def self.create_variants(seller,file_path,current_user)
	  @empty_msg = ""
		processing_start_time = Time.zone.now
	  variants = Spreadsheet.open file_path
	  # select first worksheet
	  variant_sheet = variants.worksheet(0)
	  error_hash = []
	  unless variant_sheet.rows.count >= 2
	    @empty_msg = "Channel Manager | Empty file can not be processed !"
	  else
		variant_sheet.each_with_index do |row, index|
	    if row.compact.empty?
			  break;
		  end
		  row[100] = ""
			row[10] = ""
			# next if first row
			if index == 0
				row[10] = "Please find the errors below."
				error_hash << row
				next
			end
			# push row into invalid if row is nil
			if row[0].nil?
				row[100] += "0"
				row[10].empty? ? row[10] += "Master Product sku missing" : row[10] += " ,Master Product sku missing"
			end
			if row[1].nil?
				row[100] += "1"
				row[10].empty? ? row[10] += "Variant SKU missing" : row[10] += " ,Variant SKU missing"
			end
			if row[4].nil?
				row[100] += "4"
				row[10].empty? ? row[10] += "Retail Price missing" : row[10] += " ,Retail Price missing"
			end
			if row[5].nil?
				row[100] += "5"
				row[10].empty? ? row[10] += "Selling Price missing" : row[10] += " ,Selling Price missing"
			end
			if row[7].nil?
				row[100] += "7"
				row[10].empty? ? row[10] += "Option Type missing" : row[10] += " ,Option Type missing"
			end
			if row[8].nil?
				row[100] += "8"
				row[10].empty? ? row[10] += "Option Value missing" : row[10] += " ,Option Value missing"
			end
				
			unless row[10].empty?
				error_hash << row
			end
			if error_hash.present? && !row[10].empty?
				next
			else
				master_variant = Spree::Variant.includes(:product).where(:spree_variants => {:sku => row[0]},:spree_products => {:seller_id => seller.id}).try(:first)
				if master_variant.present?
				  variant_hash = {
			      :sku => row[1],
			      :upc => row[2],
						:cost_price => row[3],
			      :price => row[4],
			      :selling_price => row[5].to_f,
			      :special_price => row[6].to_f,
			      :weight => master_variant.weight,
			      :height => master_variant.height,
			      :width => master_variant.width,
			      :depth => master_variant.depth
					}
					begin
						# create variant from variant_hash
						product = master_variant.product
						if product.kit_id.present?
              row[10].empty? ? row[10] += "You can not add variants to kit products" : row[10] += " ,You can not add variants to kit products"
              error_hash << row if row[10].present?
						else  
							Spree::Variant.transaction do
								variant = product.variants.build(variant_hash)
								# Add option values to uploaded variant
								option_types = Spree::OptionType.where(:presentation => row[7])
								if option_types.present?
								  if product.option_types.empty? || (product.option_types.present? && option_types.first.presentation == product.option_types.first.presentation)
                    product.option_types << option_types if product.option_types.empty? 
                    option_values = Spree::OptionValue.where(:presentation => row[8])
                    if option_values.present?
                      variant.option_values << option_values
                      variant.save!
                    else
                      row[10].empty? ? row[10] += "Option Value with specified presentation name not found" : row[10] += " ,Option Value with specified presentation name not found"
                    end
                  else    
                    row[10].empty? ? row[10] += "You can't add multiple option to the product" : row[10] += " ,You can't add multiple option to the product"
								  end
					      else
					        row[10].empty? ? row[10] += "Option Type with specified presentation name not found" : row[10] += " ,Option Type with specified presentation name not found"
					      end
					      error_hash << row if row[10].present?
							end
						end	
				  rescue Exception => e
							msg = e.message
							row[10].empty? ? row[10] += msg.split(':', 2).last : row[10] += " ,"+msg.split(':', 2).last
							error_hash << row
							next
						end
					else
						row[10].empty? ? row[10] += "Master Variant with specified SKU not found" : row[10] += " ,Master Variant with specified SKU not found"
						error_hash << row if row[10].present?
					end
				end
			end
		end
		message = @empty_msg.present? ? @empty_msg : "Channel Manager | Variant Import Successful !"
    body = ""
    file = nil
  	if error_hash.present? && error_hash.size >= 2
 		  message = "Channel Manager | Variant Import Failed !"
      file = ImportJob.generate_excel(error_hash)
    end
    end_time = Time.zone.now
    Spree::DataImportMailer::data_imported(current_user.try(:email), message,seller, file, File.basename(file_path)).deliver
	end

	# This method will upload images for specified variants in uploaded file
	def self.create_images(seller,file_path,images_path,current_user)
	  @empty_msg = ""
		Delayed::Worker.logger.debug("================ Image creation logs starts at #{Time.now}")

		processing_start_time = Time.zone.now
		Delayed::Worker.logger.debug("#{processing_start_time} Image creation Process Starts at Sec.")

		Delayed::Worker.logger.debug("#{Time.now} Opening Xls File")
	      images = Spreadsheet.open file_path

	    Delayed::Worker.logger.debug("#{Time.now} Xls File Opened")

	    # select first worksheet
	    images_sheet = images.worksheet(0)

	    error_hash = []

	    unless images_sheet.rows.count >= 2
	    	@empty_msg = "Channel Manager | Empty file can not be processed !"
	    else
		    images_sheet.each_with_index do |row, index|
				if row.compact.empty?
					break;
				end

				row[100] = ""
				row[4] = ""
				# next if first row
				if index == 0
					row[4] = "Please find the errors below."
					error_hash << row
					next
				end

				# push row into invalid if row is nil
				if row[0].nil?
					row[100] += "0"
					row[4].empty? ? row[4] += "Master Product/Variant sku missing" : row[4] += " ,Master Product/Variant sku missing"
				end
				if row[2].nil?
					row[100] += "2"
					row[4].empty? ? row[4] += "Image Name missing" : row[4] += " ,Image Name missing"
				end

				unless row[4].empty?
					error_hash << row
				end

				if error_hash.present? && !row[4].empty?
					next
				else
					variant = Spree::Variant.includes(:product).where(:spree_variants => {:sku => row[0]},:spree_products => {:seller_id => seller.id}).try(:first)
					unless row[1].nil?
						is_master = row[1].to_s.downcase == "yes" ? 1 : 0
					else
						is_master = 0
					end

					if variant.present?
						if FileTest.exists?("#{images_path}#{row[2]}")
							begin
								# create image from image_hash
								Spree::Image.transaction do

									image = Spree::Image.create!({:attachment => open("#{images_path}#{row[2]}"), :viewable => variant}, :without_protection => true)
									variant.images << image

									# If product is listed on any MP then add entry for recent change for that MP
									variant.product.market_places.each do |mp|
										#Spree::RecentMarketPlaceChange.create!(:market_place_id => mp.id,:seller_id => seller.id,:product_id => variant.product.id, :updated_by => current_user.id, :variant_id => variant.id, :description => "New Image is uploaded")
									end if variant.product.market_places.present?

									if is_master == 1
										variant.product.master.images << image
									end
								end
							rescue Exception => e
								Delayed::Worker.logger.debug("************** Exception Message *******************")
								Delayed::Worker.logger.debug("*********************** #{e.message}**************************")
								Delayed::Worker.logger.debug("*********************** #{e.backtrace.inspect}**************************")
								puts "==================================================================="
								ap e.message
								puts "==================================================================="
								msg = e.message
								row[4].empty? ? row[4] += msg.split(':', 2).last : row[4] += " ,"+msg.split(':', 2).last
								error_hash << row
								next
							end
						else
							row[4].empty? ? row[4] += "Image with specified name not found in images folder" : row[4] += " ,Image with specified name not found in images folder"
							error_hash << row if row[4].present?
						end
					else
						row[4].empty? ? row[4] += "Master Product/Variant with specified SKU not found" : row[4] += " ,Master Product/Variant with specified SKU not found"
						error_hash << row if row[4].present?
					end
				end
			end
		end


		Delayed::Worker.logger.debug("#{Time.now} Xls File processing Ends, Row-wise takes time #{Time.now - processing_start_time}")

		Delayed::Worker.logger.debug("================== Error Hash")
		Delayed::Worker.logger.debug("#{error_hash}")

		#message = @empty_msg.present? ? @empty_msg : "All Images are imported Successfully from #{File.basename(file_path)}"
		message = @empty_msg.present? ? @empty_msg : "Channel Manager | Image Import Successful !"
    	body = ""
    	file = nil

    	if error_hash.present? && error_hash.size >= 2
      		message = "Channel Manager | Image Import Failed !"
      		file = ImportJob.generate_excel(error_hash)
    	end
    	end_time = Time.zone.now
    	Spree::DataImportMailer::data_imported(current_user.try(:email), message,seller, file, File.basename(file_path)).deliver

		Delayed::Worker.logger.debug("=====================Images Import completed")
	end

	# This method will upload images for specified variants in uploaded file
	def self.update_market_place_details(seller,market_place,file_path,current_user)
	  @empty_msg = ""
		processing_start_time = Time.zone.now
	  mp_details = Spreadsheet.open file_path
	  # select first worksheet
	  mp_details_sheet = mp_details.worksheet(0)
		error_hash = []

    unless mp_details_sheet.rows.count >= 2
	    #@empty_msg = "Empty file can not be processed for updating details"
	    @empty_msg = "Channel Manager | Empty file can not be processed !"
    else
      mp_details_sheet.each_with_index do |row, index|
			if row.compact.empty?
				break;
			end
			row[100] = ""
			row[10] = ""
			# next if first row
			if index == 0
				row[10] = "Please find the errors below."
				error_hash << row
				next
			end
			# push row into invalid if row is nil
			if row[0].nil?
				row[100] += "0"
				row[10].empty? ? row[10] += "Master Product/Variant sku missing" : row[10] += " ,Master Product/Variant sku missing"
			end
			unless row[10].empty?
				error_hash << row
			end
			if error_hash.present? && !row[10].empty?
				next
      else
				variant = Spree::Variant.includes(:product).where(:spree_variants => {:sku => row[0]},:spree_products => {:seller_id => seller.id}).try(:first)
				if variant.present?
				  if row[1].present? || row[2].present? || row[3].present? || row[4].present? || row[5].present? || row[6].present? || row[7].present? || row[8].present?
            product = variant.product
  					market_place_product = Spree::SellersMarketPlacesProduct.where(:seller_id => seller.id, :product_id => product.id, :market_place_id => market_place.id).try(:first)
  					if market_place_product.present?
  					  price_management_hash = {
  						  :selling_price => row[5],
  							:special_price => row[6]
  					  }
  						description_management_hash = {
  						  :description => row[2],
  							:meta_description => row[3],
  							:package_content => row[4]
  						}
  						title_management_hash = {
                :name => row[1]
              }
  						price_management = Spree::PriceManagement.find_by_variant_id_and_market_place_id(variant.id,market_place.id)
  						description_management = Spree::DescriptionManagement.find_by_product_id_and_market_place_id(product.id,market_place.id)
  						title_management = Spree::TitleManagement.find_by_product_id_and_market_place_id(product.id,market_place.id)
  						begin
    						# If retail or cost price present then update it for all market places
  							retail_price = row[7].to_f unless row[7].nil?
  							cost_price = row[8].to_f unless row[8].nil?
              selling_price = row[5].to_f unless row[5].nil?
              special_price = row[6].to_f unless row[6].nil?
  							if retail_price.present? || cost_price.present?
  	  						if variant.update_attributes(:price => retail_price,:cost_price => cost_price, :selling_price => selling_price,:special_price => special_price)
                    #variant.product.market_places.each do |mp|
                    #  desc = ProductJob.get_updated_fields(['cost_price','price'],mp.code)
                    #  Spree::RecentMarketPlaceChange.create!(:market_place_id => mp.id,:seller_id => seller.id,:product_id => variant.product.id, :updated_by => current_user.id, :variant_id => variant.id, :description => desc.join(','),  :update_on_fba=>false)
                    #end
  								end
  							end
                if title_management.present?
                  title_management.update_attributes(title_management_hash.delete_if { |key, value| value.blank? })
                else
                  title_management_hash[:product_id] = variant.product.id
                  title_management_hash[:market_place_id] = market_place.id
                  title_management = Spree::TitleManagement.create!(title_management_hash.delete_if { |key, value| value.blank? })
                end
  					  	if description_management.present?
  						    description_management.update_attributes(description_management_hash.delete_if { |key, value| value.blank? })
  							else
  							  description_management_hash[:product_id] = variant.product.id
  								description_management_hash[:market_place_id] = market_place.id
  								description_management = Spree::DescriptionManagement.create!(description_management_hash.delete_if { |key, value| value.blank? })
  							end
  							# if given variant is master variant then update description only o/w update price also
  							if variant.is_master && variant.product.variants.present?
    							#Spree::RecentMarketPlaceChange.create!(:market_place_id => market_place.id,:seller_id => seller.id,:product_id => variant.product.id, :updated_by => current_user.id, :variant_id => variant.id, :description => "Description updated")
  								unless row[5].nil? && row[6].nil? && row[7].nil? && row[8].nil?
  	  							row[10].empty? ? row[10] += "Price can not be updated for the given SKU as its master SKU, But Description details are updated" : row[10] += " ,Price can not be updated for the given SKU as its master SKU, But Description details are updated"
  									error_hash << row if row[10].present?
  								end
  							else
                  description_management.update_attributes(description_management_hash.delete_if { |key, value| value.blank? })
                  title_management.update_attributes(title_management_hash.delete_if { |key, value| value.blank? })

  								if price_management.present?
  									price_management.update_attributes(price_management_hash.delete_if { |key, value| value.blank? })
  								else
  									price_management_hash[:variant_id] = variant.id
  									price_management_hash[:market_place_id] = market_place.id
  									price_management= Spree::PriceManagement.create!(price_management_hash.delete_if { |key, value| value.blank? })
  								end
  								#Spree::RecentMarketPlaceChange.create!(:market_place_id => market_place.id,:seller_id => seller.id,:product_id => variant.product.id, :updated_by => current_user.id, :variant_id => variant.id, :description => "Description And Prices updated")
  							end
  						rescue Exception => e
    						ap e.message
  							msg = e.message
  							row[10].empty? ? row[10] += msg.split(':', 2).last : row[10] += " ,"+msg.split(':', 2).last
  							error_hash << row
  							next
  						end
            else
  					   row[10].empty? ? row[10] += "Master Product/Variant with specified SKU not listed on selected Market Place" : row[10] += " ,Master Product/Variant with specified SKU not listed on selected Market Place"
  					   error_hash << row if row[10].present?
  				   end
          else
              row[10].empty? ? row[10] += "All fields can't be empty, please add value to change" : row[10] += " ,All fields can't be empty, please add value to change"
              error_hash << row if row[10].present?
            end # End of other field present condition  
        else
  			    row[10].empty? ? row[10] += "Master Product/Variant with specified SKU not found" : row[10] += " ,Master Product/Variant with specified SKU not found"
  				  error_hash << row if row[10].present?
  			  end
	    end
	  end
  end
  message = @empty_msg.present? ? @empty_msg : "Channel Manager | All Details Update Successful !"
  body = ""
  file = nil
 	if error_hash.present? && error_hash.size >= 2
    p error_hash
    message = "Channel Manager | All Details Update Failed !"
   	file = ImportJob.generate_excel(error_hash)
  end
  end_time = Time.zone.now
  Spree::DataImportMailer::data_imported(current_user.try(:email), message,seller, file, File.basename(file_path)).deliver
end
	
	# Method to inflation of quantity of product through excel file
	def self.quantity_inflation(seller,market_place,file_path,current_user)
	  @empty_msg = ""
    processing_start_time = Time.zone.now
    stock_details = Spreadsheet.open file_path
    # select first worksheet
    stock_details_sheet = stock_details.worksheet(0)
    error_hash = []
    unless stock_details_sheet.rows.count >= 2
      @empty_msg = "Channel Manager | Empty file can not be processed !"
    else
      @inflate_quantity_on_mp = {}
      @reset_quantity_to_zero = []
      @sync_quantity_with_fba = []
      stock_details_sheet.each_with_index do |row, index|
        if row.compact.empty?
          break;
        end
        row[100] = ""
        row[5] = ""
        # next if first row
        if index == 0
          row[5] = "Please find the errors below."
          error_hash << row
          next
        end
        # push row into invalid if row is nil
        if row[0].nil?
          row[100] += "0"
          row[5].empty? ? row[5] += "Master Product/Variant sku missing" : row[5] += " ,Master Product/Variant sku missing"
        end
        unless !row[5].present?
          error_hash << row
        end
        if error_hash.present? && row[5].present?
          next
        else
          variant = Spree::Variant.includes(:product).where(:spree_variants => {:sku => row[0]},:spree_products => {:seller_id => seller.id}).try(:first)
          if variant.present?
            product = variant.product
            if row[1].present?
              market_place_product = Spree::SellersMarketPlacesProduct.where(:seller_id => seller.id, :product_id => product.id, :market_place_id => market_place.id).try(:first)
              if market_place_product.present?
                Time.zone = "Singapore"
                current_time = Time.zone.now
                inflate_date = row[3].to_s.to_datetime.in_time_zone("Singapore").end_of_day if row[3].present?
                case row[1]
                  when "Inflate Quantity"
                    if !row[2].present? || !row[3].present? || !row[4].present?
                      row[5].empty? ? row[5] += "Quantity, Promotion end date and Next quantity inflation type must be present" : row[5] += " ,Quantity, Promotion end date and Next quantity inflation type must be present"
                      error_hash << row if row[5].present?
                    elsif row[2].present? && row[2].to_i <= 0
                      row[5].empty? ? row[5] += "Quantity must be a number greater than zero" : row[5] += " ,Quantity must be a number greater than zero"
                      error_hash << row if row[5].present?
                    elsif inflate_date <= current_time
                      row[5].empty? ? row[5] += "Promotion end date must be greater than or equal to current date" : row[5] += " ,Promotion end date must be greater than or equal to current date"
                      error_hash << row if row[5].present?
                    elsif product.variants.present? && variant.is_master
                      row[5].empty? ? row[5] += "You can't changed quantity for master sku, please use variants sku" : row[5] += " ,You can't changed quantity for master sku, please use variants sku"
                      error_hash << row if row[5].present?
                    else  
                      #Update previous quantity from stock product before change
                      qty_inf = Spree::QuantityInflation.where("variant_id=? AND market_place_id=?", variant.id, market_place.id)
                      if qty_inf.present?
                        qty_inf.first.update_attributes(:sku=>row[0], :change_type=>row[1], :next_type=>row[4], :quantity=>row[2].to_i, :end_date=>row[3].to_date.end_of_day)
                      else
                        qty_inf = Spree::QuantityInflation.create(:variant_id=>variant.id, :market_place_id=>market_place.id, :sku=>row[0], :change_type=>row[1], :next_type=>row[4], :quantity=>row[2].to_i, :end_date=>row[3].to_date, :previous_quantity=>0)
                      end    
                      product.update_column(:stock_config_type,1)
                      @inflate_quantity_on_mp.merge!(variant.id=>row[2].to_i)
                    end  
                  when "Reset to Zero"
                    @reset_quantity_to_zero << variant
                  when "Sync with FBA"
                    if product.kit_id.present?
                      row[5].empty? ? row[5] += "Sync with FBA didn't work with Kit product" : row[5] += " ,Sync with FBA didn't work with Kit product"
                      error_hash << row if row[5].present?
                    else
                      if variant.parent_id.present?
                        parent = Spree::Variant.find(variant.parent_id)
                        if parent.product.kit_id.present?
                          row[5].empty? ? row[5] += "Sync with FBA didn't work with Kit product" : row[5] += " ,Sync with FBA didn't work with Kit product"
                        else
                          @sync_quantity_with_fba << parent
                        end

                      end
                      @sync_quantity_with_fba << variant  
                    end
                else 
                  row[5].empty? ? row[5] += "Quantity inflation type is not present" : row[5] += " ,Quantity inflation type is not present"
                  error_hash << row if row[5].present?    
                end
              else
                row[5].empty? ? row[5] += "Master Product/Variant with specified SKU not listed on selected Market Place" : row[5] += " ,Master Product/Variant with specified SKU not listed on selected Market Place"
                error_hash << row if row[5].present?    
              end      
            else
              row[5].empty? ? row[5] += "Quantity inflation type is not present" : row[5] += " ,Quantity inflation type is not present"
              error_hash << row if row[5].present?
            end # End of switch case
          else # end row present
            row[5].empty? ? row[5] += "Master Product/Variant with specified SKU not found" : row[5] += " ,Master Product/Variant with specified SKU not found"
            error_hash << row if row[5].present?
          end # End of variant condition   
        end # End of error hash
      end # End loop stock details sheets
    end # End of Unless stock details row count
    Spree::QuantityInflation.reset_quantity_to_zero(market_place, @reset_quantity_to_zero, seller.id) if @reset_quantity_to_zero.present?
    Spree::QuantityInflation.sync_quantity_with_fba(market_place, @sync_quantity_with_fba, seller.id) if @sync_quantity_with_fba.present?
    Spree::QuantityInflation.inflate_quantity_on_mp(market_place, @inflate_quantity_on_mp, seller.id) if @inflate_quantity_on_mp.present?  
    message = @empty_msg.present? ? @empty_msg : "Channel Manager | All Details Update Successful !"
    body = ""
    file = nil
    if error_hash.present? && error_hash.size >= 2
      message = "Channel Manager | Quantity Inflation Failed !"
      file = ImportJob.generate_excel(error_hash)
    end
    end_time = Time.zone.now
    Spree::DataImportMailer::data_imported(current_user.try(:email), message,seller, file, File.basename(file_path)).deliver
	end

	# This method will generate the excel file of provided hash
	def self.generate_excel(error_hash)
	    errors = Spreadsheet::Workbook.new
	    error = errors.create_worksheet :name => "error_records.xls"
	    error_hash.each_with_index do |err, index|
	      error.row(index).push err[0], err[1], err[2], err[3], err[4], err[5], err[6], err[7], err[8], err[9], err[10], err[11], err[12], err[13], err[14], err[15], err[16], err[17], err[18], err[19], err[20], err[21], err[22], err[23], err[24], err[25], err[26], err[27], err[28], err[29], err[30], err[31], err[32], err[33], err[34]
	    end
	    blob = StringIO.new("")
	    errors.write blob
	    blob.string
 	end
end
