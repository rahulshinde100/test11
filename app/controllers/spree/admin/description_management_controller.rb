module Spree
  module Admin
    class DescriptionManagementController < Spree::Admin::BaseController
      authorize_resource :class => Spree::DescriptionManagement
      respond_to :html

      def update
        @description_management = Spree::DescriptionManagement.find(params[:id])
        if @description_management.present?
           market_place_id = @description_management.market_place_id
           description = params[:description][market_place_id.to_s]
           meta_description = params[:meta_description][market_place_id.to_s]
           package_content = params[:package_content][market_place_id.to_s]
           product_id = @description_management.product_id
           begin
             if @description_management.update_attributes(:market_place_id => market_place_id, :product_id => product_id, :description => description, :meta_description => meta_description, :package_content => package_content)
               # case @description_management.market_place.code
               #   when "qoo10"
               #     # @description_management.update_description_to_qoo10
               #   when "lazada"
               #     # @description_management.update_description_to_lazada
               # end
               flash[:notice] = "Description updated successfully"
               redirect_to :back
             else
               flash[:error] = "Description not updated, all fields are mandatory."
               redirect_to :back
             end
           rescue Exception => e
             flash[:error] = e.message
             redirect_to :back
           end
        else
           flash[:error] = "Description not updated"
           redirect_to :back
        end
      end

       private
        def model_class
          DescriptionManagement
        end

    end
  end
end
