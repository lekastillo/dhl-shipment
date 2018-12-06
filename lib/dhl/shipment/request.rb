require 'rubygems'
require 'httparty'
require 'erb'
require 'set'

class Dhl::Shipment::Request
  attr_reader :site_id, :password, :from_country_code, :from_postal_code, :to_country_code, :to_postal_code, :duty, :requested_pickup_time, :place, :consignee, :shipper, :shippet_detail
  attr_accessor :pieces, :language, :shipper_dhl_account, :shipping_payment_type, :billing_dhl_account, :reference_id

  URLS = {
    :production => 'https://xmlpi-ea.dhl.com/XMLShippingServlet',
    :test       => 'https://xmlpitest-ea.dhl.com/XMLShippingServlet'
  }

  def initialize(options = {})
    @test_mode = !!options[:test_mode] || Dhl::Shipment.test_mode?

    @site_id = options[:site_id] || Dhl::Shipment.site_id
    @password = options[:password] || Dhl::Shipment.password

    [ :site_id, :password ].each do |req|
      unless instance_variable_get("@#{req}").to_s.size > 0
        raise Dhl::Shipment::OptionsError, ":#{req} is a required option"
      end
    end

    @requested_pickup_time = false
    @duty = false
    @place = false
    @language = 'en'

    @pieces = []
  end

  def test_mode?
    !!@test_mode
  end

  def test_mode!
    @test_mode = true
  end

  def production_mode!
    @test_mode = false
  end

  def requested_pickup_time!
    @requested_pickup_time = true
  end
  
  def not_requested_pickup_time!
    @requested_pickup_time = false
  end

  def requested_pickup_time?
    !!@requested_pickup_time
  end

  def set_place(resident_or_business="C", company_name, address_line1, address_line2, address_line3, postal_code, country_code, city)
    @place = {
      :resident_or_business => resident_or_business.slice(0,1).upcase,
      :company_name => company_name,
      :address_line1 => address_line1,
      :address_line2 => address_line2, 
      :address_line3 => address_line3,
      :postal_code => postal_code,
      :country_code => country_code.slice(0,3).upcase,
      :city => city
    }
  end
  
  def set_consignee(company_name, suit_department_name, address_line1, address_line2, address_line3, city, suburb, postal_code, division, country_code, country_name, person_name, phone_number, phone_extension, fax_number, email, mobile_phone_number)
    validate_country_code!(country_code)
    @consignee = {
      :company_name => company_name,
      :suit_department_name => suit_department_name,
      :address_line1 => address_line1,
      :address_line2 => address_line2,
      :address_line3 => address_line3,
      :city => city,
      :suburb => suburb,
      :postal_code => postal_code,
      :division => division,
      :country_code => country_code,
      :country_name => country_name,
      :person_name => person_name,
      :phone_number => phone_number,
      :phone_extension => phone_extension,
      :fax_number => fax_number,
      :email => email,
      :mobile_phone_number => mobile_phone_number,
    }
  end
  alias_method :set_consignee!, :set_consignee

  
  def set_shipper(shipper_id, shipper_account, company_name, suit_department_name, address_line1, address_line2, address_line3, city, suburb, postal_code, division, country_code, country_name, person_name, phone_number, phone_extension, fax_number, email, mobile_phone_number)
    validate_country_code!(country_code)
    @shipper = {
      :shipper_id => shipper_id,
      :shipper_account => shipper_account,
      :company_name => company_name,
      :suit_department_name => suit_department_name,
      :address_line1 => address_line1,
      :address_line2 => address_line2,
      :address_line3 => address_line3,
      :city => city,
      :suburb => suburb,
      :postal_code => postal_code,
      :division => division,
      :country_code => country_code,
      :country_name => country_name,
      :person_name => person_name,
      :phone_number => phone_number,
      :phone_extension => phone_extension,
      :fax_number => fax_number,
      :email => email,
      :mobile_phone_number => mobile_phone_number,
    }
  end
  alias_method :set_shipper!, :set_shipper


  def set_shipment_details(weight, weight_unit, global_product_code, date, content, dimension_unit, package_type, is_dutiable, currency_code, cust_data)
    @shipment_detail = {
      :weight => weight,
      :weight_unit => weight_unit,
      :global_product_code => global_product_code,
      :date => date,
      :content => content,
      :dimension_unit => dimension_unit,
      :package_type => package_type,
      :is_dutiable => is_dutiable,
      :currency_code => currency_code.slice(0,3).upcase,
      :cust_data => cust_data
    }
  end
  alias_method :set_shipment_details!, :set_shipment_details


  def shipment_details?
    !!@shipment_detail
  end

  def dutiable?
    !!@duty
  end

  def dutiable(value, currency_code="USD")
    @duty = {
      :declared_value => value.to_f,
      :declared_currency => currency_code.slice(0,3).upcase
    }
  end
  alias_method :dutiable!, :dutiable

  def not_dutiable!
    @duty = false
  end

  # def payment_account_number(pac = nil)
  #   if pac.to_s.size > 0
  #     @payment_account_number = pac
  #   else
  #     @payment_account_number
  #   end
  # end

  # def payment_country_code(country_code)
  #   @payment_country_code = country_code
  # end
  

  def dimensions_unit
    @dimensions_unit ||= Dhl::Shipment.dimensions_unit
  end

  def weight_unit
    @weight_unit ||= Dhl::Shipment.weight_unit
  end

  def metric_measurements!
    @weight_unit = Dhl::Shipment::WEIGHT_UNIT_CODES[:kilograms]
    @dimensions_unit = Dhl::Shipment::DIMENSIONS_UNIT_CODES[:centimeters]
  end

  def us_measurements!
    @weight_unit = Dhl::Shipment::WEIGHT_UNIT_CODES[:pounds]
    @dimensions_unit = Dhl::Shipment::DIMENSIONS_UNIT_CODES[:inches]
  end

  def centimeters!
    deprication_notice(:centimeters!, :metric)
    metric_measurements!
  end
  alias :centimetres! :centimeters!

  def inches!
    deprication_notice(:inches!, :us)
    us_measurements!
  end

  def metric_measurements?
    centimeters? && kilograms?
  end

  def us_measurements?
    pounds? && inches?
  end

  def centimeters?
    dimensions_unit == Dhl::Shipment::DIMENSIONS_UNIT_CODES[:centimeters]
  end
  alias :centimetres? :centimeters?

  def inches?
    dimensions_unit == Dhl::Shipment::DIMENSIONS_UNIT_CODES[:inches]
  end

  def kilograms!
    deprication_notice(:kilograms!, :metric)
    metric_measurements!
  end
  alias :kilogrammes! :kilograms!

  def pounds!
    deprication_notice(:pounds!, :us)
    us_measurements!
  end

  def pounds?
    weight_unit == Dhl::Shipment::WEIGHT_UNIT_CODES[:pounds]
  end

  def kilograms?
    weight_unit == Dhl::Shipment::WEIGHT_UNIT_CODES[:kilograms]
  end
  alias :kilogrammes? :kilograms?

  def to_xml
    validate!
    @to_xml = ERB.new(File.new(xml_template_path).read, nil,'%<>-').result(binding)
  end

  # ready times are only 8a-5p(17h)
  def ready_time(time=Time.now)
    if time.hour >= 17 || time.hour < 8
      time.strftime("PT08H00M")
    else
      time.strftime("PT%HH%MM")
    end
  end

  # ready dates are only mon-fri
  def ready_date(t=Time.now)
    date = Date.parse(t.to_s)
    if (date.cwday >= 6) || (date.cwday >= 5 && t.hour >= 17)
      date.send(:next_day, 8-date.cwday)
    else
      date
    end.strftime("%Y-%m-%d")
  end

  def post
    response = HTTParty.post(servlet_url,
      :body => to_xml,
      :headers => { 'Content-Type' => 'application/xml' }
    ).response

    return Dhl::Shipment::Response.new(response.body)
  rescue Exception => e
    request_xml = if @to_xml.to_s.size>0
      @to_xml
    else
      '<not generated at time of error>'
    end

    response_body = if (response && response.body && response.body.to_s.size > 0)
      response.body
    else
      '<not received at time of error>'
    end

    log_level = if e.respond_to?(:log_level)
      e.log_level
    else
      :critical
    end

    log_request_and_response_xml(log_level, e, request_xml, response_body )
    raise e
  end


