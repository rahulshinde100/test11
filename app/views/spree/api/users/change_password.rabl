object false

@alert.keys.each do |key|
  node(key){ @alert[key] }
end