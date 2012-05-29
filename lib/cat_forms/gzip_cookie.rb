# encoding: UTF-8
require 'zlib'
require 'active_support/hash_with_indifferent_access'

# Saves form as cookie as json+gzip
module CatForms::GzipCookie
  def self.load options={}
    request     = options[:request]
    cookie_name = options[:cookie_name].to_s
    result = ActiveSupport::HashWithIndifferentAccess.new
    return result if request.blank?
    cookie = request.cookies[cookie_name]
    return result if cookie.nil? or cookie.empty?
    begin
      result.merge!(ActiveSupport::JSON.decode(Zlib::Inflate.inflate(cookie)).stringify_keys)
      return result
    rescue Zlib::DataError
      return result
    end
  end

  def self.save options = {}
    attributes  = options[:attributes]
    response    = options[:response]
    cookie_name = options[:cookie_name]
    request     = options[:request]

    cookie_json = ActiveSupport::JSON.encode(attributes)
    cookie_json = Zlib::Deflate.deflate(cookie_json, Zlib::BEST_COMPRESSION)
    cookie_hash = { :value    => cookie_json,
                    :httponly => true,
                    :secure   => true,
                    :domain   => request.host,
                    :path     => '/' }
    response.set_cookie(cookie_name, cookie_hash)
  end
end

