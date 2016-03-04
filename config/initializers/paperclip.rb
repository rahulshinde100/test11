Paperclip.interpolates(:s3_eu_url) do |attachment, style|
  "#{attachment.s3_protocol}://#{Spree::Config[:s3_host_alias]}/#{attachment.bucket_name}/#{attachment.path(style).gsub(%r{^/}, "")}"
end
Paperclip::Attachment.default_options[:use_timestamp] = false
Paperclip::Attachment.default_options[:s3_protocol] = "https"