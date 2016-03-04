object false

@total_slots.keys.each do |key|
  node(key){ @total_slots[key] }
end 