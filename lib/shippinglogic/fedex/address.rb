module Shippinglogic
  class FedEx

		# Address verification service from Fedex.
		#
		# == Options (address to be verified/corrected)
		# 
		# * <tt>company_name</tt> - name of the company (optional)
		# * <tt>streets</tt> - street address  (required)
		# * <tt>city</tt> - city  (required)
		# * <tt>state</tt> - state  (required for US addresses)
		# * <tt>postal_code</tt> - postal/zip code (required)
		# * <tt>country</tt> - country  (required)
		# * <tt>company_name_accuracy</tt> - company name accurancy (optional). Values: "LOOSE", "MEDIUM", "TIGHT", "EXACT" 
		# * <tt>street_accuracy</tt> - street accurancy (optional). Values: "LOOSE", "MEDIUM", "TIGHT", "EXACT" 
		# * <tt>directional_accuracy</tt> - directional accurancy (optional). Values: "LOOSE", "MEDIUM", "TIGHT", "EXACT" 
		# * <tt>maximum_number_of_matches</tt> - maximum number of matches (optional) - integer
		#
		# == Simple Example
		#
		#  	fedex = Shippinglogic::FedEx.new(key, password, account, meter)
		#  	fedex.address(:streets => "575 w 19th", :city => "costa mesa", :state => 'ca', :postal_code => '92627', :country => 'US')
		#
		# 	fedex.address 
		# 	#<Shippinglogic::FedEx::Address::Service:0x0000000607f728 @score="97", @changes=["MODIFIED_TO_ACHIEVE_MATCH", "APARTMENT_NUMBER_REQUIRED"], @delivery_point_validation="UNCONFIRMED", @address={:street_lines=>"575 W 19th St", :city=>"Costa Mesa", :state_or_province_code=>"CA", :postal_code=>"92627-2700", :country_code=>"US"}, @removed_non_address_data=nil>
		class Address < Service
			
			class Service; attr_accessor :score, :changes, :delivery_point_validation, :address, :removed_non_address_data; end
			
			VERSION = { :major => 2, :intermediate => 0, :minor => 0}
			
      attribute :company_name,      :string
      attribute :streets,           :string
      attribute :city,              :string
      attribute :state,             :string
      attribute :postal_code,       :string
      attribute :country,           :string,      :modifier => :country_code
			attribute :company_name_accuracy, :string
			attribute :street_accuracy,   :string
			attribute :directional_accuracy, :string
			attribute :maximum_number_of_matches, :integer

		  private
        def target
          @target ||= parse_response(request(build_request))
        end
        
        def build_request
          b = builder
          xml = b.AddressValidationRequest(:xmlns => "http://fedex.com/ws/addressvalidation/v#{VERSION[:major]}") do
            build_authentication(b)
            build_version(b, "aval", VERSION[:major], VERSION[:intermediate], VERSION[:minor])
            
						b.RequestTimestamp Time.now.strftime("%Y-%m-%dT%H:%M:%S")
						b.Options do
							b.VerifyAddresses true
		          b.CompanyNameAccuracy(company_name_accuracy) if company_name_accuracy
							b.StreetAccuracy(street_accuracy) if street_accuracy
							b.DirectionalAccuracy(directional_accuracy) if directional_accuracy
							b.MaximumNumberOfMatches(maximum_number_of_matches) if maximum_number_of_matches
						end
		        b.AddressesToValidate do
		          b.CompanyName(company_name) if company_name
		          b.Address do
		            b.StreetLines streets
		            b.City city
		            b.StateOrProvinceCode(state) if state
		            b.PostalCode postal_code
		            b.CountryCode country
		          end  
		        end
          end
        end

				def parse_response(response)
					return [] unless response[:address_results] && response[:address_results][:proposed_address_details]
					service = Service.new
					response[:address_results][:proposed_address_details].each do |key, value|
						service.send("#{key}=",value)
					end
					service
				end
		end
	end
end