# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160224130207) do

  create_table "apn_devices", :force => true do |t|
    t.string   "token",              :default => "", :null => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.datetime "last_registered_at"
  end

  add_index "apn_devices", ["token"], :name => "index_apn_devices_on_token", :unique => true

  create_table "apn_notifications", :force => true do |t|
    t.integer  "device_id",                        :null => false
    t.integer  "errors_nb",         :default => 0
    t.string   "device_language"
    t.string   "sound"
    t.string   "alert"
    t.integer  "badge"
    t.text     "custom_properties"
    t.datetime "sent_at"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "apn_notifications", ["device_id"], :name => "index_apn_notifications_on_device_id"

  create_table "ckeditor_assets", :force => true do |t|
    t.string   "data_file_name",                  :null => false
    t.string   "data_content_type"
    t.integer  "data_file_size"
    t.integer  "assetable_id"
    t.string   "assetable_type",    :limit => 30
    t.string   "type",              :limit => 30
    t.integer  "width"
    t.integer  "height"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "ckeditor_assets", ["assetable_type", "assetable_id"], :name => "idx_ckeditor_assetable"
  add_index "ckeditor_assets", ["assetable_type", "type", "assetable_id"], :name => "idx_ckeditor_assetable_type"

  create_table "comments", :force => true do |t|
    t.integer  "commentable_id",   :default => 0
    t.string   "commentable_type", :default => ""
    t.string   "title",            :default => ""
    t.text     "body"
    t.string   "subject",          :default => ""
    t.integer  "user_id",          :default => 0,  :null => false
    t.integer  "parent_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "comments", ["commentable_id"], :name => "index_comments_on_commentable_id"
  add_index "comments", ["user_id"], :name => "index_comments_on_user_id"

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "market_place_product_status", :force => true do |t|
    t.integer  "market_places_id"
    t.string   "name"
    t.string   "code"
    t.integer  "market_place_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "market_place_product_status", ["code"], :name => "index_market_place_product_status_on_code"
  add_index "market_place_product_status", ["market_place_id"], :name => "index_market_place_product_status_on_market_place_id"

  create_table "seller_market_place_product_status", :force => true do |t|
    t.integer  "market_place_product_status_id"
    t.integer  "seller_market_place_product_id"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "seller_market_place_product_status", ["market_place_product_status_id"], :name => "add_index_to_smpps_mpps"
  add_index "seller_market_place_product_status", ["seller_market_place_product_id"], :name => "add_index_to_smpps_smpp"

  create_table "spree_activators", :force => true do |t|
    t.string   "description"
    t.datetime "expires_at"
    t.datetime "starts_at"
    t.string   "name"
    t.string   "event_name"
    t.string   "type"
    t.integer  "usage_limit"
    t.string   "match_policy", :default => "all"
    t.string   "code"
    t.boolean  "advertise",    :default => false
    t.string   "path"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "spree_addresses", :force => true do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "zipcode"
    t.string   "phone"
    t.string   "state_name"
    t.string   "alternative_phone"
    t.string   "company"
    t.integer  "state_id"
    t.integer  "country_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "spree_addresses", ["country_id"], :name => "addr_country_idx"
  add_index "spree_addresses", ["firstname"], :name => "index_addresses_on_firstname"
  add_index "spree_addresses", ["lastname"], :name => "index_addresses_on_lastname"
  add_index "spree_addresses", ["state_id"], :name => "addr_state_idx"

  create_table "spree_adjustments", :force => true do |t|
    t.integer  "source_id"
    t.string   "source_type"
    t.integer  "adjustable_id"
    t.string   "adjustable_type"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.decimal  "amount",          :precision => 10, :scale => 2
    t.string   "label"
    t.boolean  "mandatory"
    t.boolean  "eligible",                                       :default => true
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
    t.string   "state"
  end

  add_index "spree_adjustments", ["adjustable_id"], :name => "index_adjustments_on_order_id"
  add_index "spree_adjustments", ["originator_id"], :name => "adjustment_originator_idx"
  add_index "spree_adjustments", ["source_id"], :name => "adjustment_src_idx"

  create_table "spree_assets", :force => true do |t|
    t.integer  "viewable_id"
    t.string   "viewable_type"
    t.integer  "attachment_width"
    t.integer  "attachment_height"
    t.integer  "attachment_file_size"
    t.integer  "position"
    t.string   "attachment_content_type"
    t.string   "attachment_file_name"
    t.string   "type",                    :limit => 75
    t.datetime "attachment_updated_at"
    t.text     "alt"
  end

  add_index "spree_assets", ["viewable_id"], :name => "index_assets_on_viewable_id"
  add_index "spree_assets", ["viewable_type", "type"], :name => "index_assets_on_viewable_type_and_type"

  create_table "spree_authentication_methods", :force => true do |t|
    t.string   "environment"
    t.string   "provider"
    t.string   "api_key"
    t.string   "api_secret"
    t.boolean  "active"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "spree_bank_details", :force => true do |t|
    t.string   "name"
    t.string   "branch"
    t.string   "address"
    t.string   "account_number"
    t.string   "ifsc_code"
    t.integer  "seller_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.string   "account_name"
  end

  add_index "spree_bank_details", ["seller_id"], :name => "bank_detail_seller_idx"

  create_table "spree_beta_users", :force => true do |t|
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "spree_block_reviews", :force => true do |t|
    t.text     "block_comment"
    t.integer  "review_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "spree_blogs", :force => true do |t|
    t.string   "title"
    t.string   "permalink"
    t.string   "meta_description"
    t.string   "meta_keywords"
    t.text     "body"
    t.string   "link"
    t.string   "type"
    t.integer  "position"
    t.date     "from"
    t.date     "to"
    t.date     "publication_date_from"
    t.date     "publication_date_to"
    t.boolean  "active",                :default => false
    t.datetime "published_at"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
  end

  add_index "spree_blogs", ["permalink"], :name => "index_spree_blogs_on_permalink", :unique => true

  create_table "spree_brands", :force => true do |t|
    t.string   "name",                :null => false
    t.string   "description"
    t.string   "permalink"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "banner_file_name"
    t.string   "banner_content_type"
    t.integer  "banner_file_size"
    t.datetime "banner_updated_at"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  add_index "spree_brands", ["name"], :name => "brand_name_idx"

  create_table "spree_business_types", :force => true do |t|
    t.string   "business_type"
    t.string   "description"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "spree_calculators", :force => true do |t|
    t.string   "type"
    t.integer  "calculable_id"
    t.string   "calculable_type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  create_table "spree_configurations", :force => true do |t|
    t.string   "name"
    t.string   "type",       :limit => 50
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "spree_configurations", ["name", "type"], :name => "index_spree_configurations_on_name_and_type"

  create_table "spree_countries", :force => true do |t|
    t.string  "iso_name"
    t.string  "iso"
    t.string  "iso3"
    t.string  "name"
    t.integer "numcode"
    t.boolean "states_required", :default => true
  end

  create_table "spree_credit_cards", :force => true do |t|
    t.string   "month"
    t.string   "year"
    t.string   "cc_type"
    t.string   "last_digits"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "start_month"
    t.string   "start_year"
    t.string   "issue_number"
    t.integer  "address_id"
    t.string   "gateway_customer_profile_id"
    t.string   "gateway_payment_profile_id"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  create_table "spree_description_managements", :force => true do |t|
    t.text     "description",                        :null => false
    t.integer  "market_place_id",                    :null => false
    t.integer  "product_id",                         :null => false
    t.text     "meta_description"
    t.text     "package_content"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.boolean  "is_active",        :default => true, :null => false
  end

  add_index "spree_description_managements", ["is_active"], :name => "index_spree_description_managements_on_is_active"
  add_index "spree_description_managements", ["market_place_id"], :name => "desc_mgt_mp_idx"
  add_index "spree_description_managements", ["product_id"], :name => "desc_mgt_product_idx"

  create_table "spree_error_logs", :force => true do |t|
    t.string   "title"
    t.text     "log"
    t.string   "status"
    t.string   "git_reference"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "spree_feedback_reviews", :force => true do |t|
    t.integer  "user_id"
    t.integer  "review_id",                    :null => false
    t.integer  "rating",     :default => 0
    t.text     "comment"
    t.datetime "created_at",                   :null => false
    t.datetime "updated_at",                   :null => false
    t.string   "locale",     :default => "en"
  end

  add_index "spree_feedback_reviews", ["review_id"], :name => "index_feedback_reviews_on_review_id"
  add_index "spree_feedback_reviews", ["user_id"], :name => "index_feedback_reviews_on_user_id"

  create_table "spree_gateways", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.text     "description"
    t.boolean  "active",      :default => true
    t.string   "environment", :default => "development"
    t.string   "server",      :default => "test"
    t.boolean  "test_mode",   :default => true
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  create_table "spree_genders", :force => true do |t|
    t.string   "name"
    t.integer  "position"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "spree_holiday_lists", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.date     "from",                          :null => false
    t.date     "to"
    t.boolean  "active",      :default => true
    t.integer  "seller_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "spree_inventory_units", :force => true do |t|
    t.string   "state"
    t.integer  "variant_id"
    t.integer  "order_id"
    t.integer  "shipment_id"
    t.integer  "return_authorization_id"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.boolean  "pending",                 :default => true
  end

  add_index "spree_inventory_units", ["order_id"], :name => "index_inventory_units_on_order_id"
  add_index "spree_inventory_units", ["shipment_id"], :name => "index_inventory_units_on_shipment_id"
  add_index "spree_inventory_units", ["variant_id"], :name => "index_inventory_units_on_variant_id"

  create_table "spree_kit_products", :force => true do |t|
    t.integer  "kit_id"
    t.integer  "product_id"
    t.integer  "quantity"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "variant_id"
  end

  add_index "spree_kit_products", ["kit_id"], :name => "index_spree_kit_products_on_kit_id"
  add_index "spree_kit_products", ["product_id"], :name => "index_spree_kit_products_on_product_id"
  add_index "spree_kit_products", ["variant_id"], :name => "index_spree_kit_products_on_variant_id"

  create_table "spree_kits", :force => true do |t|
    t.integer  "seller_id"
    t.string   "name"
    t.string   "sku"
    t.text     "description"
    t.integer  "quantity"
    t.boolean  "is_common_stock", :default => true
    t.boolean  "is_active",       :default => true
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
  end

  add_index "spree_kits", ["seller_id"], :name => "index_spree_kits_on_seller_id"

  create_table "spree_labels", :force => true do |t|
    t.string  "title"
    t.string  "color"
    t.string  "shape"
    t.integer "seller_id"
    t.boolean "is_approved", :default => false
  end

  create_table "spree_line_items", :force => true do |t|
    t.integer  "variant_id"
    t.integer  "order_id"
    t.integer  "quantity",                                                           :null => false
    t.decimal  "price",             :precision => 8, :scale => 2,                    :null => false
    t.datetime "created_at",                                                         :null => false
    t.datetime "updated_at",                                                         :null => false
    t.string   "currency"
    t.boolean  "is_pick_at_store",                                :default => false
    t.boolean  "picked_up",                                       :default => false
    t.integer  "stock_location_id"
    t.date     "item_pickup_at"
    t.boolean  "ready_for_pickup",                                :default => false
    t.decimal  "rcp",               :precision => 8, :scale => 2
    t.string   "delivery_time"
    t.integer  "kit_id"
  end

  add_index "spree_line_items", ["is_pick_at_store"], :name => "line_items_cp_idx"
  add_index "spree_line_items", ["kit_id"], :name => "index_spree_line_items_on_kit_id"
  add_index "spree_line_items", ["order_id"], :name => "index_spree_line_items_on_order_id"
  add_index "spree_line_items", ["stock_location_id"], :name => "line_items_sl_idx"
  add_index "spree_line_items", ["variant_id"], :name => "index_spree_line_items_on_variant_id"

  create_table "spree_log_entries", :force => true do |t|
    t.integer  "source_id"
    t.string   "source_type"
    t.text     "details"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "spree_mail_methods", :force => true do |t|
    t.string   "environment"
    t.boolean  "active",      :default => true
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  create_table "spree_market_place_category_lists", :force => true do |t|
    t.string   "name",            :null => false
    t.string   "category_code",   :null => false
    t.integer  "market_place_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "spree_market_place_category_lists", ["market_place_id"], :name => "mpcl_mp_idx"

  create_table "spree_market_places", :force => true do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "domain_url"
  end

  add_index "spree_market_places", ["code"], :name => "mp_code_idx"

  create_table "spree_mp_order_line_items", :force => true do |t|
    t.integer  "order_id",             :null => false
    t.text     "market_place_details"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "spree_mp_order_line_items", ["order_id"], :name => "index_spree_mp_order_line_items_on_order_id"

  create_table "spree_newsletter_subscribers", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "spree_newsletter_templates", :force => true do |t|
    t.string   "title"
    t.text     "template"
    t.boolean  "is_active"
    t.date     "for_date"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "spree_oms_logs", :force => true do |t|
    t.integer  "order_id",             :null => false
    t.string   "oms_reference_number"
    t.string   "oms_api_responce"
    t.string   "oms_api_message"
    t.text     "server_error_log"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "spree_oms_logs", ["order_id"], :name => "oms_log_order_idx"

  create_table "spree_option_types", :force => true do |t|
    t.string   "name",         :limit => 100
    t.string   "presentation", :limit => 100
    t.integer  "position",                    :default => 0, :null => false
    t.datetime "created_at",                                 :null => false
    t.datetime "updated_at",                                 :null => false
  end

  create_table "spree_option_types_market_places", :force => true do |t|
    t.integer  "option_type_id"
    t.integer  "market_place_id"
    t.string   "name"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "spree_option_types_market_places", ["market_place_id"], :name => "index_spree_option_types_market_places_on_market_place_id"
  add_index "spree_option_types_market_places", ["option_type_id"], :name => "index_spree_option_types_market_places_on_option_type_id"

  create_table "spree_option_types_prototypes", :id => false, :force => true do |t|
    t.integer "prototype_id"
    t.integer "option_type_id"
  end

  create_table "spree_option_values", :force => true do |t|
    t.integer  "position"
    t.string   "name"
    t.string   "presentation"
    t.integer  "option_type_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "spree_option_values", ["option_type_id"], :name => "ovalue_otype_idx"

  create_table "spree_option_values_market_places", :force => true do |t|
    t.integer  "option_value_id"
    t.integer  "option_type_id"
    t.integer  "market_place_id"
    t.string   "name"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "spree_option_values_market_places", ["market_place_id"], :name => "index_spree_option_values_market_places_on_market_place_id"
  add_index "spree_option_values_market_places", ["option_type_id"], :name => "index_spree_option_values_market_places_on_option_type_id"
  add_index "spree_option_values_market_places", ["option_value_id"], :name => "index_spree_option_values_market_places_on_option_value_id"

  create_table "spree_option_values_variants", :id => false, :force => true do |t|
    t.integer "variant_id"
    t.integer "option_value_id"
  end

  add_index "spree_option_values_variants", ["option_value_id"], :name => "ovvariant_ovalue_idx"
  add_index "spree_option_values_variants", ["variant_id", "option_value_id"], :name => "index_option_values_variants_on_variant_id_and_option_value_id"
  add_index "spree_option_values_variants", ["variant_id"], :name => "index_spree_option_values_variants_on_variant_id"

  create_table "spree_orders", :force => true do |t|
    t.string   "number"
    t.decimal  "item_total",                :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "total",                     :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.string   "state"
    t.decimal  "adjustment_total",          :precision => 10, :scale => 2, :default => 0.0,   :null => false
    t.integer  "user_id"
    t.datetime "completed_at"
    t.integer  "bill_address_id"
    t.integer  "ship_address_id"
    t.decimal  "payment_total",             :precision => 10, :scale => 2, :default => 0.0
    t.integer  "shipping_method_id"
    t.string   "shipment_state"
    t.string   "payment_state"
    t.string   "email"
    t.text     "special_instructions"
    t.datetime "created_at",                                                                  :null => false
    t.datetime "updated_at",                                                                  :null => false
    t.string   "currency"
    t.string   "last_ip_address"
    t.boolean  "send_as_gift",                                             :default => false
    t.string   "greating_message"
    t.date     "delivery_date"
    t.string   "delivery_time"
    t.integer  "market_place_id"
    t.string   "market_place_order_no"
    t.string   "market_place_order_status"
    t.string   "fulflmnt_state"
    t.string   "fulflmnt_tracking_no"
    t.text     "market_place_details"
    t.boolean  "is_cancel",                                                :default => false
    t.datetime "order_date"
    t.datetime "last_updated_date"
    t.string   "cart_no"
    t.text     "invoice_details"
    t.datetime "order_canceled_date"
    t.integer  "seller_id"
    t.boolean  "cancel_on_fba",                                            :default => false
    t.boolean  "is_bypass",                                                :default => false, :null => false
  end

  add_index "spree_orders", ["bill_address_id"], :name => "order_bill_addr_idx"
  add_index "spree_orders", ["cart_no"], :name => "index_spree_orders_on_cart_no"
  add_index "spree_orders", ["email"], :name => "order_email_idx"
  add_index "spree_orders", ["is_bypass"], :name => "index_spree_orders_on_is_bypass"
  add_index "spree_orders", ["last_updated_date"], :name => "index_spree_orders_on_last_updated_date"
  add_index "spree_orders", ["market_place_id"], :name => "index_spree_orders_on_market_place_id"
  add_index "spree_orders", ["market_place_order_no"], :name => "index_spree_orders_on_market_place_order_no"
  add_index "spree_orders", ["number"], :name => "index_spree_orders_on_number"
  add_index "spree_orders", ["order_date"], :name => "index_spree_orders_on_order_date"
  add_index "spree_orders", ["seller_id", "market_place_order_no"], :name => "index_spree_orders_on_seller_id_and_market_place_order_no", :unique => true
  add_index "spree_orders", ["seller_id"], :name => "index_spree_orders_on_seller_id"
  add_index "spree_orders", ["ship_address_id"], :name => "order_ship_addr_idx"
  add_index "spree_orders", ["shipping_method_id"], :name => "order_ship_method_idx"
  add_index "spree_orders", ["user_id"], :name => "index_spree_orders_on_user_id"

  create_table "spree_pages", :force => true do |t|
    t.string   "title"
    t.string   "permalink"
    t.string   "meta_description"
    t.string   "meta_keywords"
    t.text     "body"
    t.string   "link"
    t.string   "type"
    t.integer  "position"
    t.boolean  "in_nav_menu",      :default => false
    t.datetime "published_at"
    t.integer  "product_id"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
  end

  add_index "spree_pages", ["permalink"], :name => "index_spree_pages_on_permalink", :unique => true

  create_table "spree_pages_products", :id => false, :force => true do |t|
    t.integer "page_id"
    t.integer "product_id"
  end

  add_index "spree_pages_products", ["page_id"], :name => "index_spree_pages_products_on_page_id"
  add_index "spree_pages_products", ["product_id"], :name => "index_spree_pages_products_on_product_id"

  create_table "spree_pages_taxons", :id => false, :force => true do |t|
    t.integer "page_id"
    t.integer "taxon_id"
  end

  add_index "spree_pages_taxons", ["page_id"], :name => "index_spree_pages_taxons_on_page_id"
  add_index "spree_pages_taxons", ["taxon_id"], :name => "index_spree_pages_taxons_on_taxon_id"

  create_table "spree_payment_methods", :force => true do |t|
    t.string   "type"
    t.string   "name"
    t.text     "description"
    t.boolean  "active",      :default => true
    t.string   "environment", :default => "development"
    t.datetime "deleted_at"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "display_on"
  end

  create_table "spree_payments", :force => true do |t|
    t.decimal  "amount",               :precision => 10, :scale => 2, :default => 0.0, :null => false
    t.integer  "order_id"
    t.integer  "source_id"
    t.string   "source_type"
    t.integer  "payment_method_id"
    t.string   "state"
    t.string   "response_code"
    t.string   "avs_response"
    t.datetime "created_at",                                                           :null => false
    t.datetime "updated_at",                                                           :null => false
    t.string   "identifier"
    t.string   "cvv_response_code"
    t.string   "cvv_response_message"
  end

  add_index "spree_payments", ["order_id"], :name => "index_spree_payments_on_order_id"
  add_index "spree_payments", ["payment_method_id"], :name => "payment_pm_idx"
  add_index "spree_payments", ["source_id"], :name => "payment_src_idx"

  create_table "spree_paypal_accounts", :force => true do |t|
    t.string "email"
    t.string "payer_id"
    t.string "payer_country"
    t.string "payer_status"
  end

  create_table "spree_posts_products", :id => false, :force => true do |t|
    t.integer "post_id"
    t.integer "product_id"
  end

  add_index "spree_posts_products", ["post_id"], :name => "index_spree_posts_products_on_post_id"
  add_index "spree_posts_products", ["product_id"], :name => "index_spree_posts_products_on_product_id"

  create_table "spree_posts_taxon_posts", :id => false, :force => true do |t|
    t.integer "post_id"
    t.integer "taxon_post_id"
  end

  add_index "spree_posts_taxon_posts", ["post_id"], :name => "index_spree_posts_taxon_posts_on_pt_id"
  add_index "spree_posts_taxon_posts", ["taxon_post_id"], :name => "index_spree_posts_taxon_posts_on_p_id"

  create_table "spree_posts_taxons", :id => false, :force => true do |t|
    t.integer "post_id"
    t.integer "taxon_id"
  end

  add_index "spree_posts_taxons", ["post_id"], :name => "index_spree_posts_taxons_on_post_id"
  add_index "spree_posts_taxons", ["taxon_id"], :name => "index_spree_posts_taxons_on_taxon_id"

  create_table "spree_preferences", :force => true do |t|
    t.text     "value"
    t.string   "key"
    t.string   "value_type"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "spree_preferences", ["key"], :name => "index_spree_preferences_on_key", :unique => true

  create_table "spree_price_managements", :force => true do |t|
    t.decimal  "selling_price",    :precision => 15, :scale => 2,                   :null => false
    t.decimal  "special_price",    :precision => 15, :scale => 2
    t.decimal  "settlement_price", :precision => 15, :scale => 2
    t.integer  "market_place_id"
    t.integer  "variant_id"
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.boolean  "is_active",                                       :default => true, :null => false
  end

  add_index "spree_price_managements", ["is_active"], :name => "index_spree_price_managements_on_is_active"
  add_index "spree_price_managements", ["market_place_id"], :name => "price_mg_mp_idx"
  add_index "spree_price_managements", ["variant_id"], :name => "price_mg_variant_idx"

  create_table "spree_prices", :force => true do |t|
    t.integer "variant_id",                               :null => false
    t.decimal "amount",     :precision => 8, :scale => 2
    t.string  "currency"
  end

  add_index "spree_prices", ["variant_id"], :name => "fk_prices_variants"

  create_table "spree_product_labels", :force => true do |t|
    t.integer "product_id"
    t.integer "label_id"
    t.integer "position"
  end

  create_table "spree_product_notifications", :force => true do |t|
    t.integer  "user_id"
    t.integer  "variant_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "spree_product_option_types", :force => true do |t|
    t.integer  "position"
    t.integer  "product_id"
    t.integer  "option_type_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "spree_product_option_types", ["option_type_id"], :name => "potype_otype_idx"
  add_index "spree_product_option_types", ["product_id"], :name => "potype_product_idx"

  create_table "spree_product_properties", :force => true do |t|
    t.text     "value"
    t.integer  "product_id"
    t.integer  "property_id"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
    t.integer  "position",    :default => 0
  end

  add_index "spree_product_properties", ["product_id"], :name => "index_product_properties_on_product_id"
  add_index "spree_product_properties", ["property_id"], :name => "pp_property_idx"

  create_table "spree_products", :force => true do |t|
    t.string   "name",                                               :default => "",    :null => false
    t.text     "description"
    t.datetime "available_on"
    t.datetime "deleted_at"
    t.string   "permalink"
    t.text     "meta_description"
    t.string   "meta_keywords"
    t.integer  "tax_category_id"
    t.integer  "shipping_category_id"
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
    t.decimal  "avg_rating",           :precision => 7, :scale => 5, :default => 0.0,   :null => false
    t.integer  "reviews_count",                                      :default => 0,     :null => false
    t.integer  "seller_id"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.boolean  "is_approved",                                        :default => false
    t.boolean  "is_reject",                                          :default => false
    t.text     "reject_reason"
    t.string   "company"
    t.string   "website"
    t.string   "url"
    t.boolean  "is_new_arrival",                                     :default => false
    t.boolean  "is_featured",                                        :default => false
    t.boolean  "is_warehouse",                                       :default => false
    t.integer  "brand_id"
    t.boolean  "is_adult",                                           :default => false
    t.integer  "kit_id"
    t.integer  "stock_config_type",                                  :default => 0
    t.text     "package_content"
    t.string   "short_name"
    t.string   "gender",                                             :default => "NA"
  end

  add_index "spree_products", ["available_on"], :name => "index_spree_products_on_available_on"
  add_index "spree_products", ["brand_id"], :name => "product_brand_idx"
  add_index "spree_products", ["deleted_at"], :name => "index_spree_products_on_deleted_at"
  add_index "spree_products", ["kit_id"], :name => "index_spree_products_on_kit_id"
  add_index "spree_products", ["name"], :name => "index_spree_products_on_name"
  add_index "spree_products", ["permalink"], :name => "index_spree_products_on_permalink"
  add_index "spree_products", ["permalink"], :name => "permalink_idx_unique", :unique => true
  add_index "spree_products", ["seller_id"], :name => "product_seller_idx"
  add_index "spree_products", ["shipping_category_id"], :name => "shipping_category_idx"
  add_index "spree_products", ["tax_category_id"], :name => "tax_category_idx"

  create_table "spree_products_promotion_rules", :id => false, :force => true do |t|
    t.integer "product_id"
    t.integer "promotion_rule_id"
  end

  add_index "spree_products_promotion_rules", ["product_id"], :name => "index_products_promotion_rules_on_product_id"
  add_index "spree_products_promotion_rules", ["promotion_rule_id"], :name => "index_products_promotion_rules_on_promotion_rule_id"

  create_table "spree_products_taxons", :force => true do |t|
    t.integer "product_id"
    t.integer "taxon_id"
  end

  add_index "spree_products_taxons", ["product_id"], :name => "index_spree_products_taxons_on_product_id"
  add_index "spree_products_taxons", ["taxon_id"], :name => "index_spree_products_taxons_on_taxon_id"

  create_table "spree_promotion_action_line_items", :force => true do |t|
    t.integer "promotion_action_id"
    t.integer "variant_id"
    t.integer "quantity",            :default => 1
  end

  create_table "spree_promotion_actions", :force => true do |t|
    t.integer "activator_id"
    t.integer "position"
    t.string  "type"
  end

  create_table "spree_promotion_rules", :force => true do |t|
    t.integer  "activator_id"
    t.integer  "user_id"
    t.integer  "product_group_id"
    t.string   "type"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "spree_promotion_rules", ["product_group_id"], :name => "index_promotion_rules_on_product_group_id"
  add_index "spree_promotion_rules", ["user_id"], :name => "index_promotion_rules_on_user_id"

  create_table "spree_promotion_rules_market_places", :id => false, :force => true do |t|
    t.integer "market_place_id"
    t.integer "promotion_rule_id"
  end

  add_index "spree_promotion_rules_market_places", ["market_place_id"], :name => "index_market_places_promotion_rules_on_market_place_id"
  add_index "spree_promotion_rules_market_places", ["promotion_rule_id"], :name => "index_market_places_promotion_rules_on_promotion_rule_id"

  create_table "spree_promotion_rules_sellers", :force => true do |t|
    t.integer "seller_id"
    t.integer "promotion_rule_id"
  end

  add_index "spree_promotion_rules_sellers", ["promotion_rule_id"], :name => "index_seller_promotion_rules_on_promotion_rule_id"
  add_index "spree_promotion_rules_sellers", ["seller_id"], :name => "index_seller_promotion_rules_on_seller_id"

  create_table "spree_promotion_rules_taxons", :id => false, :force => true do |t|
    t.integer "taxon_id"
    t.integer "promotion_rule_id"
  end

  add_index "spree_promotion_rules_taxons", ["promotion_rule_id"], :name => "index_market_places_promotion_rules_on_promotion_rule_id"
  add_index "spree_promotion_rules_taxons", ["taxon_id"], :name => "index_market_places_promotion_rules_on_taxon_id"

  create_table "spree_promotion_rules_users", :id => false, :force => true do |t|
    t.integer "user_id"
    t.integer "promotion_rule_id"
  end

  add_index "spree_promotion_rules_users", ["promotion_rule_id"], :name => "index_promotion_rules_users_on_promotion_rule_id"
  add_index "spree_promotion_rules_users", ["user_id"], :name => "index_promotion_rules_users_on_user_id"

  create_table "spree_promotion_rules_variants", :id => false, :force => true do |t|
    t.integer "variant_id"
    t.integer "promotion_rule_id"
  end

  add_index "spree_promotion_rules_variants", ["promotion_rule_id"], :name => "index_market_places_promotion_rules_on_promotion_rule_id"
  add_index "spree_promotion_rules_variants", ["variant_id"], :name => "index_market_places_promotion_rules_on_variant_id"

  create_table "spree_properties", :force => true do |t|
    t.string   "name"
    t.string   "presentation", :null => false
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "spree_properties_prototypes", :id => false, :force => true do |t|
    t.integer "prototype_id"
    t.integer "property_id"
  end

  create_table "spree_prototypes", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "spree_quantity_inflations", :force => true do |t|
    t.integer  "variant_id",        :null => false
    t.integer  "market_place_id",   :null => false
    t.string   "sku",               :null => false
    t.string   "change_type",       :null => false
    t.string   "next_type",         :null => false
    t.integer  "quantity",          :null => false
    t.integer  "previous_quantity", :null => false
    t.datetime "end_date",          :null => false
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "spree_quantity_inflations", ["market_place_id"], :name => "index_spree_quantity_inflations_on_market_place_id"
  add_index "spree_quantity_inflations", ["variant_id"], :name => "index_spree_quantity_inflations_on_variant_id"

  create_table "spree_recent_market_place_changes", :force => true do |t|
    t.integer  "product_id"
    t.integer  "variant_id"
    t.integer  "seller_id"
    t.integer  "market_place_id"
    t.integer  "updated_by"
    t.text     "description"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.boolean  "update_on_fba",   :default => false
    t.datetime "deleted_at"
  end

  add_index "spree_recent_market_place_changes", ["market_place_id"], :name => "rmpc_mp_idx"
  add_index "spree_recent_market_place_changes", ["product_id"], :name => "rmpc_product_idx"
  add_index "spree_recent_market_place_changes", ["seller_id"], :name => "rmpc_seller_idx"
  add_index "spree_recent_market_place_changes", ["variant_id"], :name => "rmpc_variant_idx"

  create_table "spree_relation_types", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "applies_to"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "spree_relations", :force => true do |t|
    t.integer  "relation_type_id"
    t.integer  "relatable_id"
    t.string   "relatable_type"
    t.integer  "related_to_id"
    t.string   "related_to_type"
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
    t.decimal  "discount_amount",  :precision => 8, :scale => 2, :default => 0.0
  end

  create_table "spree_return_authorizations", :force => true do |t|
    t.string   "number"
    t.string   "state"
    t.decimal  "amount",            :precision => 10, :scale => 2, :default => 0.0, :null => false
    t.integer  "order_id"
    t.text     "reason"
    t.datetime "created_at",                                                        :null => false
    t.datetime "updated_at",                                                        :null => false
    t.integer  "stock_location_id"
  end

  create_table "spree_reviews", :force => true do |t|
    t.integer  "product_id"
    t.string   "name"
    t.string   "location"
    t.integer  "rating"
    t.text     "title"
    t.text     "review"
    t.boolean  "approved",   :default => false
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "user_id"
    t.string   "ip_address"
    t.string   "locale",     :default => "en"
  end

  create_table "spree_roles", :force => true do |t|
    t.string "name"
  end

  create_table "spree_roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "spree_roles_users", ["role_id"], :name => "index_spree_roles_users_on_role_id"
  add_index "spree_roles_users", ["user_id"], :name => "index_spree_roles_users_on_user_id"

  create_table "spree_search_terms", :force => true do |t|
    t.integer  "user_id"
    t.string   "search_term"
    t.integer  "result_count"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  add_index "spree_search_terms", ["user_id"], :name => "search_term_user_idx"

  create_table "spree_seller_categories", :force => true do |t|
    t.integer  "seller_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "taxon_id"
  end

  add_index "spree_seller_categories", ["seller_id"], :name => "index_spree_seller_categories_on_seller_id_and_taxonomy_id"
  add_index "spree_seller_categories", ["seller_id"], :name => "index_spree_seller_categories_on_taxonomy_id_and_seller_id"
  add_index "spree_seller_categories", ["taxon_id", "seller_id"], :name => "index_spree_seller_categories_on_taxon_id_and_seller_id"

  create_table "spree_seller_market_places", :force => true do |t|
    t.integer  "seller_id"
    t.integer  "market_place_id"
    t.datetime "created_at",                               :null => false
    t.datetime "updated_at",                               :null => false
    t.string   "api_key"
    t.string   "fba_api_key"
    t.string   "country"
    t.string   "currency_code"
    t.boolean  "is_active",             :default => true
    t.string   "api_secret_key"
    t.string   "contact_name"
    t.string   "contact_number"
    t.string   "contact_email"
    t.text     "fba_signature"
    t.string   "shipping_code",         :default => "0"
    t.integer  "stock_config_details",  :default => 0
    t.string   "shipping_carrier_code", :default => "FBA"
  end

  add_index "spree_seller_market_places", ["market_place_id"], :name => "index_spree_seller_market_places_on_market_place_id"
  add_index "spree_seller_market_places", ["seller_id"], :name => "index_spree_seller_market_places_on_seller_id"

  create_table "spree_seller_users", :force => true do |t|
    t.integer  "seller_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "spree_seller_users", ["seller_id", "user_id"], :name => "index_spree_seller_users_on_seller_id_and_user_id"
  add_index "spree_seller_users", ["user_id", "seller_id"], :name => "index_spree_seller_users_on_user_id_and_seller_id"

  create_table "spree_sellers", :force => true do |t|
    t.string   "name",                                                                              :null => false
    t.string   "address_1",                                                                         :null => false
    t.string   "address_2"
    t.string   "city",                                                                              :null => false
    t.string   "state"
    t.string   "zip"
    t.integer  "country_id",                                                                        :null => false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "banner_file_name"
    t.string   "banner_content_type"
    t.integer  "banner_file_size"
    t.datetime "banner_updated_at"
    t.string   "roc_number",                                                                        :null => false
    t.datetime "establishment_date"
    t.string   "url"
    t.string   "contact_person_name",                                                               :null => false
    t.string   "contact_person_email",                                                              :null => false
    t.string   "phone",                                                                             :null => false
    t.string   "category_ids"
    t.boolean  "termsandconditions",                                             :default => false
    t.boolean  "is_active",                                                      :default => false
    t.datetime "created_at",                                                                        :null => false
    t.datetime "updated_at",                                                                        :null => false
    t.string   "seller_user_ids"
    t.datetime "deleted_at"
    t.datetime "deactivated_at"
    t.string   "comment"
    t.text     "description"
    t.string   "permalink"
    t.string   "business_name",                                                                     :null => false
    t.decimal  "revenue_share",                    :precision => 8, :scale => 2, :default => 0.0,   :null => false
    t.decimal  "revenue_share_on_ware_house_sale", :precision => 8, :scale => 2, :default => 0.0,   :null => false
    t.integer  "business_type_id"
    t.integer  "stock_config_type",                                              :default => 1
    t.boolean  "is_cm_user",                                                     :default => true
  end

  add_index "spree_sellers", ["business_type_id"], :name => "business_type_idx"
  add_index "spree_sellers", ["country_id"], :name => "seller_country_idx"

  create_table "spree_sellers_market_places_kits", :force => true do |t|
    t.integer  "seller_id"
    t.integer  "market_place_id"
    t.integer  "kit_id"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "spree_sellers_market_places_kits", ["kit_id"], :name => "index_spree_sellers_market_places_kits_on_kit_id"
  add_index "spree_sellers_market_places_kits", ["market_place_id"], :name => "index_spree_sellers_market_places_kits_on_market_place_id"
  add_index "spree_sellers_market_places_kits", ["seller_id"], :name => "index_spree_sellers_market_places_kits_on_seller_id"

  create_table "spree_sellers_market_places_products", :force => true do |t|
    t.integer  "seller_id"
    t.integer  "market_place_id"
    t.integer  "product_id"
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
    t.string   "market_place_product_code"
    t.integer  "stock_config_details",      :default => 0
    t.boolean  "is_active",                 :default => true,                  :null => false
    t.datetime "last_update_on_mp",         :default => '2016-02-16 07:33:59', :null => false
    t.datetime "unmap_mail_sent_at"
  end

  add_index "spree_sellers_market_places_products", ["is_active"], :name => "index_spree_sellers_market_places_products_on_is_active"
  add_index "spree_sellers_market_places_products", ["market_place_id"], :name => "index_spree_sellers_market_places_products_on_market_place_id"
  add_index "spree_sellers_market_places_products", ["product_id"], :name => "index_spree_sellers_market_places_products_on_product_id"
  add_index "spree_sellers_market_places_products", ["seller_id"], :name => "index_spree_sellers_market_places_products_on_seller_id"

  create_table "spree_shipments", :force => true do |t|
    t.string   "tracking"
    t.string   "number"
    t.decimal  "cost",              :precision => 8, :scale => 2
    t.datetime "shipped_at"
    t.integer  "order_id"
    t.integer  "address_id"
    t.string   "state"
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
    t.integer  "stock_location_id"
  end

  add_index "spree_shipments", ["address_id"], :name => "shipment_addr_idx"
  add_index "spree_shipments", ["number"], :name => "index_shipments_on_number"
  add_index "spree_shipments", ["order_id"], :name => "index_spree_shipments_on_order_id"
  add_index "spree_shipments", ["stock_location_id"], :name => "shipment_stock_loc_idx"

  create_table "spree_shipping_categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "spree_shipping_method_categories", :force => true do |t|
    t.integer  "shipping_method_id",   :null => false
    t.integer  "shipping_category_id", :null => false
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
  end

  add_index "spree_shipping_method_categories", ["shipping_category_id"], :name => "index_spree_shipping_method_categories_on_shipping_category_id"
  add_index "spree_shipping_method_categories", ["shipping_method_id"], :name => "index_spree_shipping_method_categories_on_shipping_method_id"

  create_table "spree_shipping_methods", :force => true do |t|
    t.string   "name"
    t.string   "display_on"
    t.datetime "deleted_at"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.string   "tracking_url"
    t.string   "admin_name"
  end

  create_table "spree_shipping_methods_zones", :id => false, :force => true do |t|
    t.integer "shipping_method_id"
    t.integer "zone_id"
  end

  create_table "spree_shipping_rates", :force => true do |t|
    t.integer  "shipment_id"
    t.integer  "shipping_method_id"
    t.boolean  "selected",                                         :default => false
    t.decimal  "cost",               :precision => 8, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
  end

  add_index "spree_shipping_rates", ["shipment_id", "shipping_method_id"], :name => "spree_shipping_rates_join_index", :unique => true
  add_index "spree_shipping_rates", ["shipping_method_id"], :name => "sr_shipping_method_idx"

  create_table "spree_skrill_transactions", :force => true do |t|
    t.string   "email"
    t.float    "amount"
    t.string   "currency"
    t.integer  "transaction_id"
    t.integer  "customer_id"
    t.string   "payment_type"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  create_table "spree_state_changes", :force => true do |t|
    t.string   "name"
    t.string   "previous_state"
    t.integer  "stateful_id"
    t.integer  "user_id"
    t.string   "stateful_type"
    t.string   "next_state"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "spree_state_changes", ["stateful_id"], :name => "state_change_stateful_idx"
  add_index "spree_state_changes", ["user_id"], :name => "state_change_user_idx"

  create_table "spree_states", :force => true do |t|
    t.string  "name"
    t.string  "abbr"
    t.integer "country_id"
  end

  add_index "spree_states", ["country_id"], :name => "state_country_idx"

  create_table "spree_stock_items", :force => true do |t|
    t.integer  "stock_location_id"
    t.integer  "variant_id"
    t.integer  "count_on_hand",        :default => 0,     :null => false
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.boolean  "backorderable",        :default => true
    t.boolean  "virtual_out_of_stock", :default => false
    t.datetime "deleted_at"
  end

  add_index "spree_stock_items", ["stock_location_id", "variant_id"], :name => "stock_item_by_loc_and_var_id"
  add_index "spree_stock_items", ["stock_location_id"], :name => "index_spree_stock_items_on_stock_location_id"
  add_index "spree_stock_items", ["variant_id"], :name => "stock_item_variant_idx"

  create_table "spree_stock_location_holiday_lists", :force => true do |t|
    t.integer  "stock_location_id"
    t.integer  "holiday_list_id"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "spree_stock_locations", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                                :null => false
    t.datetime "updated_at",                                :null => false
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.integer  "state_id"
    t.string   "state_name"
    t.integer  "country_id"
    t.string   "zipcode"
    t.string   "phone"
    t.boolean  "active",                 :default => true
    t.boolean  "backorderable_default",  :default => true
    t.boolean  "propagate_all_variants", :default => true
    t.string   "contact"
    t.string   "email",                                     :null => false
    t.string   "operating_hours"
    t.boolean  "pickup_at",              :default => false
    t.string   "lat"
    t.string   "lng"
    t.string   "locname"
    t.integer  "seller_id"
    t.string   "contact_person_name"
    t.string   "admin_name"
    t.boolean  "is_warehouse",           :default => false
  end

  add_index "spree_stock_locations", ["country_id"], :name => "stock_loc_country_idx"
  add_index "spree_stock_locations", ["seller_id"], :name => "stock_loc_seller_idx"
  add_index "spree_stock_locations", ["state_id"], :name => "stock_loc_state_idx"

  create_table "spree_stock_movements", :force => true do |t|
    t.integer  "stock_item_id"
    t.integer  "quantity",        :default => 0
    t.string   "action"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "originator_id"
    t.string   "originator_type"
  end

  add_index "spree_stock_movements", ["originator_id"], :name => "stock_move_originator_idx"
  add_index "spree_stock_movements", ["stock_item_id"], :name => "index_spree_stock_movements_on_stock_item_id"

  create_table "spree_stock_products", :force => true do |t|
    t.integer  "sellers_market_places_product_id"
    t.integer  "variant_id"
    t.integer  "count_on_hand"
    t.boolean  "virtual_out_of_stock",             :default => false
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
  end

  add_index "spree_stock_products", ["sellers_market_places_product_id"], :name => "index_spree_stock_products_on_sellers_market_places_product_id"
  add_index "spree_stock_products", ["variant_id"], :name => "index_spree_stock_products_on_variant_id"

  create_table "spree_stock_transfers", :force => true do |t|
    t.string   "type"
    t.string   "reference"
    t.integer  "source_location_id"
    t.integer  "destination_location_id"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "number"
    t.integer  "seller_id"
    t.date     "received_date"
    t.integer  "damaged_quantity"
    t.integer  "total_order_cost"
    t.string   "received_by"
    t.date     "expiry_date"
    t.string   "delivery_order"
    t.string   "purchase_order"
    t.string   "delivery_order_scan_copy_file_name"
    t.string   "delivery_order_scan_copy_content_type"
    t.integer  "delivery_order_scan_copy_file_size"
    t.datetime "delivery_order_scan_copy_updated_at"
  end

  add_index "spree_stock_transfers", ["destination_location_id"], :name => "index_spree_stock_transfers_on_destination_location_id"
  add_index "spree_stock_transfers", ["number"], :name => "index_spree_stock_transfers_on_number"
  add_index "spree_stock_transfers", ["seller_id"], :name => "stock_transfer_seller_idx"
  add_index "spree_stock_transfers", ["source_location_id"], :name => "index_spree_stock_transfers_on_source_location_id"

  create_table "spree_store_addresses", :force => true do |t|
    t.integer  "seller_id",                                        :null => false
    t.string   "name"
    t.string   "address"
    t.string   "city",            :limit => 30
    t.string   "state",           :limit => 30
    t.integer  "country_id",                                       :null => false
    t.integer  "zipcode",                                          :null => false
    t.string   "contact",                                          :null => false
    t.string   "email",                                            :null => false
    t.string   "web_url"
    t.string   "operating_hours"
    t.boolean  "pickup_at",                     :default => false
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.string   "lat"
    t.string   "lng"
    t.string   "locname"
  end

  add_index "spree_store_addresses", ["country_id"], :name => "store_addr_country_idx"
  add_index "spree_store_addresses", ["seller_id"], :name => "store_addr_seller_idx"

  create_table "spree_store_credits", :force => true do |t|
    t.integer  "user_id"
    t.decimal  "amount",                  :precision => 8, :scale => 2, :default => 0.0, :null => false
    t.decimal  "remaining_amount",        :precision => 8, :scale => 2, :default => 0.0, :null => false
    t.string   "reason"
    t.datetime "created_at",                                                             :null => false
    t.datetime "updated_at",                                                             :null => false
    t.datetime "expires_at"
    t.string   "store_credit_email_text"
  end

  create_table "spree_sync_market_place_variants", :force => true do |t|
    t.integer  "seller_id"
    t.integer  "market_place_id"
    t.integer  "product_id"
    t.integer  "variant_id"
    t.string   "variant_sku"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "spree_sync_market_place_variants", ["market_place_id"], :name => "index_spree_sync_market_place_variants_on_market_place_id"
  add_index "spree_sync_market_place_variants", ["product_id"], :name => "index_spree_sync_market_place_variants_on_product_id"
  add_index "spree_sync_market_place_variants", ["seller_id"], :name => "index_spree_sync_market_place_variants_on_seller_id"
  add_index "spree_sync_market_place_variants", ["variant_id"], :name => "index_spree_sync_market_place_variants_on_variant_id"

  create_table "spree_tax_categories", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "is_default",  :default => false
    t.datetime "deleted_at"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "spree_tax_rates", :force => true do |t|
    t.decimal  "amount",             :precision => 8, :scale => 5
    t.integer  "zone_id"
    t.integer  "tax_category_id"
    t.boolean  "included_in_price",                                :default => false
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.string   "name"
    t.boolean  "show_rate_in_label",                               :default => true
    t.datetime "deleted_at"
  end

  create_table "spree_taxon_posts", :force => true do |t|
    t.integer  "parent_id"
    t.string   "name"
    t.string   "permalink"
    t.integer  "taxonomy_post_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "meta_description"
    t.string   "meta_keywords"
    t.text     "description"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_update_at"
    t.integer  "position"
    t.datetime "published_at"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "spree_taxon_posts", ["permalink"], :name => "index_spree_post_category_on_permalink", :unique => true
  add_index "spree_taxon_posts", ["permalink"], :name => "index_spree_taxon_posts_on_permalink", :unique => true

  create_table "spree_taxonomies", :force => true do |t|
    t.string   "name",                      :null => false
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
    t.integer  "position",   :default => 0
  end

  create_table "spree_taxonomy_posts", :force => true do |t|
    t.string   "name"
    t.integer  "position"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "spree_taxons", :force => true do |t|
    t.integer  "parent_id"
    t.integer  "position",          :default => 0
    t.string   "name",                                :null => false
    t.string   "permalink"
    t.integer  "taxonomy_id"
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
    t.text     "description"
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.string   "meta_title"
    t.string   "meta_description"
    t.string   "meta_keywords"
    t.integer  "sequence",          :default => 1000
  end

  add_index "spree_taxons", ["parent_id"], :name => "index_taxons_on_parent_id"
  add_index "spree_taxons", ["permalink"], :name => "index_taxons_on_permalink"
  add_index "spree_taxons", ["taxonomy_id"], :name => "index_taxons_on_taxonomy_id"

  create_table "spree_taxons_market_places", :force => true do |t|
    t.integer  "taxon_id"
    t.integer  "market_place_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
    t.string   "name"
    t.string   "market_place_category_id"
  end

  add_index "spree_taxons_market_places", ["market_place_category_id"], :name => "tmp_mp_category_idx"
  add_index "spree_taxons_market_places", ["market_place_id"], :name => "index_spree_taxons_market_places_on_market_place_id"
  add_index "spree_taxons_market_places", ["taxon_id"], :name => "index_spree_taxons_market_places_on_taxon_id"

  create_table "spree_title_managements", :force => true do |t|
    t.text     "name",                              :null => false
    t.integer  "market_place_id",                   :null => false
    t.integer  "product_id",                        :null => false
    t.datetime "created_at",                        :null => false
    t.datetime "updated_at",                        :null => false
    t.boolean  "is_active",       :default => true, :null => false
  end

  add_index "spree_title_managements", ["is_active"], :name => "index_spree_title_managements_on_is_active"
  add_index "spree_title_managements", ["market_place_id"], :name => "index_spree_title_managements_on_market_place_id"
  add_index "spree_title_managements", ["product_id"], :name => "index_spree_title_managements_on_product_id"

  create_table "spree_tokenized_permissions", :force => true do |t|
    t.integer  "permissable_id"
    t.string   "permissable_type"
    t.string   "token"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "spree_tokenized_permissions", ["permissable_id", "permissable_type"], :name => "index_tokenized_name_and_type"

  create_table "spree_trackers", :force => true do |t|
    t.string   "environment"
    t.string   "analytics_id"
    t.boolean  "active",       :default => true
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "spree_uploads", :force => true do |t|
    t.string   "title"
    t.string   "permalink"
    t.text     "presentation"
    t.string   "attachment_content_type"
    t.string   "attachment_file_name"
    t.integer  "attachment_size"
    t.integer  "attachment_width"
    t.integer  "attachment_height"
    t.string   "type"
    t.integer  "position"
    t.integer  "uploadable_id"
    t.string   "uploadable_type"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "spree_user_authentications", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.string   "photo"
    t.string   "location"
  end

  add_index "spree_user_authentications", ["user_id"], :name => "user_auth_user_idx"

  create_table "spree_users", :force => true do |t|
    t.string   "encrypted_password",     :limit => 128
    t.string   "password_salt",          :limit => 128
    t.string   "email"
    t.string   "remember_token"
    t.string   "persistence_token"
    t.string   "reset_password_token"
    t.string   "perishable_token"
    t.integer  "sign_in_count",                         :default => 0,     :null => false
    t.integer  "failed_attempts",                       :default => 0,     :null => false
    t.datetime "last_request_at"
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "login"
    t.integer  "ship_address_id"
    t.integer  "bill_address_id"
    t.string   "authentication_token"
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "reset_password_sent_at"
    t.datetime "created_at",                                               :null => false
    t.datetime "updated_at",                                               :null => false
    t.string   "spree_api_key",          :limit => 48
    t.datetime "remember_created_at"
    t.string   "firstname"
    t.string   "lastname"
    t.date     "dateofbirth"
    t.integer  "gender_id"
    t.integer  "country_id"
    t.string   "contact"
    t.string   "photo_file_name"
    t.string   "photo_content_type"
    t.integer  "photo_file_size"
    t.datetime "photo_updated_at"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.boolean  "terms_and_condition",                   :default => false
    t.datetime "deleted_at"
  end

  add_index "spree_users", ["bill_address_id"], :name => "user_bill_addr_idx"
  add_index "spree_users", ["country_id"], :name => "user_country_idx"
  add_index "spree_users", ["email"], :name => "email_idx_unique", :unique => true
  add_index "spree_users", ["gender_id"], :name => "user_gender_idx"
  add_index "spree_users", ["ship_address_id"], :name => "user_ship_addr_idx"

  create_table "spree_variants", :force => true do |t|
    t.string   "sku",                                               :default => "",    :null => false
    t.decimal  "weight",             :precision => 8,  :scale => 2
    t.decimal  "height",             :precision => 8,  :scale => 2
    t.decimal  "width",              :precision => 8,  :scale => 2
    t.decimal  "depth",              :precision => 8,  :scale => 2
    t.datetime "deleted_at"
    t.boolean  "is_master",                                         :default => false
    t.integer  "product_id"
    t.integer  "count_on_hand",                                     :default => 0
    t.decimal  "cost_price",         :precision => 8,  :scale => 2
    t.string   "cost_currency"
    t.integer  "position"
    t.decimal  "special_price",      :precision => 8,  :scale => 2
    t.decimal  "rcp",                :precision => 8,  :scale => 2
    t.decimal  "selling_price",      :precision => 15, :scale => 2
    t.integer  "fba_quantity",                                      :default => 0
    t.string   "upc"
    t.boolean  "is_created_on_fba",                                 :default => false
    t.text     "validation_message"
    t.boolean  "updated_on_fba",                                    :default => true
    t.integer  "parent_id"
  end

  add_index "spree_variants", ["fba_quantity"], :name => "index_spree_variants_on_fba_quantity"
  add_index "spree_variants", ["product_id"], :name => "index_spree_variants_on_product_id"
  add_index "spree_variants", ["sku"], :name => "index_spree_variants_on_sku"
  add_index "spree_variants", ["upc"], :name => "variant_upc_idx"

  create_table "spree_wished_products", :force => true do |t|
    t.integer  "variant_id"
    t.integer  "wishlist_id"
    t.text     "remark"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "spree_wishlists", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "access_hash"
    t.boolean  "is_private",  :default => true,  :null => false
    t.boolean  "is_default",  :default => false, :null => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  add_index "spree_wishlists", ["user_id"], :name => "wishlist_user_idx"

  create_table "spree_zone_members", :force => true do |t|
    t.integer  "zoneable_id"
    t.string   "zoneable_type"
    t.integer  "zone_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "spree_zones", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.boolean  "default_tax",        :default => false
    t.integer  "zone_members_count", :default => 0
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

  create_table "user_devices", :force => true do |t|
    t.integer  "user_id"
    t.integer  "device_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "user_devices", ["device_id"], :name => "user_device_device_idx"
  add_index "user_devices", ["user_id"], :name => "user_device_user_idx"

end
