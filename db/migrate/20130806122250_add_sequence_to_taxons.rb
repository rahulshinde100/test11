class AddSequenceToTaxons < ActiveRecord::Migration
  def change
  	 add_column :spree_taxons, :sequence, :integer ,:default => 1000
  end
end
