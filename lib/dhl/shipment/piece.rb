class Dhl::Shipment::Piece
  attr_accessor :piece_id

  def initialize(options = {})
    [ :width, :height, :depth, :weight, :package_type, :dim_weight ].each do |i|
      options[i] = options[i].to_f if !!options[i]
    end

    if options[:weight] && options[:weight] > 0
      @weight = options[:weight]
    else
      raise Dhl::Shipment::OptionsError, required_option_error_message(:weight)
    end

    if options[:width] || options[:height] || options[:depth] || options[:dim_weight] 
      [ :width, :height, :depth, :dim_weight ].each do |req|
        if options[req].to_f > 0.0
          instance_variable_set("@#{req}", options[req].to_f)
        else
          raise Dhl::Shipment::OptionsError, required_option_error_message(req)
        end
      end
    end

    @piece_id = options[:piece_id] || 1

  end

  def to_h
    h = {}
    [ :width, :height, :depth, :weight, :dim_weight, :package_type ].each do |req|
      if x = instance_variable_get("@#{req}")
        h[req.to_s.capitalize] = x
      end
    end
    h
  end

  def to_xml
    xml_str = <<eos
<Piece>
  <PieceID>#{@piece_id}</PieceID>
eos

    xml_str << "  <Height>#{@height}</Height>\n" if @height
    xml_str << "  <Depth>#{@depth}</Depth>\n" if @depth
    xml_str << "  <Width>#{@width}</Width>\n" if @width
    xml_str << "  <Weight>#{@weight}</Weight>\n" if @weight
    xml_str << "  <DimWeight>#{@dim_weight}</DimWeight>\n" if @dim_weight
    xml_str << "  <PackageType>#{@package_type}</PackageType>\n" if @package_type

    xml_str += "</Piece>\n"
    xml_str
  end

private

  def required_option_error_message(field)
    ":#{field} is a required for Dhl::Shipment::Piece. Must be nonzero integer or float."
  end
end


<PieceID>1</PieceID>
				<PackageType>EE</PackageType>
				<Weight>2</Weight>
				<DimWeight>1.0</DimWeight>
				<Width>2</Width>
				<Height>2</Height>
				<Depth>2</Depth>