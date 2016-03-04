class CreatePromotionVariant < ActiveRecord::Migration
  def change
    create_table :spree_promotion_rules_variants , id: false do |t|
      t.references :variant
      t.references :promotion_rule
    end
    add_index :spree_promotion_rules_variants, [:variant_id],
              :name => 'index_market_places_promotion_rules_on_variant_id'
    add_index :spree_promotion_rules_variants, [:promotion_rule_id],
              :name => 'index_market_places_promotion_rules_on_promotion_rule_id'
  end
end
