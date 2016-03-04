object false

@response.keys.each do |key|
  node(key){ @response[key] }
end