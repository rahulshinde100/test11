module Spree
  module Admin
    class SellerMarketPlacesController < Spree::Admin::ResourceController

      before_filter :authenticate_spree_user!
      load_and_authorize_resource :class => Spree::SellerMarketPlace
      before_filter :load_seller

      def index
        @seller_market_places = @seller.seller_market_places
        @seller_market_places = Kaminari.paginate_array(@seller_market_places).page(params[:page]).per(Spree::Config[:admin_products_per_page])
      end

      def new
        @seller_market_place = @seller.seller_market_places.new
      end

      def create
         @seller_market_place = Spree::Seller.find_by_permalink(params[:seller_id]).seller_market_places.new(params[:seller_market_place])
         if !@seller_market_place.seller.seller_market_places.find_by_market_place_id(params[:seller_market_place] [:market_place_id]).present?
          if @seller_market_place.save!
            redirect_to admin_seller_seller_market_places_path(Spree::Seller.find_by_permalink(params[:seller_id]).id), :notice => "Market Place added successfully"
          else
            render :new
          end
        else
          redirect_to admin_seller_seller_market_places_path(Spree::Seller.find_by_permalink(params[:seller_id]).id), :notice => "Oops..Already map this market place"
        end
      end

      def edit
        @seller_market_place = @seller.seller_market_places.find(params[:id])
      end

      def update
        @seller_market_place = Spree::Seller.find_by_permalink(params[:seller_id]).seller_market_places.find(params[:id])
       if !@seller_market_place.seller.seller_market_places.find_by_market_place_id(params[:seller_market_place][:market_place_id]).present?
        if @seller_market_place.update_attributes(params[:seller_market_place])
          redirect_to admin_seller_seller_market_places_path(Spree::Seller.find_by_permalink(params[:seller_id]).id), :notice => "Market Place updated successfully"
        else
          render "edit"
        end
       else
         if @seller_market_place.update_attributes(params[:seller_market_place])
           redirect_to admin_seller_seller_market_places_path(Spree::Seller.find_by_permalink(params[:seller_id]).id), :notice => "Updated successfully"
         end
       end
      end

      def generate_api_secret_key
        @message = ""
        @seller_market_place = SellerMarketPlace.where(:id=>params[:secret_key][:id])
        @seller_market_place = @seller_market_place.first if !@seller_market_place.blank?
        if !@seller_market_place.blank? && !@seller_market_place.api_key.nil?
          case @seller_market_place.market_place.code
          when "qoo10"
            uri = URI('http://api.qoo10.sg/GMKT.INC.Front.OpenApiService/Certification.api/CreateCertificationKey')
            req = Net::HTTP::Post.new(uri.path)
            req.set_form_data({'key'=>params[:secret_key][:api_key],'user_id'=>params[:secret_key][:user_id],'pwd'=>params[:secret_key][:password]})
            res = Net::HTTP.start(uri.hostname, uri.port) do |http|http.request(req)end
            if res.code == "200"
              res_body = Hash.from_xml(res.body).to_json
              res_body = JSON.parse(res_body, :symbolize_names=>true)
              if res_body[:StdCustomResultOfString][:ResultObject].present?
                secret_key = res_body[:StdCustomResultOfString][:ResultObject]
                @message = "API secret key generated successfully"
              else
                @message = "API secret key can not be generated, please check login details."
              end
            end
          when "lazada", "zalora"
              secret_key = @seller_market_place.api_key
              @message = "API secret key generated successfully"
          end
          @seller_market_place.update_attributes(:api_secret_key => secret_key) if secret_key
        elsif !@seller_market_place.blank? && @seller_market_place.api_key.nil?
          @message = "Please add market place api key"
        end
        flash[:success] = @message if @message.length > 0
        redirect_to :back
      end

      def load_form_generate_api_secret_kay
        @seller_market_place = SellerMarketPlace.where(:id=>params[:id])
        @seller_market_place = @seller_market_place.first if !@seller_market_place.blank?
        respond_to do |format|
          format.html { render :partial=>"generate_api_secret_key_form"}
        end
      end

      private
      def load_seller
        @seller = Spree::Seller.find_by_id(params[:seller_id])
      end

      # Added by Tejaswini Patil
      # To Add Ability
      def model_class
        SellerMarketPlace
      end

    end
  end
end



