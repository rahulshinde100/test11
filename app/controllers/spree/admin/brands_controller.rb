module Spree
	module Admin
		class BrandsController < ResourceController
			def index
				session[:return_to] = request.url

				respond_with(@collection) do |format|
	      	format.html {}
	      	format.pdf do
	        	render :pdf => "brands"
	      	end
          format.xls {
            brands = Spreadsheet::Workbook.new
            brand = brands.create_worksheet :name => 'brands'
            header_format = Spreadsheet::Format.new :color => 'green', :weight => 'bold', :size => 12, :align => 'centre'

            brand.row(0).concat %w{# Name Description Logo Banner}
            brand.row(0).default_format = header_format

            Spree::Brand.all.each_with_index do |brnd, index|
              brand.row(index+1).push (index+1), brnd.name, brnd.description
            end
            blob = StringIO.new("")
            brands.write blob
            #respond with blob object as a file
            send_data blob.string, :type => :xls, :filename => 'brands.xls'
            return
          }
    		end    
			end
			def upload_brands
				unless File.extname(params[:attachment].original_filename) == ".zip"
          flash[:error] = "Please upload a valid zip file"      
          redirect_to :action => :index
          return
        end
      
        tmp = params[:attachment].tempfile
        filename =  params[:attachment].original_filename.gsub('.zip','')
      
        #create a new dir in tmp if not exist
        create_import_data_dir("#{DATASHIFT_PATH}")
        
        file = File.join("#{DATASHIFT_PATH}", params[:attachment].original_filename)
        FileUtils.cp tmp.path, file
        
        unless extract(tmp.path)
          flash[:error] = "Oops somethinf went wrong.."      
          redirect_to :action => :index
          return
        end    
        brands = Spreadsheet.open "#{DATASHIFT_PATH}/#{filename}/brands_import_with_images.xls"
        brand_sheet = brands.worksheet(0)    
        file_path = "#{DATASHIFT_PATH}/#{filename}/images/"

        brand_sheet.each_with_index do |row, index|
        	next if index == 0 || row[1].nil?
        	@brand = Spree::Brand.find_by_name(row[1].to_s)
        	next if @brand.present?
      		brand = Spree::Brand.create({:name => row[1], :description => row[2]})
          brand.logo = open("#{file_path}#{row[3]}") if FileTest.exists?("#{file_path}#{row[3]}")
          brand.logo = open("#{file_path}#{row[4]}") if FileTest.exists?("#{file_path}#{row[4]}")
          brand.save
        end
        FileUtils.rm_rf("#{DATASHIFT_PATH}/#{filename}/.", secure: true)    
        flash[:notice] = "Brands uploaded successfully"
        redirect_to admin_brands_url
			end
		protected
		 	def collection
	      return @collection if @collection.present?
	      params[:q] ||= {}
	      params[:q][:deleted_at_null] ||= "1"

	      params[:q][:s] ||= "name asc"
	      @collection = super
	      @collection = @collection.with_deleted if params[:q].delete(:deleted_at_null).blank?
	      
	      # @search needs to be defined as this is passed to search_form_for
	      @search = @collection.ransack(params[:q])
	      @collection = @search.result.page(params[:page]).per(Spree::Config[:admin_products_per_page])
	      @collection
    	end
    	
    	def extract(zip_file)
        begin
          Archive::Zip.extract(zip_file, DATASHIFT_PATH, :symlinks => false, :directories => false)
          return true
        rescue Exception => e
          Rails.logger.info "===============================================\n #{e.message}"
          FileUtils.rm_rf("#{DATASHIFT_PATH}/#{filename}/.", secure: true)    
          #TODO
          #SEND EMAIL TO ADMIN ABOUT ERROR LOG
          return false
        end
      end
      def find_resource
        Brand.find_by_permalink!(params[:id])
      end

      def create_import_data_dir(directory_name)
        Dir.mkdir(directory_name) unless File.exists?(directory_name)
      end      
		end
	end
end
