class AddMissingIndexes < ActiveRecord::Migration
  def up
        add_index :spree_users, :ship_address_id, :name => 'user_ship_addr_idx'
        add_index :spree_users, :bill_address_id, :name => 'user_bill_addr_idx'
        add_index :spree_users, :gender_id, :name => 'user_gender_idx'
        add_index :spree_users, :country_id, :name => 'user_country_idx'
        add_index :spree_sellers, :country_id, :name => 'seller_country_idx'
        add_index :spree_sellers, :business_type_id, :name => 'business_type_idx'
        add_index :spree_products, :tax_category_id, :name => 'tax_category_idx'
        add_index :spree_products, :shipping_category_id, :name => 'shipping_category_idx'
        add_index :spree_products, :seller_id, :name => 'product_seller_idx'
        add_index :spree_products, :brand_id, :name => 'product_brand_idx'
        add_index :spree_oms_logs, :order_id, :name => 'oms_log_order_idx'
        add_index :spree_stock_locations, :state_id, :name => 'stock_loc_state_idx'
        add_index :spree_stock_locations, :country_id, :name => 'stock_loc_country_idx'
        add_index :spree_stock_locations, :seller_id, :name => 'stock_loc_seller_idx'
        add_index :spree_line_items, :is_pick_at_store, :name => 'line_items_cp_idx'
        add_index :spree_line_items, :stock_location_id, :name => 'line_items_sl_idx'
        add_index :spree_market_place_category_lists, :market_place_id, :name => 'mpcl_mp_idx'
        add_index :spree_market_places, :code, :name => 'mp_code_idx'
        add_index :spree_option_values, :option_type_id, :name => 'ovalue_otype_idx'
        add_index :spree_product_properties, :property_id, :name => 'pp_property_idx'
        add_index :spree_shipments, :address_id, :name => 'shipment_addr_idx'
        add_index :spree_shipments, :stock_location_id, :name => 'shipment_stock_loc_idx'
        add_index :spree_search_terms, :user_id, :name => 'search_term_user_idx'
        add_index :spree_recent_market_place_changes, :product_id, :name => 'rmpc_product_idx'
        add_index :spree_recent_market_place_changes, :market_place_id, :name => 'rmpc_mp_idx'
        add_index :spree_recent_market_place_changes, :variant_id, :name => 'rmpc_variant_idx'
        add_index :spree_recent_market_place_changes, :seller_id, :name => 'rmpc_seller_idx'
        add_index :spree_addresses, :country_id, :name => 'addr_country_idx'
        add_index :spree_addresses, :state_id, :name => 'addr_state_idx'
        add_index :spree_bank_details, :seller_id, :name => 'bank_detail_seller_idx'
        add_index :spree_adjustments, :source_id, :name => 'adjustment_src_idx'
        add_index :spree_adjustments, :originator_id, :name => 'adjustment_originator_idx'
        add_index :spree_brands, :name, :name => 'brand_name_idx'
        add_index :spree_payments, :source_id, :name => 'payment_src_idx'
        add_index :spree_payments, :payment_method_id, :name => 'payment_pm_idx'
        add_index :spree_option_values_variants, :option_value_id, :name => 'ovvariant_ovalue_idx'
        add_index :spree_description_managements, :market_place_id, :name => 'desc_mgt_mp_idx'
        add_index :spree_description_managements, :product_id, :name => 'desc_mgt_product_idx'
        add_index :spree_orders, :email, :name => 'order_email_idx'
        add_index :spree_orders, :bill_address_id, :name => 'order_bill_addr_idx'
        add_index :spree_orders, :ship_address_id, :name => 'order_ship_addr_idx'
        add_index :spree_orders, :shipping_method_id, :name => 'order_ship_method_idx'
        add_index :spree_price_managements, :market_place_id, :name => 'price_mg_mp_idx'
        add_index :spree_price_managements, :variant_id, :name => 'price_mg_variant_idx'
        add_index :spree_product_option_types, :product_id, :name => 'potype_product_idx'
        add_index :spree_product_option_types, :option_type_id, :name => 'potype_otype_idx'
        add_index :spree_stock_transfers, :seller_id, :name => 'stock_transfer_seller_idx'
        add_index :spree_states, :country_id, :name => 'state_country_idx'
        add_index :spree_variants, :upc, :name => 'variant_upc_idx'
        add_index :spree_stock_movements, :originator_id, :name => 'stock_move_originator_idx'
        add_index :spree_stock_items, :variant_id, :name => 'stock_item_variant_idx'
        add_index :spree_store_addresses, :seller_id, :name => 'store_addr_seller_idx'
        add_index :spree_store_addresses, :country_id, :name => 'store_addr_country_idx'
        add_index :spree_state_changes, :user_id, :name => 'state_change_user_idx'
        add_index :spree_state_changes, :stateful_id, :name => 'state_change_stateful_idx'
        add_index :user_devices, :user_id, :name => 'user_device_user_idx'
        add_index :user_devices, :device_id, :name => 'user_device_device_idx'
        add_index :spree_shipping_rates, :shipping_method_id, :name => 'sr_shipping_method_idx'
        add_index :spree_user_authentications, :user_id, :name => 'user_auth_user_idx'
        add_index :spree_taxons_market_places, :market_place_category_id, :name => 'tmp_mp_category_idx'
        add_index :spree_wishlists, :user_id, :name => 'wishlist_user_idx'
      end

      def down
        remove_index :spree_users, :name => 'user_ship_addr_idx'
        remove_index :spree_users, :name => 'user_bill_addr_idx'
        remove_index :spree_users, :name => 'user_gender_idx'
        remove_index :spree_users, :name => 'user_country_idx'
        remove_index :spree_sellers, :name => 'seller_country_idx'
        remove_index :spree_sellers, :name => 'business_type_idx'
        remove_index :spree_products, :name => 'tax_category_idx'
        remove_index :spree_products, :name => 'shipping_category_idx'
        remove_index :spree_products, :name => 'product_seller_idx'
        remove_index :spree_products, :name => 'product_brand_idx'
        remove_index :spree_oms_logs, :name => 'oms_log_order_idx'
        remove_index :spree_stock_locations, :name => 'stock_loc_state_idx'
        remove_index :spree_stock_locations, :name => 'stock_loc_country_idx'
        remove_index :spree_stock_locations, :name => 'stock_loc_seller_idx'
        remove_index :spree_line_items, :name => 'line_items_cp_idx'
        remove_index :spree_line_items, :name => 'line_items_sl_idx'
        remove_index :spree_market_place_category_lists, :name => 'mpcl_mp_idx'
        remove_index :spree_market_places, :name => 'mp_code_idx'
        remove_index :spree_option_values, :name => 'ovalue_otype_idx'
        remove_index :spree_product_properties, :name => 'pp_property_idx'
        remove_index :spree_shipments, :name => 'shipment_addr_idx'
        remove_index :spree_shipments, :name => 'shipment_stock_loc_idx'
        remove_index :spree_search_terms, :name => 'search_term_user_idx'
        remove_index :spree_recent_market_place_changes, :name => 'rmpc_product_idx'
        remove_index :spree_recent_market_place_changes, :name => 'rmpc_mp_idx'
        remove_index :spree_recent_market_place_changes, :name => 'rmpc_variant_idx'
        remove_index :spree_recent_market_place_changes, :name => 'rmpc_seller_idx'
        remove_index :spree_addresses, :name => 'addr_country_idx'
        remove_index :spree_addresses, :name => 'addr_state_idx'
        remove_index :spree_bank_details, :name => 'bank_detail_seller_idx'
        remove_index :spree_adjustments, :name => 'adjustment_src_idx'
        remove_index :spree_adjustments, :name => 'adjustment_originator_idx'
        remove_index :spree_brands, :name => 'brand_name_idx'
        remove_index :spree_payments, :name => 'payment_src_idx'
        remove_index :spree_payments, :name => 'payment_pm_idx'
        remove_index :spree_option_values_variants, :name => 'ovvariant_ovalue_idx'
        remove_index :spree_description_managements, :name => 'desc_mgt_mp_idx'
        remove_index :spree_description_managements, :name => 'desc_mgt_product_idx'
        remove_index :spree_orders, :name => 'order_email_idx'
        remove_index :spree_orders, :name => 'order_bill_addr_idx'
        remove_index :spree_orders, :name => 'order_ship_addr_idx'
        remove_index :spree_orders, :name => 'order_ship_method_idx'
        remove_index :spree_price_managements, :name => 'price_mg_mp_idx'
        remove_index :spree_price_managements, :name => 'price_mg_variant_idx'
        remove_index :spree_product_option_types, :name => 'potype_product_idx'
        remove_index :spree_product_option_types, :name => 'potype_otype_idx'
        remove_index :spree_stock_transfers, :name => 'stock_transfer_seller_idx'
        remove_index :spree_states, :name => 'state_country_idx'
        remove_index :spree_variants, :name => 'variant_upc_idx'
        remove_index :spree_stock_movements, :name => 'stock_move_originator_idx'
        remove_index :spree_stock_items, :name => 'stock_item_variant_idx'
        remove_index :spree_store_addresses, :name => 'store_addr_seller_idx'
        remove_index :spree_store_addresses, :name => 'store_addr_country_idx'
        remove_index :spree_state_changes, :name => 'state_change_user_idx'
        remove_index :spree_state_changes, :name => 'state_change_stateful_idx'
        remove_index :user_devices, :name => 'user_device_user_idx'
        remove_index :user_devices, :name => 'user_device_device_idx'
        remove_index :spree_shipping_rates, :name => 'sr_shipping_method_idx'
        remove_index :spree_user_authentications, :name => 'user_auth_user_idx'
        remove_index :spree_taxons_market_places, :name => 'tmp_mp_category_idx'
        remove_index :spree_wishlists, :name => 'wishlist_user_idx'
      end
end
