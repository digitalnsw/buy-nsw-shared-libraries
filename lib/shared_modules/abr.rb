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

    private

    def self.redis
      Rails.cache.redis
    end
  end
end
