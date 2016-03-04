# This migration comes from spree_newsletter_subscribers (originally 20130204103030)
class CreateSpreeNewsletterTemplates < ActiveRecord::Migration
  def change
    create_table :spree_newsletter_templates do |t|
      t.string :title 
      t.text  :template 
      t.boolean :is_active 
      t.date :for_date 

      t.timestamps
    end
  end
end
