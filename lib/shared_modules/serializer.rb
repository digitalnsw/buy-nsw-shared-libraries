require "json"

module SharedModules
  module Serializer
    include ERB::Util

    BCREG = /[^A-Za-z0-9 .,'`":;?~!@#$%^&*()\-_+=<>\{\}\[\]\|\/\\\s]/

    def sanitize s
      s.gsub(Serializer::BCREG, '?')
    end

    def full_sanitize s
      unescape(ActionView::Base.full_sanitizer.sanitize(unescape(s), tags: []))
    end

    def escape s
      html_escape_once s
    end

    def unescape s
      CGI.unescapeHTML s
    end

    def sanitize_recursive input
      if input.is_a? String
        sanitize(input)
      elsif input.is_a? Array
        input.map{|e| sanitize_recursive(e)}
      elsif input.is_a? Hash
        input.map{|k,v| [sanitize_recursive(k), sanitize_recursive(v)]}.to_h
      else
        input
      end
    end

    def full_sanitize_recursive input
      if input.is_a? String
        full_sanitize(input)
      elsif input.is_a? Array
        input.map{|e| full_sanitize_recursive(e)}
      elsif input.is_a? Hash
        input.map{|k,v| [full_sanitize_recursive(k), full_sanitize_recursive(v)]}.to_h
      else
        input
      end
    end

    def unescape_recursive input
      if input.is_a? String
        unescape input
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
        escape input
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
