module SharedModules
  class Abr
    def self.lookup abn
      if ABN.valid? abn
        abn = ABN.new(abn).to_s.gsub(' ', '')
        key = 'abr_abn_' + abn
        result = redis.get(key)
        return nil if result == 'NOT_FOUND'
        return JSON.parse(result).symbolize_keys if result
        client = Abn::Client.new(ENV['ABR_GUID'])
        result = client.search(abn)
        if result[:status] || result[:abn]
          redis.set key, result.to_json
          redis.expire key, 1.day.to_i
          return result
        else
          redis.set key, "NOT_FOUND"
          redis.expire key, 1.day.to_i
          return nil
        end
      end
    end

    WSDL_URL = ENV['ABR_SEARCH_ENDPOINT'].to_s + '?WSDL'

    def self.search_call abn
      client = Savon.client do |globals|
        globals.wsdl WSDL_URL
        globals.open_timeout 15
        globals.read_timeout 15
        globals.ssl_version :TLSv1_2
        globals.soap_version 2
        globals.namespace_identifier :abr
        globals.env_namespace :soap
        globals.endpoint ENV['ABR_SEARCH_ENDPOINT']
        globals.pretty_print_xml true
        globals.basic_auth [ENV['ABR_SEARCH_USERNAME'],ENV['ABR_SEARCH_PASSWORD']]
      end

      client.call(:identifier_search, message: {
        search_identifier: {
          identifier_type: 'ABN',
          identifier_value: abn,
          date: DateTime.now.to_s,
          history: 'N'
        }
      }).body[:identifier_search_response][:abr_payload_search_identifier]
    rescue => e
      puts e.message
      Airbrake.notify_sync(e.message, {
        abn: abn,
        trace: e.backtrace.select{|l|l.match?(/buy-nsw/)},
      })
      nil
    end

    def self.search abn
      if ABN.valid? abn
        abn = ABN.new(abn).to_s.gsub(' ', '')
        key = 'abr_search_' + abn
        result = redis.get(key)
        return nil if result == 'NOT_FOUND'
        return Marshal.load(result) if result
        result = search_call(abn)
        if result.present?
          redis.set key, Marshal.dump(result)
          redis.expire key, 1.day.to_i
          return result
        else
          redis.set key, "NOT_FOUND"
          redis.expire key, 1.day.to_i
          return nil
        end
      end
    end

    def self.active?
      ENV['ABR_GUID'].present?
    end

    private

    def self.redis
      Rails.cache.redis
    end
  end
end
