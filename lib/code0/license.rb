# frozen_string_literal: true

require "openssl"
require "base64"
require "date"
require "json"

require_relative "license/boundary"
require_relative "license/version"

module Code0
  # Logic relating to license. Delegates encryption to Encryptor
  class License
    class Error < StandardError; end
    class ValidationError < Error; end

    class << self
      def encryption_key=(key)
        raise Error, "No RSA key provided." if key && !key.is_a?(OpenSSL::PKey::RSA)

        @encryption_key = key
      end

      def load(data)
        raise ValidationError, "No data" if data.nil?

        data = Boundary.remove_boundary(data)

        decrypted_license = encryptor.decrypt(data)

        new(JSON.parse(decrypted_license, symbolize_names: true))
      rescue JSON::ParserError
        raise ValidationError, "License data is invalid JSON"
      end

      def export(license, license_name)
        license_data = JSON.dump(license.data)
        encrypted_license = encryptor.encrypt(license_data)
        Boundary.add_boundary(encrypted_license, license_name)
      end

      def encryptor
        Encryptor.new(@encryption_key)
      end
    end

    ATTRIBUTES = %i[
      start_date
      end_date
      licensee
      restrictions
      options
    ].freeze
    attr_reader(*ATTRIBUTES)

    def initialize(data)
      assign_attributes(data)
    end

    def valid?
      return false if !licensee || !licensee.is_a?(Hash) || licensee.empty?
      return false if !start_date || !start_date.is_a?(Date)
      return false if (!end_date || !end_date.is_a?(Date)) && !options[:allow_missing_end_date]

      true
    end

    def in_active_time?
      return false if start_date > Date.today
      return true if !end_date && options[:allow_missing_end_date]
      return false if !end_date && !options[:allow_missing_end_date]

      end_date >= Date.today
    end

    def restricted?(attribute)
      restrictions.key?(attribute)
    end

    def data
      ATTRIBUTES.to_h { |attr| [attr, send(attr)] }
    end

    private

    attr_writer(*ATTRIBUTES)

    def assign_attributes(data)
      %i[start_date end_date].each do |property|
        value = data[property]
        value = parse_date(data[property]) unless data[property].is_a?(Date)
        send("#{property}=", value)
      end

      send("licensee=", data[:licensee])
      send("restrictions=", data[:restrictions] || {})
      send("options=", data[:options] || {})
    end

    def parse_date(str)
      Date.parse(str)
    rescue StandardError
      nil
    end
  end
end

# this depends on constants defined in this class
require_relative "license/encryptor"
