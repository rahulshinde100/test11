require 'spreadsheet'
module Spree
	module Admin
		class StoreAddressesController < Spree::Admin::ResourceController
      before_filter :load_seller, :verify_seller

      #load_and_authorize_resource :store_address, :through => :seller , :only => [:edit, :update]

			def index
				@store_addresses = @seller.stock_locations
			end

			def new
        redirect_to new_admin_stock_location_path(:return => admin_seller_store_addresses_path(@seller))
				return
			end

      def show
        redirect_to edit_admin_seller_store_address_path(@seller)
        return
      end

			def create
				if params[:sample_file].present? && params[:sample_file].content_type == "application/vnd.ms-excel"
        	upload_stores
					redirect_to admin_seller_store_addresses_path(@seller), :notice => "Address successfully added"
					return
				else
					@store_address = @seller.stores.build(params[:store_address])
					if @store_address.save
						@store_address.update_lat_lng
						if spree_current_user.has_spree_role? 'admin'
							redirect_to new_admin_seller_bank_detail_path(@seller), :notice => "Address successfully added"
						else
							redirect_to admin_seller_store_addresses_path(@seller), :notice => "Address successfully added"
						end
					else
						render :new
					end
				end
			end

			def edit
        address = Spree::StoreAddress.find(params[:id])
        unless @seller.id == address.try(:seller).try(:id)
          redirect_to admin_seller_store_addresses_path(@seller), :alert => "No Address found"
          return
        end
			end

			def download_sample
				@store_addresses = @seller.stock_locations.limit(5)
				if @store_addresses.blank?
					dummy_stores =[
						{
							:name 						=> "Anchanto",
							:email 						=> "admin@anchanto.com",
							:phone 					=> "+91 20 6529 4284",
							:address1 				=> "Anchanto Pte Ltd",
              :address2 				=> "4 Leng Kee Road #04-04A SiS Building",
							:city 						=> "Singapore",
							:state 						=> "Singapore",
							:country 					=> "Singapore",
							:zipcode 					=> "159088",
							:operating_hours 	=> "Mon-Fri 09 AM to 06 PM",
							:pickup_at				=> "true",
							:contact_person_name	=> "Shipli Admin"
						}
					]
				end
        
        store_addresses = Spreadsheet::Workbook.new
        store_address = store_addresses.create_worksheet :name => 'store_address'
        store_address.column(0).width = 5

        header_format = Spreadsheet::Format.new :color => 'Gray', :weight => 'bold', :size => 13, :align => 'center', :text_wrap => true, :pattern_fg_color => :black, :pattern => 1
        body_format = Spreadsheet::Format.new :color => 'black', :size => 11, :align => 'center', :text_wrap => true
				
				store_address.row(0).push '#','Name','Email','Contact','Address 1','Address 2','City','State','Country','Zipcode','Operating Hours','Pickup at', 'Contact Person Name'
				if @store_addresses.present?
				
	        @store_addresses.each_with_index do | store, index |
	          store_address.row(index + 1).push (index + 1), store.try(:name), store.try(:email), store.try(:phone), store.try(:address1), store.try(:address2), store.try(:city), store.try(:state), store.try(:country).try(:name), store.try(:zipcode), store.try(:operating_hours),(store.pickup_at ? "true" : "false"), store.contact_person_name
	          store_address.row(index + 1).set_format(5,body_format)
	        end
	      else
	      	dummy_stores.each_with_index do | store, index |
	          store_address.row(index + 1).push (index + 1), store[:name], store[:email], store[:phone], store[:address1], store[:address2], store[:city], store[:state], store[:country], store[:zipcode], store[:operating_hours],store[:pickup_at], store[:contact_person_name]
	          store_address.row(index + 1).set_format(5,body_format)
	        end
	      end
        blob = StringIO.new("")
        store_addresses.write blob
        store_address.row(0).default_format = header_format
        #respond with blob object as a file
        send_data blob.string, :type => :xls, :filename => "#{@seller.name}_sample_stores.xls" 
        return
			end

			def update
				@store_address = Spree::StoreAddress.find(params[:id])
				if @store_address.update_attributes(params[:store_address])
					@store_address.update_lat_lng
					redirect_to admin_seller_store_addresses_path(@seller), :notice => "Address successfully updated"
				else
					redirect_to admin_seller_store_addresses_path(@seller), :notice => "Oops! Something wrong"
				end
			end

			def destroy
				@store_address = Spree::StoreAddress.find(params[:id])
				@store_address.destroy
				redirect_to admin_seller_store_addresses_path(@seller), :notice => "Address successfully deleted"
			end

      private
      def load_seller        
        @seller = Spree::Seller.find_by_permalink(params[:seller_id])
      end



		end	
	end
end
