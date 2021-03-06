require 'json'
require 'openssl'
require 'base64'

module SharedModules
  module Encrypt
    def encrypt_and_sign data
      private_key = OpenSSL::PKey::RSA.new File.read(Rails.root.join('sso_rsa.pem').to_s)
      jwt_token = JWT.encode(data, private_key, 'RS512', { typ: 'JWT'})
      aes(jwt_token)
    end

    def encrypt data
      bin2hex(blowfish(data.to_json))
    end

    def bin2hex data
      data.unpack('C*').map{ |b| "%02X" % b }.join('')
    end

    def blowfish data
      cipher = OpenSSL::Cipher.new('bf-ecb').encrypt
      cipher.key = Base64.decode64(ENV['ETENDERING_ENCRYPTION_KEY'])
      cipher.update(data) << cipher.final
    end

    def aes data
      cipher = OpenSSL::Cipher::AES128.new(:CBC).encrypt
      cipher.key = Base64.decode64(ENV['ETENDERING_ENCRYPTION_KEY'])
      iv = cipher.random_iv
      enc = cipher.update(data) << cipher.final
      bin2hex(iv) + bin2hex(enc)
    end
  end
end
