# Be sure to restart your server when you modify this file.

SwitchFabric::Application.config.session_store :cookie_store, key: '_ship.li_session' #, domain: :all  #commented as we are not using subdomain

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# ShipLi::Application.config.session_store :active_record_store
