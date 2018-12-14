[![Build Status](https://travis-ci.org/deseretbook/dhl-get_quote.png)](https://travis-ci.org/deseretbook/dhl-get_quote)
[![Code Climate](https://codeclimate.com/github/deseretbook/dhl-get_quote.png)](https://codeclimate.com/github/deseretbook/dhl-get_quote)

# Dhl::GetQuote

Get shipping quotes from DHL's XML-PI Service.

Use of the XML-PI Service requires you to have Site ID and Password from DHL. You can sign up here: https://myaccount.dhl.com/MyAccount/jsp/TermsAndConditionsIndex.htm

Many thanks to John Riff of DHL for his help during the development of this gem.

## Installation

Add this line to your application's Gemfile:

    gem 'dhl-get_quote'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dhl-get_quote

## Basic Usage

```ruby
  require 'dhl-get_quote'

  r = Dhl::GetQuote::Request.new(
    :site_id => "SiteIdHere",
    :password => "p4ssw0rd",
    :test_mode => true # changes the url being hit
  )

  r.metric_measurements!

  r.add_special_service("DD")

  r.to('CA', "T1H 0A1")
  r.from('US', 84010)

  r.pieces << Dhl::GetQuote::Piece.new(
    :height => 20.0,
    :weight => 20.0,
    :width => 20.0,
    :depth => 19.0
  )

  response = r.post
  if response.error?
    raise "There was an error: #{response.raw_xml}"
  else
    puts "Your cost to ship will be: #{response.total_amount} in #{response.currency_code}."
  end
```

---

### Dhl::GetQuote::Request

#### Making a new request

This is where the magic starts. It accepts a hash that, at minimum, requires :site\_id and :password. Optionally, :test\_mode may be passed in to tell the gem to use the XML-PI test URL. The default is to *not* use test mode and to hit the production URL.

```ruby
request = Dhl::GetQuote::Request.new(
  :site_id => "SiteIdHere",
  :password => "p4ssw0rd",
  :test_mode => false
)
```

*NOTE*: You can also set default beforehand in, for example, an initializer. For more information on this, please see the section "Initializers with Dhl::GetQuote"

#### Setting Payment Account Number

If you are using a special account for shipping payments, you can specify it as

```ruby
  request.payment_account_number('12345678')
```

To read the current payment account number (if set), use:

```ruby
  request.payment_accout_number
```

It will return the current number or nil if none has been set.

#### Package Source and Destination

To set the source and destination, use the #to() and #from() methods:

  #to(_country_code_, _postal_code_, city_name), #from(_country_code_, _postal_code_, city_name)

The country code must be the two-letter capitalized ISO country code. The postal code will be cast in to a string. City name is optional.

Example:

```ruby
  # without city
  request.from('US', 84111)
  request.to('CA', 'T1H 0A1')

  # with city
  request.from('US', 84111, "Bountiful")
  request.to('MX', "53950", 'Naucalpan de Juárez')
```

#### Measurement Units

DHL can accept weights and measures in both Metric and US Customary units.  Weights are given in either pounds or kilograms, dimensions in either inches or centimeters. This gem defaults to use metric measurements.

To set to US Customary, use:

```ruby
  request.us_measurements! # set dimensions to inches and weight to pounds
```

To set back to Metric, use

```ruby
  request.metric_measurements! # set dimensions to centimeters and weight to kilograms
```

To query what measurement system the object is currently using, use the following boolean calls:

```ruby
  request.us_measurements?

  request.metric_measurements?
```

You can also get the value directly:

```ruby
  request.dimensions_unit # will return either "CM" or "IN"
  request.weight_unit     # will return either "KG" or "LB"
```

#### Setting Duty

! Note, this a breaking change from 0.4.x

To set the duty on a shipment, use the dutiable() method. It accepts the numeric value and an optional currency code. If not specified, the currency code default to US Dollars (USD).

```ruby
  # set the dutiable value at $100 in US Dollars
  request.dutiable(100.00, 'USD')
```

To remove a previously set duty, use the not_dutiable!() method.

```ruby
  request.not_dutiable!
```

You can query the current state with #dutiable?:

```ruby
  request.dutiable? # returns true or false
```

The default is for the request is "not dutiable".

#### Shipment Services

Shipment services (speed, features, etc) can be added, listed and removed.

To add a special service, call #add_special_service as pass in DHL-standard code for the service:

```ruby
  request.add_special_service("D")
```

To list all services currently added to a request, use #special_services:

```ruby
  request.special_services
```

To remove a special service, use #remove_special_service and pass the code:

```ruby
  request.remove_special_service("D")
```

The interface will not allow the same special service code to be added twice, it will be silently ignored if you try.


#### Adding items to the request

To add items to the shipping quote request, generate a new Dhl::GetQuote::Piece instance and append it to #pieces:

```ruby
  # minimal
  request.pieces << Dhl::GetQuote::Piece.new( :weight => 20.0 )

  # more details
  request.pieces << Dhl::GetQuote::Piece.new(
    :weight => 20.0, :height => 20.0, :width => 20.0, :depth => 19.0
  )
```

Dhl::GetQuote::Piece requires *at least* :weight to be specified, and it must be a nonzero integer or float.  Optionally, you can provide :width, :depth and :height. The measurement options must all be added at once and cannot be added individually. They must be integers or floats.

#### Posting to DHL

Once the request is prepared, call #post() to post the request to the DHL XML-PI.  This will return a Dhl::GetQuote::Response object.

```ruby
  response = request.post
  response.class == Dhl::GetQuote::Response # true
```

---

### Dhl::GetQuote::Response

Once a post is sent to DHL, this gem will interpret the XML returned and create a Dhl::GetQuote::Response object.

#### Checking for errors

To check for errors in the response (both local and upstream), query the #error? and #error methods

```ruby
  response.error? # true
  response.error
  # => < Dhl::GetQuote::Upstream::ValidationFailureError: your site id is not correct blah blah >
```

#### Getting costs

The response object exposes the following values:

  * currency_code
  * currency_role_type_code
  * weight_charge
  * total_amount
  * total_tax_amount
  * weight_charge_tax

To find the total change:

```ruby
  puts "Your cost to ship will be: #{response.total_amount} in #{response.currency_code}."
  # Your cost to ship will be: 337.360 in USD.
```

DHL can return the cost in currency unit based on sender location or reciever location. It is unlikely this will be used much, but you can change the currency by calling #load_costs with the CurrencyRoleTypeCode:

```ruby
  response.load_costs('PULCL')
  puts "Your cost to ship will be: #{response.total_amount} in #{response.currency_code}."
  # Your cost to ship will be: 341.360 in CAD.
```

CurrencyRoleTypeCodes that can be used are:

  * BILLCU – Billing currency
  * PULCL – Country of pickup local currency
  * INVCU – Invoice currency
  * BASEC – Base currency

#### Accessing the raw response

If you need data from the response that is not exposed by this gem, you can access both the raw xml and parsed xml directly:

```ruby
  response.raw_xml    # raw xml string as returned by DHL
  response.parsed_xml # xml parsed in to a Hash for easy traversal
```

\#parsed\_xml() is not always available in the case of errors. #raw\_xml() is, except in cases of network transport errors.

#### Accessing offered services

In cases where you have either sent many special service code, or you are evaluating all available services (via the 'OSINFO' special service code), you can obtain a list of all the services with the #offered_services() and #all_services() methods. Both methods return an array of Dhl::GetQuote::MarketService objects.

The #offered_services() method returns only those services intended to be shown to the end user an optional services (XCH) they can apply. These would be services with either 'TransInd' or 'MrkSrvInd' set to 'Y'.

The #all_services() methods returns all associated services, including everything in #offered_services and also including possible fees (FEE) and surcharges (SCH).

If using 'OSINFO' to obtain all offered services, you pass the value of #code() in to Request#add_special_service() to apply this services to another request:

```ruby
  # assume we already did an 'OSINFO' request.
  new_request.add_special_service(response.offered_services.first.code)
```

---

### Dhl::GetQuote::MarketService

Instances of this object are returned from Response#offered_services() and Response#all_services().

#### Methods for parameters

All XML parameters in the response will be added as methods to this object.  They may vary but generally include:

* #local\_product\_code() - code for user-offered services (signature, tracking, overnight, etc)
* #local\_service_type() code for non-offered special services (fees, surcharges, etc)
* #local\_service\_type\_name() - Name for a non-offered service
* #local\_product\_name() - Name for a user-offered service
* #mrk\_srv\_ind() - Should this be offered to the user?
* #trans\_ind() - Should this be shown to every user regardless of shipping options?

#### Getting the code for a service

The #code() method will return the code for a given service. It will work on both non-offered and user-offered services, it queries both LocalProductCode and LocalServiceType.

```ruby
  market_service.code # "D"
```

This code can be passed in to Request#add_special_service()

#### Getting the name for a service

The #name() method will return the name for a given service. It will work on both non-offered and user-offered services, it queries both LocalProductName and LocalServiceTypeName.

```ruby
  market_service.name # "EXPRESS WORLDWIDE DOC"
```

---

### Setting a logger and log levels

By default the gem will only log output of fatal errors that occur when communicating with the DHL servers. If such an error is caught, the gem will log the exception name, the request XML (if generated) and the response xml (if received).

To change the log level:

```ruby
  Dhl::GetQuote::configure do |c|
    c.set_log_level :verbose
  end

  # or

  Dhl::GetQuote::set_log_level :verbose
```

Available log levels are:

  :none      Logs nothing
  :critical  Logs fatal exceptions (DEFAULT)
  :verbose   Log :critical, also logs internal validation errors
  :debug     Log everything

The default logger is STDERR. You can change this by passing a Proc object to set_logger(). For example, if you wanted to log to the Rails Logger instead:

```ruby
  # with a block
  Dhl::GetQuote::set_logger do |message, log_level|
    Rails.logger.info(message)
  end

  # as an argument
  logger = Proc.new { |message, log_level| Rails.logger.info(message) }
  Dhl::GetQuote::set_logger(logger)

  # you can also do this is the configure block:
  Dhl::GetQuote::configure do |c|
    c.set_logger(
      Proc.new { |message, log_level| Rails.logger.info(message) }
    )
    # or as a block here too
    c.set_logger do |message, log_level|
      Rails.logger.info(message)
    end
  end
```

Log level CAN NOT be set via "Dhl::GetQuote::new()" options.

---

### Initializers with Dhl::GetQuote

If you don't want to have to pass email, password, weight setting, etc, every time you build a new request object you can set these defaults beforehand. This works well in cases where you want to put setting in something like a Rails initializer.

To do this, call Dhl::GetQuote::configure and pass a block:

```ruby
  Dhl::GetQuote::configure do |c|

    c.side_id  "SomeSiteId"
    c.password "p4ssw0rd"

    c.production_mode! # or test_mode!

    c.metric_measurements!
    c.us_measurements!

    c.dutiable(1.00, 'USD')

  end
```

The above block sets defaults for use thereafter. You would then not have to pass site\_id or password in to Dhl::GetQuote::new():

```ruby
  Dhl::GetQuote::configure do |c|
    c.side_id  "SomeSiteId"
    c.password "p4ssw0rd"
  end

  request = Dhl::GetQuote::new()
```

*Note*: options passed in to _Dhl::GetQuote::new()_ will override setting in the _Dhl::GetQuote::configure_ block.
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Add tests, make sure existing tests pass.
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/deseretbook/dhl-get_quote/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

```ruby

require 'dhl-shipment'
request=Dhl::Shipment::Request.new(:site_id => "MOVISADECV", :password => "a23M9jH1DC", :test_mode => true)

consignee_params = {}
consignee_params[:company_name] = 'Lekastillo SA de CV'
consignee_params[:address_line1] = 'Casa 5 N 4'
consignee_params[:city] = 'SAN SALVADOR'
consignee_params[:suburb] = 'COLONIA SAN BENITO'
consignee_params[:country_code] = 'SV'
consignee_params[:country_name] = 'EL SALVADOR'
consignee_params[:person_name] = 'Luis Castillo'
consignee_params[:phone_number] = 50324080686
consignee_params[:email] = 'castillovaliente@gmail.com'
consignee_params[:mobile_phone_number] = 50379900988

request.set_consignee(consignee_params)

shipper_params = {}
shipper_params[:shipper_id] = 123123123
shipper_params[:shipper_account] = 123123123
shipper_params[:company_name] = 'Mia Logistic'
shipper_params[:address_line1] = '2630 NW 75th Avenue'
shipper_params[:city] = 'MIAMI'
shipper_params[:postal_code] = 33122
shipper_params[:country_code] = 'US'
shipper_params[:country_name] = 'UNITED STATES OF AMERICA'
shipper_params[:person_name] = 'William Monico'
shipper_params[:phone_number] = 50324080686
shipper_params[:email] = 'luis_castillo777@hotmail.com'
shipper_params[:mobile_phone_number] = 50376349171

request.set_shipper(shipper_params)

shipment_detail_params = {}
shipment_detail_params[:weight] = 10
shipment_detail_params[:weight_unit] = 'K'
shipment_detail_params[:global_product_code] = 'P'
shipment_detail_params[:date] = DateTime.now.to_s
shipment_detail_params[:content] = 'algo que no se'
shipment_detail_params[:dimension_unit] = 'C'
shipment_detail_params[:package_type] = 'YP'
shipment_detail_params[:is_dutiable] = 'Y'
shipment_detail_params[:currency_code] = 'USD'
shipment_detail_params[:cust_data] = 'LABEL CUSTOM'


request.set_shipment_details(shipment_detail_params)

dutiable_params = {}

dutiable_params[:value] = 100
dutiable_params[:currency_code] = 'USD'
dutiable_params[:terms_of_trade] = 'DAP' 

request.dutiable(dutiable_params)

billing_params = {}

billing_params[:shipper_account_number] = '753871175'
billing_params[:shipping_payment_type] = 'S'
billing_params[:billing_account_number] = '753871175'
billing_params[:duty_payment_type] = 'S'
billing_params[:duty_account_number = '753871175'

request.pieces << Dhl::Shipment::Piece.new(:height => 20.0, :weight => 3.5, :width => 20.0, :depth => 19.0, :dim_weight => 3 )
request.shipment_time=DateTime.now.to_s
request.reference_id='123123123123'

request.to_xml

response = request.post

```