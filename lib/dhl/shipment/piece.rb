class Dhl::Shipment::Piece
  attr_accessor :piece_id

  def initialize(options = {})
    [:weight, :dim_weight ].each do |i|
      options[i] = options[i].to_f if !!options[i]
    end
    
    [:width, :height, :depth ].each do |i|
      options[i] = options[i].to_i if !!options[i]
    end


    if options[:weight] && options[:weight] > 0
      @weight = options[:weight]
    else
      raise Dhl::Shipment::OptionsError, required_option_error_message(:weight)
    end

    if options[:width] || options[:height] || options[:depth]
      [ :width, :height, :depth].each do |req|
        if options[req].to_f > 1
          instance_variable_set("@#{req}", options[req].to_i)
        else
          raise Dhl::Shipment::OptionsError, required_option_error_message(req)
        end
      end
    end

    
    @dim_weight = options[:dim_weight] if options[:dim_weight]
    @package_type = options[:package_type] if options[:package_type]
    @piece_contents = options[:piece_contents] if options[:piece_contents]
    @piece_reference = options[:piece_reference] if options[:piece_reference]
    
    @piece_id = options[:piece_id] || 1

  end

  def to_h
    h = {}
    [ :width, :height, :depth, :weight, :dim_weight, :package_type, :piece_contents, :piece_reference].each do |req|
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
    xml_str << "  <PackageType>#{@package_type}</PackageType>\n" if @package_type
    xml_str << "  <Weight>#{@weight}</Weight>\n" if @weight
    xml_str << "  <DimWeight>#{@weight}</DimWeight>\n" if @dim_weight
    xml_str << "  <Width>#{@width}</Width>\n" if @width
    xml_str << "  <Height>#{@height}</Height>\n" if @height
    xml_str << "  <Depth>#{@depth}</Depth>\n" if @depth
    xml_str << "  <PieceContents>#{@piece_contents}</PieceContents>\n" if @piece_contents
    xml_str << "  <PieceReference>#{@piece_reference}</PieceReference>\n" if @piece_reference
    xml_str += "</Piece>\n"
    xml_str
  end

private

  def required_option_error_message(field)
    ":#{field} is a required for Dhl::Shipment::Piece. Must be nonzero integer or float."
  end
end