protected

  def servlet_url
    test_mode? ? URLS[:test] : URLS[:production]
  end

  def validate!
    raise Dhl::Shipment::FromNotSetError, "#from() is not set" unless (!!@consignee and !!@shipment_details?)
    raise Dhl::Shipment::ToNotSetError, "#to() is not set" unless (!!@shipper and !!@shipment_details?)
    # validate_pieces!
  end

  def validate_pieces!
    pieces.each do |piece|
      klass_name = "Dhl::Shipment::Piece"
      if piece.class.to_s != klass_name
        raise Dhl::Shipment::PieceError, "entry in #pieces is not a #{klass_name} object!"
      end
    end
  end

  def validate_country_code!(country_code)
    unless country_code =~ /^[A-Z]{2}$/
      raise Dhl::Shipment::CountryCodeError, 'country code must be upper-case, two letters (A-Z)'
    end
  end

  def xml_template_path
    spec = Gem::Specification.find_by_name("dhl-shipment")
    gem_root = spec.gem_dir
    gem_root + "/tpl/request.xml.erb"
  end

private

  def deprication_notice(meth, m)
    messages = {
      :metric => "Method replaced by Dhl::Shipment::Request#metic_measurements!(). I am now setting your measurements to metric",
      :us     => "Method replaced by Dhl::Shipment::Request#us_measurements!(). I am now setting your measurements to US customary",
    }
    puts "!!!! Method \"##{meth}()\" is depricated. #{messages[m.to_sym]}."
  end

  def log_request_and_response_xml(level, exception, request_xml, response_xml)
    log_exception(exception, level)
    log_request_xml(request_xml, level)
    log_response_xml(response_xml, level)
  end

  def log_exception(exception, level)
    log("Exception: #{exception}", level)
  end

  def log_request_xml(xml, level)
    log("Request XML: #{xml}", level)
  end

  def log_response_xml(xml, level)
    log("Response XML: #{xml}", level)
  end

  def log(msg, level)
    Dhl::Shipment.log(msg, level)
  end

end
