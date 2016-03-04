object false
child(@categories => :categories) do
   attributes *taxonomy_attributes
   node(:product_count) { |m| m.product_count(@seller.id)}
    child :children => :taxons do
      attributes *taxon_attributes
      node(:product_available) { |p| p.product_available(@seller.id)}
      node(:product_count) { |c| c.product_count(@seller.id)}
    end
  end
