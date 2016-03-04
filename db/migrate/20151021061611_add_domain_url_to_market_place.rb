class AddDomainUrlToMarketPlace < ActiveRecord::Migration
  def change
    add_column :spree_market_places, :domain_url, :string
  end
end
