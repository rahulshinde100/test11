require "base64"
module TokenGenerator

  private
  def encode(obj)
    Base64.encode64("#{obj}@#{TOKENPARAM}")
  end

  def decode(enc)
    Base64.decode64(enc)
  end
end