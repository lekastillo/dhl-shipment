require 'rubygems'
require 'httparty'
require 'erb'
require 'set'

class Dhl::Shipment::Request
  attr_reader :site_id, :password, :duty, :requested_pickup_time, :place, :consignee, :shipper, :shippet_detail, :billing, :notification
  attr_accessor :pieces, :language, :reference_id, :shipment_time, :shipment_reference, :request_archive_doc

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
    @language = 'es'
    @request_archive_doc = 'Y'

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

  def set_place(place_params = {})
    @test_mode = !!place_params[:test_mode] || Dhl::Shipment.test_mode?

    @place = {
      :resident_or_business => place_params[:resident_or_business].slice(0,1).upcase,
      :company_name => place_params[:company_name],
      :address_line1 => place_params[:address_line1],
      :address_line2 => place_params[:address_line2], 
      :address_line3 => place_params[:address_line3],
      :postal_code => place_params[:postal_code],
      :country_code => place_params[:country_code].slice(0,3).upcase,
      :city => place_params[:city]
    }
  end
  
  # def set_consignee(company_name, suit_department_name, address_line1, address_line2, address_line3, city, suburb, postal_code, division, country_code, country_name, person_name, phone_number, phone_extension, fax_number, email, mobile_phone_number)
  def set_consignee(consignee_params = {})
    validate_country_code!(consignee_params[:country_code])
    @consignee = {
      :company_name => consignee_params[:company_name],
      :suit_department_name => consignee_params[:suit_department_name],
      :address_line1 => consignee_params[:address_line1],
      :address_line2 => consignee_params[:address_line2],
      :address_line3 => consignee_params[:address_line3],
      :city => consignee_params[:city],
      :suburb => consignee_params[:suburb],
      :postal_code => consignee_params[:postal_code],
      :division => consignee_params[:division],
      :country_code => consignee_params[:country_code],
      :country_name => consignee_params[:country_name],
      :person_name => consignee_params[:person_name],
      :phone_number => consignee_params[:phone_number],
      :phone_extension => consignee_params[:phone_extension],
      :fax_number => consignee_params[:fax_number],
      :email => consignee_params[:email],
      :mobile_phone_number => consignee_params[:mobile_phone_number],
    }
  end
  alias_method :set_consignee!, :set_consignee

  
  # def set_shipper(shipper_id, shipper_account, company_name, suit_department_name, address_line1, address_line2, address_line3, city, suburb, postal_code, division, country_code, country_name, person_name, phone_number, phone_extension, fax_number, email, mobile_phone_number)
  def set_shipper(shipper_params = {})
    validate_country_code!(shipper_params[:country_code])
    @shipper = {
      :shipper_id => shipper_params[:shipper_id],
      :shipper_account => shipper_params[:shipper_account],
      :company_name => shipper_params[:company_name],
      :suit_department_name => shipper_params[:suit_department_name],
      :address_line1 => shipper_params[:address_line1],
      :address_line2 => shipper_params[:address_line2],
      :address_line3 => shipper_params[:address_line3],
      :city => shipper_params[:city],
      :suburb => shipper_params[:suburb],
      :postal_code => shipper_params[:postal_code],
      :division => shipper_params[:division],
      :country_code => shipper_params[:country_code],
      :country_name => shipper_params[:country_name],
      :person_name => shipper_params[:person_name],
      :phone_number => shipper_params[:phone_number],
      :phone_extension => shipper_params[:phone_extension],
      :fax_number => shipper_params[:fax_number],
      :email => shipper_params[:email],
      :mobile_phone_number => shipper_params[:mobile_phone_number],
    }
  end
  alias_method :set_shipper!, :set_shipper


  # def set_shipment_details(weight, weight_unit, global_product_code, date, content, dimension_unit, package_type, is_dutiable, currency_code, cust_data)
  def set_shipment_details(shipment_detail_params = {})
    @shipment_detail = {
      :weight => shipment_detail_params[:weight],
      :weight_unit => shipment_detail_params[:weight_unit],
      :global_product_code => shipment_detail_params[:global_product_code],
      :date => shipment_detail_params[:date],
      :content => shipment_detail_params[:content],
      :dimension_unit => shipment_detail_params[:dimension_unit],
      :package_type => shipment_detail_params[:package_type],
      :is_dutiable => shipment_detail_params[:is_dutiable],
      :currency_code => shipment_detail_params[:currency_code].slice(0,3).upcase,
      :cust_data => shipment_detail_params[:cust_data]
    }
  end
  alias_method :set_shipment_details!, :set_shipment_details


  def set_billing(billing_params = {})
    @billing = {
      :shipper_account_number => billing_params[:shipper_account_number],
      :shipping_payment_type => billing_params[:shipping_payment_type],
      :billing_account_number => billing_params[:billing_account_number],
      :duty_payment_type => billing_params[:duty_payment_type],
      :duty_account_number => billing_params[:duty_account_number]
    }
  end
  alias_method :set_billing!, :set_billing


  def shipment_details?
    !!@shipment_detail
  end

  def dutiable?
    !!@duty
  end

  # def dutiable(value, currency_code="USD", terms_of_trade)
  def dutiable(dutiable_params = {})
    @duty = {
      :declared_value => dutiable_params[:value].to_f,
      :declared_currency => dutiable_params[:currency_code].slice(0,3).upcase,
      :terms_of_trade=> dutiable_params[:terms_of_trade]
    }
  end
  alias_method :dutiable!, :dutiable

  def not_dutiable!
    @duty = false
  end

  def notificable?
    !!@notification
  end

  # def dutiable(value, currency_code="USD", terms_of_trade)
  def notificable(notificable_params = {})
    @notification = {
      :emails => notificable_params[:emails].join(';'),
      :message => notificable_params[:message]
    }
  end
  alias_method :notificable!, :notificable

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

  # # ready times are only 8a-5p(17h)
  # def ready_time(time=Time.now)
  #   if time.hour >= 17 || time.hour < 8
  #     time.strftime("PT08H00M")
  #   else
  #     time.strftime("PT%HH%MM")
  #   end
  # end

  # # ready dates are only mon-fri
  # def ready_date(t=Time.now)
  #   date = Date.parse(t.to_s)
  #   if (date.cwday >= 6) || (date.cwday >= 5 && t.hour >= 17)
  #     date.send(:next_day, 8-date.cwday)
  #   else
  #     date
  #   end.strftime("%Y-%m-%d")
  # end

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
    raise Dhl::Shipment::FromNotSetError, "#from() is not set" unless !(@consignee and @shipment_details)
    raise Dhl::Shipment::ToNotSetError, "#to() is not set" unless !(@shipper and @shipment_details)
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
