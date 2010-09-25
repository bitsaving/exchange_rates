require 'net/http'
require 'uri'
require 'nokogiri'

class ExchangeRates < ActiveRecord::Base
  serialize :fields

  class << self
    def get
      Record.new first
    end

    def update
      row = first || new
      updater = Updater.new
      row.date = updater.date
      row.fields = updater.fields
      row.save
    end
  end

  class Record
    def initialize(record)
      @record = record
    end

    def date
      @record.date
    end

    def value(key)
      if @record.fields[key] && @record.fields[key][:value]
        @record.fields[key][:value]
      else
        nil
      end
    end
  end

  class Updater
    URL = 'http://www.cbr.ru/scripts/XML_daily.asp'
    attr_reader :date, :fields

    def initialize
      @date = nil
      @fields = {}
      load_data
    end

    private

    def load_data
      url = URI.parse URL
      respond = Net::HTTP.get url
      doc = Nokogiri::XML(respond)
      parse_data(doc)
    end

    def parse_data(doc)
      @date = Date.parse doc.xpath("//ValCurs").attr("Date").to_s
      doc.xpath("//ValCurs/Valute").each do |valute|
        code = valute.xpath("./CharCode").text.to_sym
        @fields[code] = {}
        @fields[code][:value] = valute.xpath("./Value").text.gsub(',','.').to_f
        @fields[code][:name] = valute.xpath("./Name").text
        @fields[code][:nominal] = valute.xpath("./Nominal").text
      end
    end
  end
end
