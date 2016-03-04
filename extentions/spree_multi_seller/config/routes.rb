Spree::Core::Engine.routes.draw do

  resources :sellers, :except => [:show] do
    member do
      get 'locations'
    end
  end

  namespace :admin do
    # match "/dashboard", :to => "sellers#index", :as => :dashboard
    post "/sellers/search", :to => "sellers#index"
    # post "/admin/sellers/deactive", :to => "sellers#deactive"
    get "/sellers/:permalink/:id/change_warehouse", :to => "stock_locations#change_warehouse"
    get '/sellers/:seller_id/seller_users/', :to => "seller_users#index", :as => :seller_users
    get '/sellers/:seller_id/seller_market_places/', :to => "seller_market_places#index", :as => :seller_market_places
    resources :products do
      member do
        get 'reject_reason'
        put 'approved'
        put 'reject'
      end
    end
    resources :sellers do
      member do
        get 'active'
        get 'deactive'
        put 'deactivated'
        post 'upload_product'
        post 'list_product'
        post 'add_warehouse_sale'
        get 'stock_setting'
      end
      collection do
        post 'upload_product'
        post 'list_product'
        post 'add_warehouse_sale'
        post 'manage_stock_settings'
      end
      resources :store_addresses do
        collection do
          get 'download_sample'
        end
      end
      resources :bank_details
      resources :seller_categories do
      end
      resources :seller_market_places
      #resources :users, :only => [:index]
      resources :seller_users do
        collection do
          get 'select'
        end
      end
    end
  end
end
