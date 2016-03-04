class CreateSpreePromotionRuleMarketPlace < ActiveRecord::Migration
  def change
    create_table :spree_promotion_rules_market_places , id: false do |t|
      t.references :market_place
      t.references :promotion_rule
    end
    add_index :spree_promotion_rules_market_places, [:market_place_id],
              :name => 'index_market_places_promotion_rules_on_market_place_id'
    add_index :spree_promotion_rules_market_places, [:promotion_rule_id],
              :name => 'index_market_places_promotion_rules_on_promotion_rule_id'
  end

end
