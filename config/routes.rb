SwitchFabric::Application.routes.draw do

  #get "all_report/index"

  mount Ckeditor::Engine => '/ckeditor'

  get "miscs/index"
  get '/', :to => "spree/home#business",   :constraints => { :subdomain => "business" }
  constraints(Subdomain) do
    #Commented as we don't want to use frontend
    #get '/', :to => "spree/sellers#show", :as => :seller #,  :constraints => { :subdomain => /.+/ }
    get '/seller_products', :to => "spree/sellers#seller_products", :as => :seller_products
  end

  get '/home/load_products', :to => "spree/home#load_products", :as => :home_products
  mount Spree::Core::Engine, :at => '/'
  Spree::Core::Engine.routes.draw do
  #get "all_report/index"

    mount Ckeditor::Engine => '/ckeditor'

    resources :orders do
      collection do
        post 'update_fulflmnt_state'
        get 'cancel'
        get 'manual_push_order_to_fba'
        get 'get_new_order_status'
        get 'order_sync'
      end
    end

    resources :products do
      collection do
        post 'stock_updates'
        get 'fetch_fba_quantity'
      end
    end

    #Admin routes
    namespace :admin do
      match 'users/revoke/:id', :to => "users#revoke", :as => :revoke
      #get "orders/:id/invoice", to: "orders#invoice_show", :as => :order_invoice
      get "orders/:number/invoice", to: "orders#show_invoice", :as => :order_invoice
      get "variants/get_new_variants", to: "variants#get_new_variants", :as => 'get_new_variants'
      get "variants/get_updated_variants", to: "variants#get_updated_variants", :as => 'get_updated_variants'
      get 'variants/reject_change', to: "variants#reject_change"
      post "variants/create_on_fba", to: "variants#create_on_fba", :as => 'create_on_fba'
      put "variants/update_on_fba", to: "variants#update_on_fba", :as => 'update_on_fba'
      get "variants/get_skus", to: "variants#get_skus", :as => 'get_skus'
      get "variants/get_selected_variant_data", to:"variants#get_selected_variant_data", :as => 'get_selected_variant_data'
      get 'products/error_message_for_mp', to: "products#error_message_for_mp", :as => 'error_message_for_mp'
      get 'products/get_updated_fields', to: "products#get_updated_fields", :as => 'get_updated_fields'
      get 'option_types_market_places/map_option_type', to: "option_types_market_places#map_option_type", :as => 'map_option_type'
      get 'option_values_market_places/map_option_value', to: "option_values_market_places#map_option_value", :as => 'map_option_value'

      resources :description_management do
      end
      resources :title_management do
      end
      resources :price_management do
      end

      resources :error_logs
      resources :store_credits do
        collection do
          post :update_email_message
        end
      end

      resources :brands do
        collection do
          post :upload_brands
        end
      end

      resources :reviews do
          resources :block_reviews
      end

      resources :labels do
        collection do
          get :search
        end
      end

      resources :stock_items do
        member do
          post :out_of_stock
        end
        collection do
          post :out_of_stock_globally
        end
      end

      resources :stock_transfers do
        collection do
          get 'get_stcok_locations'
          get 'stock_setting_load_product'
          get 'sync_with_fba'
          post 'manage_stock_setting_product'
          post 'import_product_stock'
          post 'export_product_stock'
        end

        # member do
        #   post 'import_product_stock'
        #   post 'export_product_stock'
        # end
      end

      resources :products do
        member do
          get 'manage_stock'
          get 'manage_price'
          get 'manage_description'
          get 'manage_title'
        end
        collection do
          get 'market_place_variants'
          post 'import_data'
          get 'create_marketplace_list'
          get 'update_marketplace_list'
          get 'reject_marketplace_change'
          post 'create_product_on_mp'
          post 'update_product_on_mp'
          get 'quantity_inflation_end_of_promotion'
          get 'get_products_for_promotion'
        end
      end

      resources :all_reports do
          collection do
            get "current_monthly_cancel_orders"
          end
      end

      resources :kits do
        collection do
          get :load_market_places_for_kit
          get :load_market_places_for_bulk_kit_upload
          post :upload_kit
          get :taxonomies_json
        end
        member do
          post :upload_kit
        end
      end

      resources :kit_products do
        collection do
          get :load_variants
          get :add_variants
          get :product_variants_json
        end
      end

      # resources :users do
      #   member do
      #   end
      # end

      resources :orders do
        resource :customer, :controller => "orders/customer_details"
        collection do
          get 'oms_success'
          get 'oms_pending'
          get 'partial_orders'
          get 'complete_orders'
          get 'cancel_orders'
          get 'all_orders_sync'
          get 'load_products_skus'
          get 'product_skus_json'
          get 'add_product_skus'
          get 'load_existing_variant_sku'
          get 'update_product_qty'
          get 'generate_dummy_order'
          post 'create_dummy_order'
          get 'disputed_cancel_orders'
        end

        member do
          get 'update_line_item_status'
          post 'place_order_to_oms'
          get 'modify_order'
          get 'validate_push_to_fba'
        end
      end

      resources :sellers do
        collection do
           get 'import_stock'
        end

        resources :holiday_lists do
          collection do
            post 'import'
          end
        end
      end

      resources :market_places

      resources :taxons_market_places do
        collection do
          get :mapped_categories
          get :pre_mapped_categories
          get :add_categories
          get :unmapped_category
          get :get_all_market_place_categories
          get :get_categories
        end
      end

      resources :sellers_market_places_products do
        collection do
          get :load_market_places
          get :pre_mapped_market_places
          get :unmapped_market_place
          get :load_market_places_on_product_import
          get :load_market_places_on_product_export
          get :load_market_places_on_product_listing
          get :show_seller_products
        end
      end

      resources :seller_market_places do
        collection do
          post :generate_api_secret_key
          get :load_form_generate_api_secret_kay
        end
      end

      resources :taxonomies do
        collection do
          get :category_mapping
          post :category_mapping
          get :sync_category
          post :import_categories
        end
      end

      resources :analytics_raw_data, :only => [:index] do
        collection do
          get 'abandoned_carts'
          get 'searched_terms'
          post 'searched_terms'
        end
      end

      resources :reports, :only => [:index, :show] do
        collection do
          post :generate_report
          post :load_form
          get :sales_total
          post :sales_total
          get :seller_wise_sale_total
          post :seller_wise_sale_total
          get :seller_detail_sale_total
          post :seller_detail_sale_total
          get :goods_and_services_tax
          post :goods_and_services_tax
        end
      end

     resources :option_types_market_places do
       collection do
           get :search_option_type
           get :get_mapped_name
           get :add_option_type
         end
     end
     resources :option_values_market_places do
        collection do
          get :search_option_value
          get :get_mapped_value_name
          get :add_option_value
        end
      end
     resources :promotions do
       member do
         put 'force_close'
       end
     end

    end

    #Store Routes
    resources :orders do
      collection do
        get 'close_ios_view'
      end
    end

    resources :brands, only: [:show, :index]

    resources :wishlists do
      collection do
        get 'clear'
      end
    end

    #Store routes
    get "miscs/index"
    post '/product_notifications/notify_me/:variant_id', :to => "product_notifications#notify_me", :as => :product_notify_me
    get '/product_notifications/notify_me/:variant_id', :to => "product_notifications#notify_me", :as => :product_notify_me
    get '/ambassadors', :to => 'home#ambassadors', :as => 'ambassadors'
    post '/wished_products/wished_product/:variant_id', :to => "wished_products#wished_product", :as => :add_to_wishlist
    get '/wished_products/wished_product/:variant_id', :to => "wished_products#wished_product", :as => :add_to_wishlist

    resources :products, :only => [] do
      collection do
        get 'search'
      end
      member do
        get 'stores'
        get 'notify'
      end
    end



    match '/brands/:id/*permalink', :to => 'brands#show', :as => :brands_taxon
    post '/brands/:id/*permalink', :to => 'brands#show', :as => :brands_taxon
    post '/brands/:id', :to => 'brands#show'
    match '/view/*id', :to => 'taxons#show', :as => :shipli_nested_taxons
    get '/taxon/taxon_products', :to => 'taxons#taxon_products', :as => :taxons_products
    match '/sale', :to => 'products#sale', :as => :sale
    match '/discounts', :to => 'products#shipli_sale', :as => :shipli_sale
    match '/warehouse', :to => 'products#warehouse_sale', :as => :warehouse_sale
    match '/discounts/*id', :to => 'products#shipli_sale', :as => :shipli_sale_taxon
    match '/warehouse/*id', :to => 'products#warehouse_sale', :as => :warehouse_sale_taxon

    #routes for APIs
    namespace :api, :defaults => { :format => 'json' } do

      get "variants/search_for_promotion", to: "variants#search_for_promotion", :as => :search_for_promotion
      resources :users do
        collection do
          post 'sign_up'
          post 'sign_in'
          post 'social_sign_up'
          delete 'logout'
          get 'order_history'
          post 'forget_password'
          put 'change_password'
          put "register_device"
        end
      end

      resources :images
      resources :brands do
        member do
          get 'products'
        end
      end
      resources :miscs do
        collection do
          get 'terms_conditions'
          get 'about_us'
        end
      end

      resources :checkouts do
        member do
          get 'delivery_slots'
        end
      end

      resources :wishlists do
        collection do
          post 'remove_product'
          get 'clear_wishlist'
        end
      end

      resources :sellers do
        member do
          get 'products'
          get 'orders'
          get 'users'
        end

        collection do
          put 'ready_for_pickup'
          get 'seller_roles'
          get 'categories'
          get 'stock_locations'
          get 'seller_orders'
          get 'category_products'
          get 'updated_data_status'
          get 'product_search'
        end
      end

      resources :stock_items do
        collection do
          post :out_of_stock
          post :out_of_stock_globally
        end
      end

      resources :seller_users

      resources :products do
        collection do
          get 'search'
          get 'seller_products'
          get 'prototypes'
          get 'shipping_categories'
          get 'option_types'
          get 'properties'
          get 'tax_categories'
          get 'category_products'
          get 'shipli_sale'
          get 'warehouse_sale'
          get 'get_products_for_promotion'
        end

        member do
          get 'notify_me'
          post 'upload_image'
          get 'product_variants'
        end
      end


      resources :market_places
      # match 'market_places/index', :to => 'market_places#index', :as => :market_places
      match '/t/*id', :to => 'taxons#products', :as => :nested_taxons

    end
  end
end

