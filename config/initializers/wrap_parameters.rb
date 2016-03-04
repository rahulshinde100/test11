# Be sure to restart your server when you modify this file.
#
# This file contains settings for ActionController::ParamsWrapper which
# is enabled by default.

# Enable parameter wrapping for JSON. You can disable this by setting :format to an empty array.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters format: [:json]
end

# Disable root element in JSON by default.
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
end

# Report Types
REPORTTYPES = [{:id=>1, :name=>"Weekly Report"}, {:id=>2, :name=>"Monthly Report"}, {:id=>3, :name=>"Invoicing by Cart Number"}]

# Setting Hash for stock configuration
STOCKCONFIG = {0=>"default", 1=>"fixed_quantity", 2=>"percentage_quantity", 3=>"flat_quantity"}

# Setting Hash for stock options
STOCKOPTION = {1=>"stock_import", 2=>"stock_export"}

QOO10CHECKLIST = {:update_goods=>{:upg1 => 'category', :upg2 => 'name', :upg3 =>'price' ,:upg4 => 'shipping_code'}, :goods_status => {},
                  :goods_contents => {:gc1 => 'description'}, :goods_price => {:gp1 => 'selling_price', :gp2 => 'product_special_price'}, :goods_image => { :gimg1 => 'attachment_file_name', :gimg2 => 'new_image'},
                  :update_inventory_data_unit => {:uidu1 => 'selling_price', :uidu2 => 'qty', :uidu3 => 'cost_price', :uidu5 => 'option_type'},
                  :insert_inventory_data_unit => {:insidu1 => 'new_variant'}
}

LAZADACHACKLIST = {:description => 'description', :name => 'name', :height => 'height', :width =>'width', :depth =>'depth', :weight => 'weight', :brand =>'brand_id',:category => 'category', :new_variant => 'new_variant', :price => 'price',
                   :selling_price => 'selling_price', :special_price => 'special_price',  :sku =>'sku', :sale_start_date => 'sale_start_date', :short_desc => 'meta_description',:package_content => 'package_content', :image_update => 'attachment_file_name', :new_image => 'new_image'}

ZALORACHACKLIST = {:description => 'description', :name => 'name', :brand =>'brand_id',:category => 'category', :new_variant => 'new_variant', :price => 'price',
                   :selling_price => 'selling_price', :special_price => 'special_price', :sku =>'sku', :sale_start_date => 'sale_start_date', :image_update => 'attachment_file_name', :new_image => 'new_image'}


UPDATEMESSAGE = {:upg1 => 'Sub category has changed', :upg2 => 'Product Title has changed', :upg3 => "Retail Price has changed", :upg4 => 'Special Price has changed', :upg5 => 'Seller Code(sku) has changed' , :uidu5 => 'Option type has changed',
                 :gc1 =>'Product Description has changed', :gp1 => 'Item price has changed',:gp2=> 'Product special Price has changed', :upg4 => 'Special Price has changed', :gimg1 => 'Image has changed', :gimg2 => 'New Image added', :new_variant => 'New variant Added', :uidu4 => 'special has price changed', :uidu1 => 'selling price has changed',
                 :description =>'Product Description has changed', :desc => 'Product Description has changed', :name => 'Product Name has changed', :height => 'Height has changed', :width =>'Width has changed', :depth =>'Length has changed', :weight => 'Weight has changed', :brand =>'Brand has changed',:category => 'category',
                 :selling_price => 'selling price has changed', :special_price => 'Special price has changed', :settlement_price => 'Settlement price has changed', :sku =>'New variant Added',
                 :sale_start_date => 'Sale Start Date has changed', :short_desc => 'Short Description has changed',:package_content => 'Package Content has changed', :image_update => 'Image has changed', :gimg2 => 'New Image Added', :new_image => 'New Image has added', :price => 'Retails Price has changed', :insidu1 => 'New variant has added'
}