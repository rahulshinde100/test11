class CreateSpreeTaxonsMarketPlaces < ActiveRecord::Migration
  def self.up
    create_table :spree_taxons_market_places do |t|
      t.references :taxon
      t.references :market_place
      t.timestamps
    end
    add_index :spree_taxons_market_places, :taxon_id
    add_index :spree_taxons_market_places, :market_place_id
  end

  def self.down
    drop_table :spree_taxons_market_places
  end
end
