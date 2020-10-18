require "json"

module SharedModules
  module Serializer
    include ERB::Util

    BCREG = /[^A-Za-z0-9 .,'":;+~*\-_|()@#$%&\/\s]/

    def sanitize_recursive input
      if input.is_a? String
        input.gsub(Serializer::BCREG, '?')
      elsif input.is_a? Array
        input.map{|e| sanitize_recursive(e)}
      elsif input.is_a? Hash
        input.map{|k,v| [sanitize_recursive(k), sanitize_recursive(v)]}.to_h
      else
        input
      end
    end

    def unescape_recursive input
      if input.is_a? String
        CGI.unescapeHTML input
      elsif input.is_a? Array
        input.map{|e| unescape_recursive(e)}
      elsif input.is_a? Hash
        input.map{|k,v| [unescape_recursive(k), unescape_recursive(v)]}.to_h
      else
        input
      end
    end

    def escape_recursive input
      if input.is_a? String
        html_escape_once input
      elsif input.is_a? Array
        input.map{|e| escape_recursive(e)}
      elsif input.is_a? Hash
        input.map{|k,v| [escape_recursive(k), escape_recursive(v)]}.to_h
      else
        input
      end
    end
  end
end
