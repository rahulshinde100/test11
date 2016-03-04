class CreateSpreePromotionRulesSellers < ActiveRecord::Migration
  def change
    create_table :spree_promotion_rules_sellers do |t|
      t.references :seller
      t.references :promotion_rule
    end
  end
end
