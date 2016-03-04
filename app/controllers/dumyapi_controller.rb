class DumyapiController < ApplicationController
	respond_to :xml, :json

	def sign_up
		@user = {"id" => 1, "user_token" => "gswjgd3hjkdhewjnfej"}
		respond_to do |format|
    		format.json { render :json => @user }
    	end
	end

	def sign_in
		if params[:user][:email] == "user@ship.li" && params[:user][:password] == "ship.li@123"
        	@user = {"id" => 2,"authentication_token" => "OlZnirQb8gTy-ElaDSVo","firstname" => "abc","lastname" => "xyz","email" => "user@ship.li","spree_api_key" => "01693ed74d107c9864ceefb6bf0c08d4272ec2e8ace5473b"}
		else
			@user = {"error" => "You are not authorized to perform that action."}
		end
		respond_to do |format|
    		format.json { render :json => @user }
    	end
	end

	def social_sign_up
		@user = {"id" => 1, "user_token" => "gswjgd3hjkdhewjnfej"}
		respond_to do |format|
    		format.json { render :json => @user }
    	end
	end

	def forget_password
		if params[:user][:email] == "user@ship.li"
			@status = {:msg => "Reset password instructions sent to your email"}
		else
			@status = {:msg => "Record not found"}
		end
		respond_to do |format|
    		format.json { render :json => @status }
    	end
	end

