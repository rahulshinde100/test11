class AddColumnToSpreeTaxonsMarketPlaces < ActiveRecord::Migration
  def change
    add_column :spree_taxons_market_places, :name,   :string
    add_column :spree_taxons_market_places, :market_place_category_id,   :string
  end
end
