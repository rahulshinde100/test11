class CreateSpreePromotionRuleTaxon < ActiveRecord::Migration
  def change
    create_table :spree_promotion_rules_taxons , id: false do |t|
      t.references :taxon
      t.references :promotion_rule
    end
    add_index :spree_promotion_rules_taxons, [:taxon_id],
              :name => 'index_market_places_promotion_rules_on_taxon_id'
    add_index :spree_promotion_rules_taxons, [:promotion_rule_id],
              :name => 'index_market_places_promotion_rules_on_promotion_rule_id'
  end
end
