require 'date'

require "dhl/shipment/version"
require "dhl/shipment/helper"
require "dhl/shipment/errors"
require "dhl/shipment/request"
require "dhl/shipment/response"
require "dhl/shipment/piece"
# require "dhl/shipment/market_service"
# require "dhl/shipment/shipping_service"

class Dhl
  class Shipment

    DIMENSIONS_UNIT_CODES = { :centimeters => "CM", :inches => "IN" }
    WEIGHT_UNIT_CODES = { :kilograms => "KG", :pounds => "LB" }
    LOG_LEVELS = [:debug, :verbose, :critical, :none]
    DEFAULT_LOG_LEVEL = :debug

    def self.configure(&block)
      yield self if block_given?
    end

    def self.test_mode!
      @@test_mode = true
    end

    def self.test_mode?
      !!@@test_mode
    end

    def self.production_mode!
      @@test_mode = false
    end

    def self.site_id(site_id=nil)
      if (s = site_id.to_s).size > 0
        @@site_id = s
      else
        @@site_id
      end
    end

    def self.password(password=nil)
      if (s = password.to_s).size > 0
        @@password = s
      else
        @@password
      end
    end

    def self.metric_measurements!
      @@weight_unit = WEIGHT_UNIT_CODES[:kilograms]
      @@dimensions_unit = DIMENSIONS_UNIT_CODES[:centimeters]
    end

    def self.us_measurements!
      @@weight_unit = WEIGHT_UNIT_CODES[:pounds]
      @@dimensions_unit = DIMENSIONS_UNIT_CODES[:inches]
    end

    def self.kilograms!
      deprication_notice(:kilograms!, :metric)
      metric_measurements!
    end
    def self.kilogrammes!; self.kilograms!; end

    def self.pounds!
      deprication_notice(:pounds!, :us)
      us_measurements!
    end

    def self.weight_unit
      @@weight_unit
    end

    def self.centimeters!
      deprication_notice(:centimeters!, :metric)
      metric_measurements!
    end
    def self.centimetres!; self.centimeters!; end

    def self.inches!
      deprication_notice(:inches!, :us)
      us_measurements!
    end

    def self.dimensions_unit
      @@dimensions_unit
    end

    def self.set_defaults
      @@site_id = nil
      @@password = nil
      @@weight_unit = WEIGHT_UNIT_CODES[:kilograms]
      @@dimensions_unit = DIMENSIONS_UNIT_CODES[:centimeters]
      @@test_mode = false
      
      @@logger = self.default_logger
      @@log_level = DEFAULT_LOG_LEVEL
      # @@dutiable = false
      # here i should initialize every class var to use in the process
    end

    def self.log(message, level = DEFAULT_LOG_LEVEL)
      validate_log_level!(level)
      return unless LOG_LEVELS.index(level.to_sym) >= LOG_LEVELS.index(log_level)
      get_logger.call(message, level)
    end

    def self.set_logger(logger_proc=nil, &block)
      @@logger = block || logger_proc || default_logger
    end

    def self.get_logger
      @@logger
    end

    def self.set_log_level(log_level)
      validate_log_level!(log_level)
      @@log_level = log_level
    end

    def self.log_level
      @@log_level
    end

    private

    def self.validate_log_level!(level)
      raise "Log level :#{level} is not valid" unless
        valid_log_level?(level)
    end

    def self.valid_log_level?(level)
      LOG_LEVELS.include?(level.to_sym)
    end

    def self.default_logger
      @default_logger ||= Proc.new do |m, ll|
        output = if (lines = m.split("\n")).size < 2
          m
        else
          "\n" + lines.map{|l| "\t#{l}"}.join("\n")
        end
        STDERR.puts "#{ll.to_s.upcase}: Dhl-get_quote gem: #{output}"
      end
    end

    def self.deprication_notice(meth, m)
      messages = {
        :metric => "Method replaced by Dhl::Shipment#metic_measurements!(). I am now setting your measurements to metric",
        :us     => "Method replaced by Dhl::Shipment#us_measurements!(). I am now setting your measurements to US customary",
      }
      puts "!!!! Method \"##{meth}()\" is depricated. #{messages[m.to_sym]}."
    end
  end
end

Dhl::Shipment.set_defaults