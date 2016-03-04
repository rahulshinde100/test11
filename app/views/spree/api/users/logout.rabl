object false

@status.keys.each do |key|
  node(key){@status[key] }
end