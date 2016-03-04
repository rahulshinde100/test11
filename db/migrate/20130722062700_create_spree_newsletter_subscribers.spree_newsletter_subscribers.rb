# This migration comes from spree_newsletter_subscribers (originally 20120920162943)
class CreateSpreeNewsletterSubscribers < ActiveRecord::Migration
  def up
    create_table :spree_newsletter_subscribers do |t|
      t.string :name
      t.string :email
      t.timestamps
    end
  end

  def down
    drop_table :spree_newsletter_subscribers
  end
end
