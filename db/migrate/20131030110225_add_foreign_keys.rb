class AddForeignKeys < ActiveRecord::Migration
  def up
	  execute "ALTER TABLE spree_variants
	      ADD CONSTRAINT fk_variants_products
	      FOREIGN KEY (product_id)
	      REFERENCES spree_products(id)"
	  
	  execute "ALTER TABLE spree_prices
	      ADD CONSTRAINT fk_prices_variants
	      FOREIGN KEY (variant_id)
	      REFERENCES spree_variants(id)"
	    
	   execute "ALTER TABLE spree_products_taxons
	      ADD CONSTRAINT fk_products_taxons
	      FOREIGN KEY (product_id)
	      REFERENCES spree_products(id)"
		execute "ALTER TABLE spree_products_taxons
	      ADD CONSTRAINT fk_taxons_products
	      FOREIGN KEY (taxon_id)
	      REFERENCES spree_taxons(id)"
	  
  end

  def down
  	execute "ALTER TABLE spree_variants
        DROP FOREIGN KEY fk_variants_products"
      
     execute "ALTER TABLE spree_prices
        DROP FOREIGN KEY fk_prices_variants"
      
     execute "ALTER TABLE spree_products_taxons
        DROP FOREIGN KEY fk_products_taxons"
     execute "ALTER TABLE spree_products_taxons   
        DROP FOREIGN KEY fk_taxons_products"
    
  end
end