# 	def order_history
# 		resp = {"count" =>2 ,"current_page" => 1,"orders" => [{"id"=>4,"number"=>"R488726352","item_total"=>"35.98","total"=>"42.78","state"=>"complete","adjustment_total"=>"6.8","user_id"=>1,"created_at"=>"2013-06-28T10:01:44Z","updated_at"=>"2013-06-28T10:05:02Z","completed_at" => "2013-06-28T10:05:02Z","payment_total" => "0.0","shipment_state" => "pending","payment_state" => "balance_due","email" => "spree@example.com","special_instructions" => nil,"products"=>[{"id"=>1,"name"=>"Ruby on Rails Tot e":desc ri:ion"=> "L:o =e volup =atibus vo =uptatem aut  es: Voluptates et fugi = vel qui. Et hic quidem repellendus perferendis sint facilis. Qui eligendi suscipit nemo. Ea officiis est sit.","price"=>"15.99","available_on"=>"2013-06-13T 11:52:51Z","permalink" => "r:y-on-rails-t ot:,"m =ta_description" => nil,"meta_keywords" => nil,"taxon_ids" => [8],"variants" => [{"id" => 1,"name" => "Ruby on Rails Tote","sku" => "ROR-00011","price" => "15.99","weight" => nil,"height" => nil,"width" => nil,"depth" => nil,"is_master" => true,"cost_price" => "17.0","permalink" => "ruby-on-rails-tote","option_values" => [],"images" => [{"id" => 21,"position" => 1,"attachment_content_type" => "image/jpeg","attachment_file_name" => "ror_tote.jpeg","type" => "Spree::Image","attachment_updated_at" => "2013-06-13T11:53:27Z","attachment_width" => 360,"attachment_height" => 360,"alt":nil,"viewable_type" => "Spree::Variant","viewable_id" => 1,"attachment_url" => "/spree/products/21/product/ror_tote.jpeg?1371124407"},{"id" => 22,"position" => 2,"attachment_content_type" => "image/jpeg","attachment_file_name" => "ror_tote_back.jpeg","type" => "Spree::Image","attachment_updated_at" => "2013-06-13T11:53:28Z","attachment_width" => 360,"attachment_height" => 360,"alt" => nil,"viewable_type" => "Spree::Variant","viewable_id" => 1,"attachment_url" => "/spree/products/22/product/ror_tote_back.jpeg?1371124408"}]}],"option_types" => [],"product_properties" => [{"id" => 25,"product_id" => 1,"property_id" => 9,"value" => "Tote","property_name" => "Type"},{"id"=>26,"product_id"=>1,"property_id"=>10,"value"=>"15\" x 18\" x 6\"","property_name"=>"Size"},{"id"=>27,"product_id"=>1,"property_id"=>11,"value"=>"Canvas","property_name"=>"Material"}]},{"id"=>5,"name"=>"Ruby on Rails Ringer T-Shirt","description"=>"Labore voluptatibus voluptatem aut est. Voluptates et fugit vel qui. Et hic quidem repellendus perferendis sint facilis. Qui eligendi suscipit nemo. Ea officiis est sit.","price"=>"19.99","available_on"=>"2013-06-13T11:52:51Z","permalink"=>"ruby-on-rails-ringer-t-shirt","meta_description"=>nil,"meta_keywords"=>nil,"taxon_ids"=>[12],"variants"=>[{"id"=>5,"name"=>"Ruby on Rails Ringer T-Shirt","sku"=>"ROR-00015","price"=>"19.99","weight"=>nil,"height"=>nil,"width"=>nil,"depth"=>nil,"is_master"=>true,"cost_price"=>"17.0","permalink"=>"ruby-on-rails-ringer-t-shirt","option_values"=>[],"images"=>[{"id"=>29,"position"=>1,"attachment_content_type"=>"image/jpeg","attachment_file_name"=>"ror_ringer.jpeg","type"=>"Spree=>:Image","attachment_updated_at" => "2013-06-13T11:53:37Z","attachment_width" => 360,"attachment_height" => 360,"alt" => nil,"viewable_type" => "Spree::Variant","viewable_id" => 5,"attachment_url" =>"/spree/products/29/product/ror_ringer.jpeg?1371124417"},{"id" => 30,"position" => 2,"attachment_content_type" => "image/jpeg","attachment_file_name" => "ror_ringer_back.jpeg","type" => "Spree::Image","attachment_updated_at" => "2013-06-13T11:53:38Z","attachment_width" => 360,"attachment_height" => 360,"alt" => nil,"viewable_type" => "Spree::Variant","viewable_id" => 5,"attachment_url":"/spree/products/30/product/ror_ringer_back.jpeg?1371124418"}]}],"option_types" => [],"product_properties":[{"id" => 17,"product_id" => 5,"property_id" => 1,"value":"Jerseys","property_name":"Manufacturer"},{"id":18,"product_id":5,"property_id" => 2,"value":"Conditioned","property_name":"Brand"},{"id":19,"product_id":5,"property_id" => 3,"value":"TL9002","property_name":"Model"},{"id" => 20,"product_id" => 5,"property_id" => 4,"value" => "Ringer T","property_name" => "Shirt Type"},{"id" => 21,"product_id" => 5,"property_id" => 5,"value" => "Short","property_name" => "Sleeve Type"},{"id" => 22,"product_id" => 5,"property_id" => 6,"value" => "100% Vellum","property_name" => "Made from"},{"id" => 23,"product_id" => 5,"property_id" => 7,"value" => "Loose","property_name" => "Fit"},{"id" => 24,"product_id" => 5,"property_id" => 8,"value" => "Men's",
# "property_name" => "Gender"}]}]},{"id" => 5,"number" => "R788314730","item_total" => "0.0","total" => "0.0","state" => "cart","adjustment_total" => "0.0","user_id" => 1,"created_at" => "2013-06-28T10:05:03Z","updated_at" => "2013-06-28T10:05:03Z","completed_at" => nil,"payment_total" => "0.0","shipment_state" => nil,"payment_state" => nil,"email" => "spree@example.com","special_instructions" => nil,"products" => []}]}
# 		respond_to do |format|
#     		format.json { render :json => @status }
#     	end
# 	end

	def terms_conditions
		@terms_conditions = {:contents => "There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour, or randomised words which don't look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn't anything embarrassing hidden in the middle of text. All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The generated Lorem Ipsum is therefore always free from repetition, injected humour, or non-characteristic words etc."}
		respond_to do |format|
    		format.json { render :json => @terms_conditions }
    	end
	end

	def logout
		@status = {:msg => "logout successfuly"}
		respond_to do |format|
    		format.json { render :json => @status }
    	end
	end

	def products
	products = []
  60.times do |i|
    
  o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
  string  =  (0...8).map{ o[rand(o.length)] }.join
  products << 
    {
      "id" => i + 1,
      "name" => "Example product - #{string.upcase}",
      "description" => "Description- #{string.upcase}",
      "price" => "15.99",
      "available_on" => "2012-10-17T03:43:57Z",
      "permalink" => "ruby-on-rails-tote",
      "count_on_hand" => 10,
      "meta_description" => nil,
      "meta_keywords" => nil,
      "product_rate" => 3,
      "variants" => [
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
	    {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_url" => "/spree/products/21/product/ror_tote.jpeg?1372916151",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
	    {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        },
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
	    {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
	    {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        }
      ],
      "product_properties" => [
        {
          "id" => 1,
          "product_id" => 1,
          "property_id" => 1,
          "value" => "Tote",
          "property_name" => "bag_type"
        },
	{
          "id" => 2,
          "product_id" => 1,
          "property_id" => 2,
          "value" => "Tote",
          "property_name" => "bag_type"
        }
      ],
"store_locations" =>[
	{
	      "id" => 1,
	      "name" => "default",
	      "address1" => "7735 Old Georgetown Road",
	      "address2" => "Suite 510",
	      "city" => "Bethesda",
	      "state_id" => 26,
	      "country_id" => 49,
	      "zipcode" => "20814",
	      "phone" => "",
	      "active" => true,
        "lat" => 21.9,
        "long" => 23.7
     },
    {
	      "id" => 1,
	      "name" => "default",
	      "address1" => "7735 Old Georgetown Road",
	      "address2" => "Suite 510",
	      "city" => "Bethesda",
	      "state_id" => 26,
	      "country_id" => 49,
	      "zipcode" => "20814",
	      "phone" => "",
	      "active" => true,
        "lat" => 21.9,
        "long" => 23.7
     },
	
  ],
  "product_reviews" =>[
   	{
		"review_id" => 1,
		"review_date" => "2012-10-17T03:43:57Z",
		"review_rate" => 4,
		"review_comment" => "nice product",
		"category" => "abc",
		"seller_name" => "",
		"product_name" => "Example product",
		"product_id" => "1"
	},
	{	
		"review_id" => 1,
		"review_date" => "2012-10-17T03:43:57Z",
		"review_rate" => nil,
		"review_comment" => "nice product",
		"category" => "abc",
		"seller_name" => "seller name",
		"product_name" => "Example product",
		"product_id" => "1"

	}


  ],
    "product_seller" =>
	{
		"seller_id" => 1,
		"seller_name" => "Nike",
		"seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
	}
    
    }
  
  end

render :json => {:products => products,  "count" => 60,"pages" => 5,"current_page" => 1}.to_json
return
	end
  
  def taxonomies
  taxonomies = []
  5.times do |i|
    
  o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
  string  =  (0...8).map{ o[rand(o.length)] }.join
  taxonomies << 
             {
              "id"=> i + 1,
              "name"=> "Clothing- #{string.upcase}",
              "root"=> {
                "id"=> 2,
                "name"=> "Shirts",
                "permalink"=> "Clothing/Shirts",
                "position"=> 1,
                "parent_id"=> 1,
                "taxonomy_id"=> 1,
                "taxons"=> [
                  {
                    "id"=> 3,
                    "name"=> "T-Shirts",
                    "permalink"=> "Clothing/Shirts/t-shirts",
                    "position"=> 1,
                    "parent_id"=> 2,
                    "taxonomy_id"=> 1
                  },
                  {
                    "id"=> 3,
                    "name"=> "formal",
                    "permalink"=> "Clothing/Shirts/t-shirts/formal",
                    "position"=> 1,
                    "parent_id"=> 2,
                    "taxonomy_id"=> 1
                  }
                ]
              }
            }
        end
 render :json => {:taxonomies => taxonomies, :count => 5}.to_json
 return
end

  def product_search
  products = []
  10.times do |i|
    
  o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
  string  =  (0...8).map{ o[rand(o.length)] }.join
  products << 
    {
      "id" => i + 1,
      "name" => "Example product - #{string.upcase}",
      "description" => "Description- #{string.upcase}",
      "price" => "15.99",
      "available_on" => "2012-10-17T03:43:57Z",
      "permalink" => "ruby-on-rails-tote",
      "count_on_hand" => 10,
      "meta_description" => nil,
      "meta_keywords" => nil,
      "product_rate" => 3,
      "variants" => [
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
	    {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
	    {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        },
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
	    {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
	    {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        }
      ],
      "product_properties" => [
        {
          "id" => 1,
          "product_id" => 1,
          "property_id" => 1,
          "value" => "Tote",
          "property_name" => "bag_type"
        },
	{
          "id" => 2,
          "product_id" => 1,
          "property_id" => 2,
          "value" => "Tote",
          "property_name" => "bag_type"
        }
      ],
"store_locations" =>[
	{
	      "id" => 1,
	      "name" => "default",
	      "address1" => "7735 Old Georgetown Road",
	      "address2" => "Suite 510",
	      "city" => "Bethesda",
	      "state_id" => 26,
	      "country_id" => 49,
	      "zipcode" => "20814",
	      "phone" => "",
	      "active" => true,
        "lat" => 21.9,
        "long" => 23.7
     },
    {
	      "id" => 1,
	      "name" => "default",
	      "address1" => "7735 Old Georgetown Road",
	      "address2" => "Suite 510",
	      "city" => "Bethesda",
	      "state_id" => 26,
	      "country_id" => 49,
	      "zipcode" => "20814",
	      "phone" => "",
	      "active" => true,
        "lat" => 21.9,
        "long" => 23.7
     },
	
  ],
  "product_reviews" =>[
   	{
		"review_id" => 1,
		"review_date" => "2012-10-17T03:43:57Z",
		"review_rate" => 4,
		"review_comment" => "nice product",
		"category" => "abc",
		"seller_name" => "",
		"product_name" => "Example product",
		"product_id" => "1"
	},
	{	
		"review_id" => 1,
		"review_date" => "2012-10-17T03:43:57Z",
		"review_rate" => nil,
		"review_comment" => "nice product",
		"category" => "abc",
		"seller_name" => "seller name",
		"product_name" => "Example product",
		"product_id" => "1"

	}


  ],
    "product_seller" =>
	{
		"seller_id" => 1,
		"seller_name" => "Nike",
		"seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
	}
    
    }
  
  end

  render :json => {:products => products,  "count" => 10,"pages" => 5,"current_page" => 1}.to_json
  return
  end
  
  def user_profile
    @user = {
              "user_id" => "456",
              "first_name" => "apple",
              "last_name" => "user",
              "date_of_birth" => "2012-10-17",
              "contact_number" => "63547654757",
              "country" => "Singapore"
              }
    render :json => {:user => @user}
  end
  
  def order_history
    orders = []
  5.times do |i|
    
  o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
  string  =  (0...8).map{ o[rand(o.length)] }.join
  
      orders << { 
                  "order_number"  => i+2,
                  "order_date"  => "2012-10-17T03:43:57Z",
                  "order_payment_status" => nil ,
                  'order_Delivery_status' => nil ,
                  "order_Total_amount" => "0.0",
                  "order_payment_type" => "credit card",
                  "order_discount_received" => "5.809",
                  "order_delevery_details" => nil,
                  "Products" => [
                              {
                              "product_id" => i + 5 ,
                              "product_name" => "my product - #{string.upcase}" ,
                              "product_quantity" => 6 ,
                              "product_price" => "67" ,
                              "product_details" => nil,
                              "product_variants" =>  [
                                                  {
                                                    "id" => i + 4 ,
                                                    "name" => "sndbhs",
                                                    "count_on_hand" => "my varient - #{string.upcase}" ,                                                    "sku" => "RTJHN534347" ,
                                                    "price" => "67" ,
                                                    "weight" => "67" ,
                                                    "height" => "67",
                                                    "width" => "67",
                                                    "depth" =>"67" ,
                                                    "is_master" => true,
                                                    "cost_price" => "67",
                                                    "permalink" => "xyz/tyui",
                                                    "option_values" => [
                                                                    {
                                                                      "id" => 445 ,
                                                                      "name" => "my option" ,
                                                                      "presentation" => "#{string.upcase}" ,
                                                                      "option_type_name" => "name",
                                                                      "option_type_id" => 547657865
                                                                    }
                                                                  ],
                                                          "images" => [
                                                            {
                                                              "id" => 56,
                                                              "position" => 4,
                                                              "attachment_content_type" => "jpeg" ,
                                                              "attachment_file_name" => "my_attachment",
                                                              "type" => nil,
                                                              "attachment_updated_at" => "2012-10-17T03:43:57Z" ,
                                                              "attachment_width" =>  "764",
                                                              "attachment_height" => "87" ,
                                                              "alt" => "abc",
                                                              "viewable_type" => nil,
                                                              "viewable_id" => 44
                                                            }
                                                          ]
                                                        }
                                                      ]
                                                     }
                                                    ]
                                                   }

       end
       render :json => {:orders => orders, :count => 5}
  end
  
  def review_list
   
                   product_reviews = [
                       {
                            "review_id" => 435,
                            "review_date" => "2012-10-17T03=>43=>57Z",
                            "review_time" => "2012-10-17T03=>43=>57Z",
                            "review_rate" => 5,
                            "review_comment" => "nice ",
                            "category" => "my category",
                            "seller_name" => "nike",
                            "product_name" => "my product",
                            'product_id' => 324

                       }
                       ]
                   seller_reviews = [
                                    {
                                      "review_id" => 4535,
                                      "review_date" => "2012-10-17T03:43:57Z",
                                      "review_time" => "2012-10-17T03:43:57Z",
                                      "review_rate" => 4,
                                      "review_comment" => "nice product",
                                      "category" => "clothes",
                                      "seller_name" => "Adidas",
                                      "product_name" => "My T shirt",
                                      "product_id" => 758

                                    }

                                    ]
                      
    render :json => {:product_reviews => product_reviews,:seller_reviews => seller_reviews}
  end
  
  def delete_review
    render :json => {:response => "deleted successfuly"}
  end
  
  def wishlist
        products = []
        2.times do |i|

        o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
        string  =  (0...8).map{ o[rand(o.length)] }.join
        products << 
          {
            "id" => i + 1,
            "name" => "Example product - #{string.upcase}",
            "description" => "Description- #{string.upcase}",
            "price" => "15.99",
            "available_on" => "2012-10-17T03:43:57Z",
            "permalink" => "ruby-on-rails-tote",
            "count_on_hand" => 10,
            "meta_description" => nil,
            "meta_keywords" => nil,
            "product_rate" => 3,
            "variants" => [
              {
                "id" => 1,
                "name" => "Ruby on Rails Tote",
                "count_on_hand" => 10,
                "sku" => "ROR-00011",
                "price" => "15.99",
                "weight" => nil,
                "height" => nil,
                "width" => nil,
                "depth" => nil,
                "is_master" => true,
                "cost_price" => "13.0",
                "permalink" => "ruby-on-rails-tote",
                "option_values" => [
                  {
                    "id" => 1,
                    "name" => "Small",
                    "presentation" => "S",
                    "option_type_name" => "tshirt-size",
                    "option_type_id" => 1
                  },
            {
                    "id" => 2,
                    "name" => "medium",
                    "presentation" => "m",
                    "option_type_name" => "tshirt-size",
                    "option_type_id" => 1
                  }
                ],
                "images" => [
                  {
                    "id" => 1,
                    "position" => 1,
                    "attachment_content_type" => "image/jpg",
                    "attachment_file_name" => "ror_tote.jpeg",
                    "type" => "Spree::Image",
                    "attachment_updated_at" => nil,
                    "attachment_width" => 360,
                    "attachment_height" => 360,
                    "alt" => nil,
                    "viewable_type" => "Spree::Variant",
                    "viewable_id" => 1
                  },
            {
                    "id" => 2,
                    "position" => 2,
                    "attachment_content_type" => "image/jpg",
                    "attachment_file_name" => "ror_tote.jpeg",
                    "type" => "Spree::Image",
                    "attachment_updated_at" => nil,
                    "attachment_width" => 360,
                    "attachment_height" => 360,
                    "alt" => nil,
                    "viewable_type" => "Spree::Variant",
                    "viewable_id" => 2
                  }
                ]
              },
              {
                "id" => 1,
                "name" => "Ruby on Rails Tote",
                "count_on_hand" => 10,
                "sku" => "ROR-00011",
                "price" => "15.99",
                "weight" => nil,
                "height" => nil,
                "width" => nil,
                "depth" => nil,
                "is_master" => true,
                "cost_price" => "13.0",
                "permalink" => "ruby-on-rails-tote",
                "option_values" => [
                  {
                    "id" => 1,
                    "name" => "Small",
                    "presentation" => "S",
                    "option_type_name" => "tshirt-size",
                    "option_type_id" => 1
                  },
            {
                    "id" => 2,
                    "name" => "medium",
                    "presentation" => "m",
                    "option_type_name" => "tshirt-size",
                    "option_type_id" => 1
                  }
                ],
                "images" => [
                  {
                    "id" => 1,
                    "position" => 1,
                    "attachment_content_type" => "image/jpg",
                    "attachment_file_name" => "ror_tote.jpeg",
                    "type" => "Spree::Image",
                    "attachment_updated_at" => nil,
                    "attachment_width" => 360,
                    "attachment_height" => 360,
                    "alt" => nil,
                    "viewable_type" => "Spree::Variant",
                    "viewable_id" => 1
                  },
                  {
                    "id" => 2,
                    "position" => 2,
                    "attachment_content_type" => "image/jpg",
                    "attachment_file_name" => "ror_tote.jpeg",
                    "type" => "Spree::Image",
                    "attachment_updated_at" => nil,
                    "attachment_width" => 360,
                    "attachment_height" => 360,
                    "alt" => nil,
                    "viewable_type" => "Spree::Variant",
                    "viewable_id" => 2
                  }
                ]
              }
            ]
          }
          end
          render :json => {:products => products,  "count" => 2}.to_json
    end

    def product_show
      product =  {
      "id" => 1,
      "name" => "Example product ",
      "description" => "Description",
      "price" => "15.99",
      "available_on" => "2012-10-17T03:43:57Z",
      "permalink" => "ruby-on-rails-tote",
      "count_on_hand" => 10,
      "meta_description" => nil,
      "meta_keywords" => nil,
      "product_rate" => 3,
      "variants" => [
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
      {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
      {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        },
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
      {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
      {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        }
      ],
      "product_properties" => [
        {
          "id" => 1,
          "product_id" => 1,
          "property_id" => 1,
          "value" => "Tote",
          "property_name" => "bag_type"
        },
  {
          "id" => 2,
          "product_id" => 1,
          "property_id" => 2,
          "value" => "Tote",
          "property_name" => "bag_type"
        }
      ],
"pick_up_at_store" => true,
"store_locations" =>[
  {
        "id" => 1,
        "name" => "default",
        "address1" => "7735 Old Georgetown Road",
        "address2" => "Suite 510",
        "city" => "Bethesda",
        "state_id" => 26,
        "country_id" => 49,
        "zipcode" => "20814",
        "phone" => "",
        "active" => true,
        "lat" => 21.9,
        "long" => 23.7
     },
    {
        "id" => 1,
        "name" => "default",
        "address1" => "7735 Old Georgetown Road",
        "address2" => "Suite 510",
        "city" => "Bethesda",
        "state_id" => 26,
        "country_id" => 49,
        "zipcode" => "20814",
        "phone" => "",
        "active" => true,
        "lat" => 21.9,
        "long" => 23.7
     },
  
  ],
  "product_reviews" =>[
    {
    "review_id" => 1,
    "review_date" => "2012-10-17T03:43:57Z",
    "review_rate" => 4,
    "review_comment" => "nice product",
    "category" => "abc",
    "seller_name" => "",
    "product_name" => "Example product",
    "product_id" => "1"
  },
  { 
    "review_id" => 1,
    "review_date" => "2012-10-17T03:43:57Z",
    "review_rate" => nil,
    "review_comment" => "nice product",
    "category" => "abc",
    "seller_name" => "seller name",
    "product_name" => "Example product",
    "product_id" => "1"

  }


  ],
    "product_seller" =>
  {
    "seller_id" => 1,
    "seller_name" => "Nike",
    "seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
  }
    
    }
          render :json => {:product => product}

    end

    def about_us
      about_us = {:contents => "There are many variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour, or randomised words which don't look even slightly believable. If you are going to use a passage of Lorem Ipsum, you need to be sure there isn't anything embarrassing hidden in the middle of text. All the Lorem Ipsum generators on the Internet tend to repeat predefined chunks as necessary, making this the first true generator on the Internet. It uses a dictionary of over 200 Latin words, combined with a handful of model sentence structures, to generate Lorem Ipsum which looks reasonable. The generated Lorem Ipsum is therefore always free from repetition, injected humour, or non-characteristic words etc."}
      respond_to do |format|
        format.json { render :json => about_us }
      end
    end

    def sale
    products = []
    5.times do |i|
      
    o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
    string  =  (0...8).map{ o[rand(o.length)] }.join
    products << 
      {
        "id" => i + 1,
        "name" => "Example product - #{string.upcase}",
        "description" => "Description- #{string.upcase}",
        "price" => "15.99",
        "available_on" => "2012-10-17T03:43:57Z",
        "permalink" => "ruby-on-rails-tote",
        "count_on_hand" => 10,
        "meta_description" => nil,
        "meta_keywords" => nil,
        "product_rate" => 3,
        "variants" => [
          {
            "id" => 1,
            "name" => "Ruby on Rails Tote",
            "count_on_hand" => 10,
            "sku" => "ROR-00011",
            "price" => "15.99",
            "weight" => nil,
            "height" => nil,
            "width" => nil,
            "depth" => nil,
            "is_master" => true,
            "cost_price" => "13.0",
            "permalink" => "ruby-on-rails-tote",
            "option_values" => [
              {
                "id" => 1,
                "name" => "Small",
                "presentation" => "S",
                "option_type_name" => "tshirt-size",
                "option_type_id" => 1
              },
        {
                "id" => 2,
                "name" => "medium",
                "presentation" => "m",
                "option_type_name" => "tshirt-size",
                "option_type_id" => 1
              }
            ],
            "images" => [
              {
                "id" => 1,
                "position" => 1,
                "attachment_content_type" => "image/jpg",
                "attachment_file_name" => "ror_tote.jpeg",
                "type" => "Spree::Image",
                "attachment_updated_at" => nil,
                "attachment_width" => 360,
                "attachment_height" => 360,
                "alt" => nil,
                "viewable_type" => "Spree::Variant",
                "viewable_id" => 1
              },
        {
                "id" => 2,
                "position" => 2,
                "attachment_content_type" => "image/jpg",
                "attachment_file_name" => "ror_tote.jpeg",
                "type" => "Spree::Image",
                "attachment_updated_at" => nil,
                "attachment_width" => 360,
                "attachment_height" => 360,
                "alt" => nil,
                "viewable_type" => "Spree::Variant",
                "viewable_id" => 2
              }
            ]
          },
          {
            "id" => 1,
            "name" => "Ruby on Rails Tote",
            "count_on_hand" => 10,
            "sku" => "ROR-00011",
            "price" => "15.99",
            "weight" => nil,
            "height" => nil,
            "width" => nil,
            "depth" => nil,
            "is_master" => true,
            "cost_price" => "13.0",
            "permalink" => "ruby-on-rails-tote",
            "option_values" => [
              {
                "id" => 1,
                "name" => "Small",
                "presentation" => "S",
                "option_type_name" => "tshirt-size",
                "option_type_id" => 1
              },
        {
                "id" => 2,
                "name" => "medium",
                "presentation" => "m",
                "option_type_name" => "tshirt-size",
                "option_type_id" => 1
              }
            ],
            "images" => [
              {
                "id" => 1,
                "position" => 1,
                "attachment_content_type" => "image/jpg",
                "attachment_file_name" => "ror_tote.jpeg",
                "type" => "Spree::Image",
                "attachment_updated_at" => nil,
                "attachment_width" => 360,
                "attachment_height" => 360,
                "alt" => nil,
                "viewable_type" => "Spree::Variant",
                "viewable_id" => 1
              },
        {
                "id" => 2,
                "position" => 2,
                "attachment_content_type" => "image/jpg",
                "attachment_file_name" => "ror_tote.jpeg",
                "type" => "Spree::Image",
                "attachment_updated_at" => nil,
                "attachment_width" => 360,
                "attachment_height" => 360,
                "alt" => nil,
                "viewable_type" => "Spree::Variant",
                "viewable_id" => 2
              }
            ]
          }
        ],
        "product_properties" => [
          {
            "id" => 1,
            "product_id" => 1,
            "property_id" => 1,
            "value" => "Tote",
            "property_name" => "bag_type"
          },
    {
            "id" => 2,
            "product_id" => 1,
            "property_id" => 2,
            "value" => "Tote",
            "property_name" => "bag_type"
          }
        ],
  "store_locations" =>[
    {
          "id" => 1,
          "name" => "default",
          "address1" => "7735 Old Georgetown Road",
          "address2" => "Suite 510",
          "city" => "Bethesda",
          "state_id" => 26,
          "country_id" => 49,
          "zipcode" => "20814",
          "phone" => "",
          "active" => true,
        "lat" => 21.9,
        "long" => 23.7
       },
      {
          "id" => 1,
          "name" => "default",
          "address1" => "7735 Old Georgetown Road",
          "address2" => "Suite 510",
          "city" => "Bethesda",
          "state_id" => 26,
          "country_id" => 49,
          "zipcode" => "20814",
          "phone" => "",
          "active" => true,
        "lat" => 21.9,
        "long" => 23.7
       },
    
    ],
    "product_reviews" =>[
      {
      "review_id" => 1,
      "review_date" => "2012-10-17T03:43:57Z",
      "review_rate" => 4,
      "review_comment" => "nice product",
      "category" => "abc",
      "seller_name" => "",
      "product_name" => "Example product",
      "product_id" => "1"
    },
    { 
      "review_id" => 1,
      "review_date" => "2012-10-17T03:43:57Z",
      "review_rate" => nil,
      "review_comment" => "nice product",
      "category" => "abc",
      "seller_name" => "seller name",
      "product_name" => "Example product",
      "product_id" => "1"

    }


    ],
      "product_seller" =>
    {
      "seller_id" => 1,
      "seller_name" => "Nike",
      "seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
    }
      
      }
    
    end

    render :json => {:products => products,  "count" => 5 }.to_json
    return
  end

  def sellers
    sellers = []
    5.times do |i|
      
      o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten
      string  =  (0...8).map{ o[rand(o.length)] }.join
      sellers << {
                    "seller_id" => i+1,
                    "seller_name" => "Seller Name - #{ string.upcase}",
                    "seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
      }
    end
    render :json => {:sellers => sellers , :count => 5}

  end

  def seller_detail

    seller = {
  "seller_id" => 4,
  "seller_name" => "Nike",
  "seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
  "seller_banner" => "images/my_image",
  "seller_logo" => "images/my_image",
  "seller_products" =>[  
                        {
                          "id" => 1,
                          "name" => "Example product ",
                          "description" => "Description",
                          "price" => "15.99",
                          "available_on" => "2012-10-17T03:43:57Z",
                          "permalink" => "ruby-on-rails-tote",
                          "count_on_hand" => 10,
                          "meta_description" => nil,
                          "meta_keywords" => nil,
                          "product_rate" => 3,
                          "variants" => [
                                          {
                                              "id" => 1,
                                              "name" => "Ruby on Rails Tote",
                                              "count_on_hand" => 10,
                                              "sku" => "ROR-00011",
                                              "price" => "15.99",
                                              "weight" => nil,
                                              "height" => nil,
                                              "width" => nil,
                                              "depth" => nil,
                                              "is_master" => true,
                                              "cost_price" => "13.0",
                                              "permalink" => "ruby-on-rails-tote",
                                              "option_values" => [
                                                                    {
                                                                      "id" => 1,
                                                                      "name" => "Small",
                                                                      "presentation" => "S",
                                                                      "option_type_name" => "tshirt-size",
                                                                      "option_type_id" => 1
                                                                    },
                                                                    {
                                                                      "id" => 2,
                                                                      "name" => "medium",
                                                                      "presentation" => "m",
                                                                      "option_type_name" => "tshirt-size",
                                                                      "option_type_id" => 1
                                                                    }
                                                                  ],
                                              "images" => [
                                                            {
                                                              "id" => 1,
                                                              "position" => 1,
                                                              "attachment_content_type" => "image/jpg",
                                                              "attachment_file_name" => "ror_tote.jpeg",
                                                              "type" => "Spree::Image",
                                                              "attachment_updated_at" => nil,
                                                              "attachment_width" => 360,
                                                              "attachment_height" => 360,
                                                              "alt" => nil,
                                                              "viewable_type" => "Spree::Variant",
                                                              "viewable_id" => 1
                                                            },
                                                            {
                                                              "id" => 2,
                                                              "position" => 2,
                                                              "attachment_content_type" => "image/jpg",
                                                              "attachment_file_name" => "ror_tote.jpeg",
                                                              "type" => "Spree::Image",
                                                              "attachment_updated_at" => nil,
                                                              "attachment_width" => 360,
                                                              "attachment_height" => 360,
                                                              "alt" => nil,
                                                              "viewable_type" => "Spree::Variant",
                                                              "viewable_id" => 2
                                                            }
                                                        ]
                                              },
                                              {
                                                      "id" => 1,
                                                      "name" => "Ruby on Rails Tote",
                                                      "count_on_hand" => 10,
                                                      "sku" => "ROR-00011",
                                                      "price" => "15.99",
                                                      "weight" => nil,
                                                      "height" => nil,
                                                      "width" => nil,
                                                      "depth" => nil,
                                                      "is_master" => true,
                                                      "cost_price" => "13.0",
                                                      "permalink" => "ruby-on-rails-tote",
                                                      "option_values" => [
                                                                            {
                                                                              "id" => 1,
                                                                              "name" => "Small",
                                                                              "presentation" => "S",
                                                                              "option_type_name" => "tshirt-size",
                                                                              "option_type_id" => 1
                                                                            },
                                                                            {
                                                                              "id" => 2,
                                                                              "name" => "medium",
                                                                              "presentation" => "m",
                                                                              "option_type_name" => "tshirt-size",
                                                                              "option_type_id" => 1
                                                                            }
                                                                        ],
                                                            "images" => [
                                                                            {
                                                                              "id" => 1,
                                                                              "position" => 1,
                                                                              "attachment_content_type" => "image/jpg",
                                                                              "attachment_file_name" => "ror_tote.jpeg",
                                                                              "type" => "Spree::Image",
                                                                              "attachment_updated_at" => nil,
                                                                              "attachment_width" => 360,
                                                                              "attachment_height" => 360,
                                                                              "alt" => nil,
                                                                              "viewable_type" => "Spree::Variant",
                                                                              "viewable_id" => 1
                                                                            },
                                                                            {
                                                                                    "id" => 2,
                                                                                    "position" => 2,
                                                                                    "attachment_content_type" => "image/jpg",
                                                                                    "attachment_file_name" => "ror_tote.jpeg",
                                                                                    "type" => "Spree::Image",
                                                                                    "attachment_updated_at" => nil,
                                                                                    "attachment_width" => 360,
                                                                                    "attachment_height" => 360,
                                                                                    "alt" => nil,
                                                                                    "viewable_type" => "Spree::Variant",
                                                                                    "viewable_id" => 2
                                                                           }
                                                                      ]
                                                                    }
                                                                  ],
                                                             "product_properties" => [
                                                                                        {
                                                                                          "id" => 1,
                                                                                          "product_id" => 1,
                                                                                          "property_id" => 1,
                                                                                          "value" => "Tote",
                                                                                          "property_name" => "bag_type"
                                                                                        },
                                                                                        {
                                                                                            "id" => 2,
                                                                                            "product_id" => 1,
                                                                                            "property_id" => 2,
                                                                                            "value" => "Tote",
                                                                                            "property_name" => "bag_type"
                                                                                          }
                                                                                      ],
                                                              "store_locations" =>[
                                                                                      {
                                                                                        "id" => 1,
                                                                                        "name" => "default",
                                                                                        "address1" => "7735 Old Georgetown Road",
                                                                                        "address2" => "Suite 510",
                                                                                        "city" => "Bethesda",
                                                                                        "state_id" => 26,
                                                                                        "country_id" => 49,
                                                                                        "zipcode" => "20814",
                                                                                        "phone" => "",
                                                                                        "active" => true,
                                                                                        "lat" => 21.9,
                                                                                        "long" => 23.7
                                                                                      },
                                                                                     {
                                                                                        "id" => 1,
                                                                                        "name" => "default",
                                                                                        "address1" => "7735 Old Georgetown Road",
                                                                                        "address2" => "Suite 510",
                                                                                        "city" => "Bethesda",
                                                                                        "state_id" => 26,
                                                                                        "country_id" => 49,
                                                                                        "zipcode" => "20814",
                                                                                        "phone" => "",
                                                                                        "active" => true,
                                                                                        "lat" => 21.9,
                                                                                        "long" => 23.7
                                                                                     },
                                                                                  ],
                                                              "product_reviews" =>[
                                                                                      {
                                                                                      "review_id" => 1,
                                                                                      "review_date" => "2012-10-17T03:43:57Z",
                                                                                      "review_rate" => 4,
                                                                                      "review_comment" => "nice product",
                                                                                      "category" => "abc",
                                                                                      "seller_name" => "",
                                                                                      "product_name" => "Example product",
                                                                                      "product_id" => "1"
                                                                                    },
                                                                                    { 
                                                                                      "review_id" => 1,
                                                                                      "review_date" => "2012-10-17T03:43:57Z",
                                                                                      "review_rate" => nil,
                                                                                      "review_comment" => "nice product",
                                                                                      "category" => "abc",
                                                                                      "seller_name" => "seller name",
                                                                                      "product_name" => "Example product",
                                                                                      "product_id" => "1"

                                                                                    }
                                                                                  ],
                                                                "product_seller" =>
                                                                                    {
                                                                                      "seller_id" => 1,
                                                                                      "seller_name" => "Nike",
                                                                                      "seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
                                                                                    }

                                                                 }
                                                              ],
                                            "seller_review" =>[
                                                                {
                                                                "review_id" => 3,
                                                                "review_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
                                                                }
                                                              ],
                                            "seller_rate" => 4,
                                            "seller_stores" =>[
                                                                {
                                                                "store_id" => 7,
                                                                "store_address" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
                                                                "store_name" => "my store"
                                                                }
                                                              ]
                                          }
    render :json =>  seller 
  end

  def notify_me
    render :json => {:msg => "We are sorry but this product is out of stock right now"}
  end

  def cart
    cart = 
{
  "cart_id" => 56,
  "cart_product" => [
                        {
                        "id" => 1,
      "name" => "Example product ",
      "description" => "Description",
      "price" => "15.99",
      "available_on" => "2012-10-17T03:43:57Z",
      "permalink" => "ruby-on-rails-tote",
      "count_on_hand" => 10,
      "meta_description" => nil,
      "meta_keywords" => nil,
      "product_rate" => 3,
      "variants" => [
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
      {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
      {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        },
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
      {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
      {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        }
      ],
      "product_properties" => [
        {
          "id" => 1,
          "product_id" => 1,
          "property_id" => 1,
          "value" => "Tote",
          "property_name" => "bag_type"
        },
  {
          "id" => 2,
          "product_id" => 1,
          "property_id" => 2,
          "value" => "Tote",
          "property_name" => "bag_type"
        }
      ],
      "pick_up_at_store" => "false",
  "product_reviews" =>[
    {
    "review_id" => 1,
    "review_date" => "2012-10-17T03:43:57Z",
    "review_rate" => 4,
    "review_comment" => "nice product",
    "category" => "abc",
    "seller_name" => "",
    "product_name" => "Example product",
    "product_id" => "1"
  },
  { 
    "review_id" => 1,
    "review_date" => "2012-10-17T03:43:57Z",
    "review_rate" => nil,
    "review_comment" => "nice product",
    "category" => "abc",
    "seller_name" => "seller name",
    "product_name" => "Example product",
    "product_id" => "1"

  }


  ],
    "product_seller" =>
  {
    "seller_id" => 1,
    "seller_name" => "Nike",
    "seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
  }
    
    }
      
                      
                      ],
  "cart_total" => 450,
  "pick_up_at_store" => [
                          {
                           
                "id" => 1,
                "name" => "Example product ",
                "description" => "Description",
                "price" => "15.99",
                "available_on" => "2012-10-17T03:43:57Z",
                "permalink" => "ruby-on-rails-tote",
                "count_on_hand" => 10,
                "meta_description" => nil,
                "meta_keywords" => nil,
                "product_rate" => 3,
                "variants" => [
                  {
                    "id" => 1,
                    "name" => "Ruby on Rails Tote",
                    "count_on_hand" => 10,
                    "sku" => "ROR-00011",
                    "price" => "15.99",
                    "weight" => nil,
                    "height" => nil,
                    "width" => nil,
                    "depth" => nil,
                    "is_master" => true,
                    "cost_price" => "13.0",
                    "permalink" => "ruby-on-rails-tote",
                    "option_values" => [
                      {
                        "id" => 1,
                        "name" => "Small",
                        "presentation" => "S",
                        "option_type_name" => "tshirt-size",
                        "option_type_id" => 1
                      },
                {
                        "id" => 2,
                        "name" => "medium",
                        "presentation" => "m",
                        "option_type_name" => "tshirt-size",
                        "option_type_id" => 1
                      }
                    ],
                    "images" => [
                      {
                        "id" => 1,
                        "position" => 1,
                        "attachment_content_type" => "image/jpg",
                        "attachment_file_name" => "ror_tote.jpeg",
                        "type" => "Spree::Image",
                        "attachment_updated_at" => nil,
                        "attachment_width" => 360,
                        "attachment_height" => 360,
                        "alt" => nil,
                        "viewable_type" => "Spree::Variant",
                        "viewable_id" => 1
                      },
                {
                        "id" => 2,
                        "position" => 2,
                        "attachment_content_type" => "image/jpg",
                        "attachment_file_name" => "ror_tote.jpeg",
                        "type" => "Spree::Image",
                        "attachment_updated_at" => nil,
                        "attachment_width" => 360,
                        "attachment_height" => 360,
                        "alt" => nil,
                        "viewable_type" => "Spree::Variant",
                        "viewable_id" => 2
                      }
                    ]
                  },
                  {
                    "id" => 1,
                    "name" => "Ruby on Rails Tote",
                    "count_on_hand" => 10,
                    "sku" => "ROR-00011",
                    "price" => "15.99",
                    "weight" => nil,
                    "height" => nil,
                    "width" => nil,
                    "depth" => nil,
                    "is_master" => true,
                    "cost_price" => "13.0",
                    "permalink" => "ruby-on-rails-tote",
                    "option_values" => [
                      {
                        "id" => 1,
                        "name" => "Small",
                        "presentation" => "S",
                        "option_type_name" => "tshirt-size",
                        "option_type_id" => 1
                      },
                {
                        "id" => 2,
                        "name" => "medium",
                        "presentation" => "m",
                        "option_type_name" => "tshirt-size",
                        "option_type_id" => 1
                      }
                    ],
                    "images" => [
                      {
                        "id" => 1,
                        "position" => 1,
                        "attachment_content_type" => "image/jpg",
                        "attachment_file_name" => "ror_tote.jpeg",
                        "type" => "Spree::Image",
                        "attachment_updated_at" => nil,
                        "attachment_width" => 360,
                        "attachment_height" => 360,
                        "alt" => nil,
                        "viewable_type" => "Spree::Variant",
                        "viewable_id" => 1
                      },
                {
                        "id" => 2,
                        "position" => 2,
                        "attachment_content_type" => "image/jpg",
                        "attachment_file_name" => "ror_tote.jpeg",
                        "type" => "Spree::Image",
                        "attachment_updated_at" => nil,
                        "attachment_width" => 360,
                        "attachment_height" => 360,
                        "alt" => nil,
                        "viewable_type" => "Spree::Variant",
                        "viewable_id" => 2
                      }
                    ]
                  }
                ],
                "product_properties" => [
                  {
                    "id" => 1,
                    "product_id" => 1,
                    "property_id" => 1,
                    "value" => "Tote",
                    "property_name" => "bag_type"
                  },
                  {
                    "id" => 2,
                    "product_id" => 1,
                    "property_id" => 2,
                    "value" => "Tote",
                    "property_name" => "bag_type"
                  }
                ],
                "pick_up_at_store" => true,
                "store_locations" =>[
                                {
                                      "id" => 1,
                                      "name" => "default",
                                      "address1" => "7735 Old Georgetown Road",
                                      "address2" => "Suite 510",
                                      "city" => "Bethesda",
                                      "state_id" => 26,
                                      "country_id" => 49,
                                      "zipcode" => "20814",
                                      "phone" => "",
                                      "active" => true,
                                      "lat" => 21.9,
                                      "long" => 23.7
                                   },
                                  {
                                      "id" => 1,
                                      "name" => "default",
                                      "address1" => "7735 Old Georgetown Road",
                                      "address2" => "Suite 510",
                                      "city" => "Bethesda",
                                      "state_id" => 26,
                                      "country_id" => 49,
                                      "zipcode" => "20814",
                                      "phone" => "",
                                      "active" => true
                                   }
                                 ],
                    "product_reviews" =>[
                                  {
                                   "review_id" => 1,
                                   "review_date" => "2012-10-17T03:43:57Z",
                                   "review_rate" => 4,
                                   "review_comment" => "nice product",
                                   "category" => "abc",
                                   "seller_name" => "",
                                   "product_name" => "Example product",
                                   "product_id" => "1"
                                 },
                                 { 
                                   "review_id" => 1,
                                   "review_date" => "2012-10-17T03:43:57Z",
                                   "review_rate" => nil,
                                   "review_comment" => "nice product",
                                   "category" => "abc",
                                   "seller_name" => "seller name",
                                   "product_name" => "Example product",
                                   "product_id" => "1"

                                 }
                                ],
              "product_seller" =>
                                  {
                                    "seller_id" => 1,
                                    "seller_name" => "Nike",
                                    "seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum." 
                                  },    
            
          }
          
          ],
          "pick_up_at_store_total" => 679 ,
            "cart_grand_total" =>  1102
          
        }

    render :json => cart
  end

  def update_cart
      cart = 
{
  "cart_id" => 56,
  "cart_product" => [
                        {
                        "id" => 1,
      "name" => "Example product ",
      "description" => "Description",
      "price" => "15.99",
      "available_on" => "2012-10-17T03:43:57Z",
      "permalink" => "ruby-on-rails-tote",
      "count_on_hand" => 10,
      "meta_description" => nil,
      "meta_keywords" => nil,
      "product_rate" => 3,
      "variants" => [
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
      {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
      {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        },
        {
          "id" => 1,
          "name" => "Ruby on Rails Tote",
          "count_on_hand" => 10,
          "sku" => "ROR-00011",
          "price" => "15.99",
          "weight" => nil,
          "height" => nil,
          "width" => nil,
          "depth" => nil,
          "is_master" => true,
          "cost_price" => "13.0",
          "permalink" => "ruby-on-rails-tote",
          "option_values" => [
            {
              "id" => 1,
              "name" => "Small",
              "presentation" => "S",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            },
      {
              "id" => 2,
              "name" => "medium",
              "presentation" => "m",
              "option_type_name" => "tshirt-size",
              "option_type_id" => 1
            }
          ],
          "images" => [
            {
              "id" => 1,
              "position" => 1,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 1
            },
      {
              "id" => 2,
              "position" => 2,
              "attachment_content_type" => "image/jpg",
              "attachment_file_name" => "ror_tote.jpeg",
              "type" => "Spree::Image",
              "attachment_updated_at" => nil,
              "attachment_width" => 360,
              "attachment_height" => 360,
              "alt" => nil,
              "viewable_type" => "Spree::Variant",
              "viewable_id" => 2
            }
          ]
        }
      ],
      "product_properties" => [
        {
          "id" => 1,
          "product_id" => 1,
          "property_id" => 1,
          "value" => "Tote",
          "property_name" => "bag_type"
        },
  {
          "id" => 2,
          "product_id" => 1,
          "property_id" => 2,
          "value" => "Tote",
          "property_name" => "bag_type"
        }
      ],
      "pick_up_at_store" => "false",
  "product_reviews" =>[
    {
    "review_id" => 1,
    "review_date" => "2012-10-17T03:43:57Z",
    "review_rate" => 4,
    "review_comment" => "nice product",
    "category" => "abc",
    "seller_name" => "",
    "product_name" => "Example product",
    "product_id" => "1"
  },
  { 
    "review_id" => 1,
    "review_date" => "2012-10-17T03:43:57Z",
    "review_rate" => nil,
    "review_comment" => "nice product",
    "category" => "abc",
    "seller_name" => "seller name",
    "product_name" => "Example product",
    "product_id" => "1"

  }


  ],
    "product_seller" =>
  {
    "seller_id" => 1,
    "seller_name" => "Nike",
    "seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum."
  }
    
    }
      
                      
                      ],
  "cart_total" => 450,
  "pick_up_at_store" => [
                          {
                           
                "id" => 1,
                "name" => "Example product ",
                "description" => "Description",
                "price" => "15.99",
                "available_on" => "2012-10-17T03:43:57Z",
                "permalink" => "ruby-on-rails-tote",
                "count_on_hand" => 10,
                "meta_description" => nil,
                "meta_keywords" => nil,
                "product_rate" => 3,
                "variants" => [
                  {
                    "id" => 1,
                    "name" => "Ruby on Rails Tote",
                    "count_on_hand" => 10,
                    "sku" => "ROR-00011",
                    "price" => "15.99",
                    "weight" => nil,
                    "height" => nil,
                    "width" => nil,
                    "depth" => nil,
                    "is_master" => true,
                    "cost_price" => "13.0",
                    "permalink" => "ruby-on-rails-tote",
                    "option_values" => [
                      {
                        "id" => 1,
                        "name" => "Small",
                        "presentation" => "S",
                        "option_type_name" => "tshirt-size",
                        "option_type_id" => 1
                      },
                {
                        "id" => 2,
                        "name" => "medium",
                        "presentation" => "m",
                        "option_type_name" => "tshirt-size",
                        "option_type_id" => 1
                      }
                    ],
                    "images" => [
                      {
                        "id" => 1,
                        "position" => 1,
                        "attachment_content_type" => "image/jpg",
                        "attachment_file_name" => "ror_tote.jpeg",
                        "type" => "Spree::Image",
                        "attachment_updated_at" => nil,
                        "attachment_width" => 360,
                        "attachment_height" => 360,
                        "alt" => nil,
                        "viewable_type" => "Spree::Variant",
                        "viewable_id" => 1
                      },
                {
                        "id" => 2,
                        "position" => 2,
                        "attachment_content_type" => "image/jpg",
                        "attachment_file_name" => "ror_tote.jpeg",
                        "type" => "Spree::Image",
                        "attachment_updated_at" => nil,
                        "attachment_width" => 360,
                        "attachment_height" => 360,
                        "alt" => nil,
                        "viewable_type" => "Spree::Variant",
                        "viewable_id" => 2
                      }
                    ]
                  },
                  {
                    "id" => 1,
                    "name" => "Ruby on Rails Tote",
                    "count_on_hand" => 10,
                    "sku" => "ROR-00011",
                    "price" => "15.99",
                    "weight" => nil,
                    "height" => nil,
                    "width" => nil,
                    "depth" => nil,
                    "is_master" => true,
                    "cost_price" => "13.0",
                    "permalink" => "ruby-on-rails-tote",
                    "option_values" => [
                      {
                        "id" => 1,
                        "name" => "Small",
                        "presentation" => "S",
                        "option_type_name" => "tshirt-size",
                        "option_type_id" => 1
                      },
                {
                        "id" => 2,
                        "name" => "medium",
                        "presentation" => "m",
                        "option_type_name" => "tshirt-size",
                        "option_type_id" => 1
                      }
                    ],
                    "images" => [
                      {
                        "id" => 1,
                        "position" => 1,
                        "attachment_content_type" => "image/jpg",
                        "attachment_file_name" => "ror_tote.jpeg",
                        "type" => "Spree::Image",
                        "attachment_updated_at" => nil,
                        "attachment_width" => 360,
                        "attachment_height" => 360,
                        "alt" => nil,
                        "viewable_type" => "Spree::Variant",
                        "viewable_id" => 1
                      },
                {
                        "id" => 2,
                        "position" => 2,
                        "attachment_content_type" => "image/jpg",
                        "attachment_file_name" => "ror_tote.jpeg",
                        "type" => "Spree::Image",
                        "attachment_updated_at" => nil,
                        "attachment_width" => 360,
                        "attachment_height" => 360,
                        "alt" => nil,
                        "viewable_type" => "Spree::Variant",
                        "viewable_id" => 2
                      }
                    ]
                  }
                ],
                "product_properties" => [
                  {
                    "id" => 1,
                    "product_id" => 1,
                    "property_id" => 1,
                    "value" => "Tote",
                    "property_name" => "bag_type"
                  },
                  {
                    "id" => 2,
                    "product_id" => 1,
                    "property_id" => 2,
                    "value" => "Tote",
                    "property_name" => "bag_type"
                  }
                ],
                "pick_up_at_store" => true,
                "store_locations" =>[
                                {
                                      "id" => 1,
                                      "name" => "default",
                                      "address1" => "7735 Old Georgetown Road",
                                      "address2" => "Suite 510",
                                      "city" => "Bethesda",
                                      "state_id" => 26,
                                      "country_id" => 49,
                                      "zipcode" => "20814",
                                      "phone" => "",
                                      "active" => true,
                                      "lat" => 21.9,
                                      "long" => 23.7
                                   },
                                  {
                                      "id" => 1,
                                      "name" => "default",
                                      "address1" => "7735 Old Georgetown Road",
                                      "address2" => "Suite 510",
                                      "city" => "Bethesda",
                                      "state_id" => 26,
                                      "country_id" => 49,
                                      "zipcode" => "20814",
                                      "phone" => "",
                                      "active" => true
                                   }
                                 ],
                    "product_reviews" =>[
                                  {
                                   "review_id" => 1,
                                   "review_date" => "2012-10-17T03:43:57Z",
                                   "review_rate" => 4,
                                   "review_comment" => "nice product",
                                   "category" => "abc",
                                   "seller_name" => "",
                                   "product_name" => "Example product",
                                   "product_id" => "1"
                                 },
                                 { 
                                   "review_id" => 1,
                                   "review_date" => "2012-10-17T03:43:57Z",
                                   "review_rate" => nil,
                                   "review_comment" => "nice product",
                                   "category" => "abc",
                                   "seller_name" => "seller name",
                                   "product_name" => "Example product",
                                   "product_id" => "1"

                                 }
                                ],
              "product_seller" =>
                                  {
                                    "seller_id" => 1,
                                    "seller_name" => "Nike",
                                    "seller_description" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum." 
                                  },    
            
          }
          
          ],
          "pick_up_at_store_total" => 679 ,
            "cart_grand_total" =>  1102
          
        }

    render :json => cart
  
  end

  def empty_cart
    render :json => {  msg:"cart deleted successfuly" }
  end

  def create_order
          order = 
        {
        "id" =>  1,
        "number" =>  "R335381310",
        "item_total" =>  "100.0",
        "display_item_total" =>  "$100.00",
        "total" =>  "0.0",
        "state" =>  "cart",
        "adjustment_total" =>  "-0.0",
        "user_id" =>  nil,
        "created_at" =>  "2012-10-24T01:02:25Z",
        "updated_at" =>  "2012-10-24T01:02:25Z",
        "completed_at" =>  nil,
        "payment_total" =>  "0.0",
        "shipment_state" =>  nil,
        "payment_state" =>  nil,
        "email" =>  nil,
        "special_instructions" =>  nil,
        "total_quantity" =>  1,
        "token" =>  "abcdef123456",
        "line_items" =>  [
          {
            "id" =>  1,
            "quantity" =>  2,
            "price" =>  "19.99",
            "single_display_amount" =>  "$19.99",
            "total" =>  "39.99",
            "display_total" =>  "$39.99",
            "variant_id" =>  1,
            "variant" =>  {
              "id" =>  1,
              "name" =>  "Ruby on Rails Tote",
              "count_on_hand" =>  10,
              "sku" =>  "ROR-00011",
              "price" =>  "15.99",
              "weight" =>  nil,
              "height" =>  nil,
              "width" =>  nil,
              "depth" =>  nil,
              "is_master" =>  true,
              "cost_price" =>  "13.0",
              "permalink" =>  "ruby-on-rails-tote",
              "option_values" =>  [
                {
                  "id" =>  1,
                  "name" =>  "Small",
                  "presentation" =>  "S",
                  "option_type_name" =>  "tshirt-size",
                  "option_type_id" =>  1
                }
              ],
              "images" =>  [
                {
                  "id" =>  1,
                  "position" =>  1,
                  "attachment_content_type" =>  "image/jpg",
                  "attachment_file_name" =>  "ror_tote.jpeg",
                  "type" =>  "Spree =>  => Image",
                  "attachment_updated_at" =>  nil,
                  "attachment_width" =>  360,
                  "attachment_height" =>  360,
                  "alt" =>  nil,
                  "viewable_type" =>  "Spree =>  => Variant",
                  "viewable_id" =>  1,
                  "mini_url" =>  "/spree/products/1/mini/file.png?1370533476",
                  "small_url" =>  "/spree/products/1/small/file.png?1370533476",
                  "product_url" =>  "/spree/products/1/product/file.png?1370533476",
                  "large_url" =>  "/spree/products/1/large/file.png?1370533476"
                }
              ],
              "description" =>  "A text description of the product."
            }
          }
        ],
        "adjustments" =>  [

        ],
        "payments" =>  [

        ],
        "shipments" =>  [

        ]
      }

      render :json => order
    end

    def get_addresses
      address = { "address" => [ {
        
        "billing_address" => {
                        "id"=> 1,
                "firstname"=> "Spree",
                "lastname"=> "Commerce",
                "address1"=> "1 Someplace Lane",
                "address2"=> "Suite 1",
                "city"=> "Bethesda",
                "zipcode"=> "16804",
                "phone"=> "123.4567.890",
                "company"=> nil,
                "alternative_phone"=> nil,
                "country_id"=> 1,
                "state_id"=> 1,
                "state_name"=> nil,
                }
      
  },
  {
    "shipping_address" => {
                      "id"=> 1,
                  "firstname"=> "Spree",
                  "lastname"=> "Commerce",
                  "address1"=> "1 Someplace Lane",
                  "address2"=> "Suite 1",
                  "city"=> "Bethesda",
                  "zipcode"=> "16804",
                  "phone"=> "123.4567.890",
                  "company"=> nil,
                  "alternative_phone"=> nil,
                  "country_id" => 1,
                  "state_id"=> 1,
                  "state_name"=> nil,
                  }
    
  }],
  "order_number" => "54645365" }

  render :json => address

    end

    def update_address
      address = { "address" => [ {
        
        "billing_address" => {
                        "id"=> 1,
                "firstname"=> "Spree",
                "lastname"=> "Commerce",
                "address1"=> "1 Someplace Lane",
                "address2"=> "Suite 1",
                "city"=> "Bethesda",
                "zipcode"=> "16804",
                "phone"=> "123.4567.890",
                "company"=> nil,
                "alternative_phone"=> nil,
                "country_id"=> 1,
                "state_id"=> 1,
                "state_name"=> nil,
                }
      
  },
  {
    "shipping_address" => {
                      "id"=> 1,
                  "firstname"=> "Spree",
                  "lastname"=> "Commerce",
                  "address1"=> "1 Someplace Lane",
                  "address2"=> "Suite 1",
                  "city"=> "Bethesda",
                  "zipcode"=> "16804",
                  "phone"=> "123.4567.890",
                  "company"=> nil,
                  "alternative_phone"=> nil,
                  "country_id" => 1,
                  "state_id"=> 1,
                  "state_name"=> nil,
                  }
    
  }],
  "order_number" => "54645365" }

  render :json => address
    end

    def delivery
      delivery = {
        "day" => [
                    {
                      "day_id" => 2,
                      "day_display_text" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum." 
                    }

                  ],
        "delivery_slot" => [
                              {
                              "slot_id" => 8,
                              "slot_display_text" => "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum." 
                              }
                            ]
                  }

        render :json => delivery
      end

      def add_to_cart
        line_item = {
          "line_item" => [
                          {
                            "quantity" => 7,
                            "variant_id" => 4
                          }
                    ]
        }

        render :json => line_item 
      end

      def change_password
        render :json => {:msg => "Password updated successfully"}
      end

      def order_details
        order = {
                  "order_number"  => 34365345,
                  "order_date"  => "2012-10-17T03:43:57Z",
                  "order_payment_status" => nil ,
                  'order_Delivery_status' => nil ,
                  "order_Total_amount" => "0.0",
                  "order_payment_type" => "credit card",
                  "order_discount_received" => "5.809",
                  "order_delevery_details" => nil,
                  "Products" => [
                              {
                              "product_id" => 5 ,
                              "product_name" => "my product " ,
                              "product_quantity" => 6 ,
                              "product_price" => "67" ,
                              "product_details" => nil,
                              "product_variants" =>  [
                                                  {
                                                    "id" =>  4 ,
                                                    "name" => "sndbhs",
                                                    "count_on_hand" => "my varient" ,                                                    "sku" => "RTJHN534347" ,
                                                    "price" => "67" ,
                                                    "weight" => "67" ,
                                                    "height" => "67",
                                                    "width" => "67",
                                                    "depth" =>"67" ,
                                                    "is_master" => true,
                                                    "cost_price" => "67",
                                                    "permalink" => "xyz/tyui",
                                                    "option_values" => [
                                                                    {
                                                                      "id" => 445 ,
                                                                      "name" => "my option" ,
                                                                      "presentation" => "sadasdadf" ,
                                                                      "option_type_name" => "name",
                                                                      "option_type_id" => 547657865
                                                                    }
                                                                  ],
                                                          "images" => [
                                                            {
                                                              "id" => 56,
                                                              "position" => 4,
                                                              "attachment_content_type" => "jpeg" ,
                                                              "attachment_file_name" => "my_attachment",
                                                              "type" => nil,
                                                              "attachment_updated_at" => "2012-10-17T03:43:57Z" ,
                                                              "attachment_width" =>  "764",
                                                              "attachment_height" => "87" ,
                                                              "alt" => "abc",
                                                              "viewable_type" => nil,
                                                              "viewable_id" => 44
                                                            }
                                                          ]
                                                        }
                                                      ]
                                                     }
                                                    ]
                                                   }
        render :json => order
       end

       def payment_status
        render :json => { msg: "Success"}
       end
       
       def delivery_slots
          render :json => { 
                            "selected_pickup_at_store_day" => 23,
                            "selected_delivery_slot" => 34
                          }
       end
      


  end
  


