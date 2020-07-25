require "json"

module SharedModules
  module Serializer
    include ERB::Util

    def escape_recursive input
      if input.is_a? String
        CGI.unescapeHTML input
        # FIXME: The second code is correct. But since ember escapes, it was causing issues
        # html_escape_once input
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
