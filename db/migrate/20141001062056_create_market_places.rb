class CreateMarketPlaces < ActiveRecord::Migration
  def change
    create_table :spree_market_places do |t|
      t.integer :id
      t.string :name
      t.string :code

      t.timestamps
    end
  end
end
