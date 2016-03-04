class AddIndexedToPromotionRules < ActiveRecord::Migration
  def change
    add_index :spree_promotion_rules_sellers, [:seller_id],
              :name => 'index_seller_promotion_rules_on_seller_id'
    add_index :spree_promotion_rules_sellers, [:promotion_rule_id],
              :name => 'index_seller_promotion_rules_on_promotion_rule_id'
  end
end
