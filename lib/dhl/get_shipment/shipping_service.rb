class Dhl::GetQuote::ShippingService
  include Dhl::GetQuote::Helper

  def initialize(options)
    @options = {}
    if options.class.to_s == 'Hash'
      build_from_hash(options)
    else
      build_from_xml(options.to_s)
    end
  end

  def code
    @global_product_code || @local_product_code
  end

  def name
    @product_short_name || @local_product_name
  end

  def total_amount
  end

protected

  def build_from_xml(xml_string)
    @parsed_xml = MultiXml.parse(xml_string)

    @parsed_xml['QtdShp'].each do |k,v|
      @options[k] = v
      instance_variable_set("@#{underscore(k)}".to_sym, v)
      self.class.class_eval { attr_reader underscore(k).to_sym }
    end
  end

  def build_from_hash(options)
    options.each do |k,v|
      k = underscore(k) if k =~ /[A-Z]/
      @options[k] = v
      instance_variable_set("@#{k}".to_sym, v)
      self.class.class_eval { attr_reader k.to_sym }
    end
  end

end