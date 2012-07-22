# encoding: UTF-8
require 'money'
require 'date'
require 'yajl'
require 'open-uri'

# https://openexchangerates.org/documentation

class Money
  module Bank
    module OpenExchangeRatesLoader
      def self.app_id
        @app_id
      end

      def self.app_id=(id)
        @app_id = id
      end

      def self.add_app_id(url)
        url << "?app_id=#{app_id}" if app_id
        url
      end

      def self.latest_url
        add_app_id("http://openexchangerates.org/api/latest.json")
      end

      def self.historical_url(date)
        add_app_id("http://openexchangerates.org/api/historical/#{date}.json")
      end

      def rates_source(date)
        if date == Date.today
          OpenExchangeRatesLoader.latest_url
        else
          OpenExchangeRatesLoader.historical_url(date)
        end
      end

      # Tries to load data from OpenExchangeRates for the given rate.
      # Won't do anything if there's no data available for that date
      # in OpenExchangeRates (short) history.
      def load_data(date)
        doc = Yajl::Parser.parse(open(rates_source(date)).read)

        base_currency = doc['base'] || 'USD'

        doc['rates'].each do |currency, rate|
          # Don't use set_rate here, since this method can only be called from
          # get_rate, which already aquired a mutex.
          internal_set_rate(date, base_currency, currency, rate)

        end

      rescue OpenURI::HTTPError => e
        puts "couldn't get rate from #{rates_source}"
      end
    end
  end
end
