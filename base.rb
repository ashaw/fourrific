require 'yaml'

module Fourrific
  
  VERSION = '0.0.3'
  
  class Authorize
    
    #get keys from YAML
    f = File.open( 'credentials.yml' ) { |yf| YAML::load( yf ) }
    CONSUMER_KEY = f['foursquare_keys']['key'].to_s
    CONSUMER_SECRET = f['foursquare_keys']['secret'].to_s
    
    def initialize
      @consumer = OAuth::Consumer.new(CONSUMER_KEY,CONSUMER_SECRET, {
             :site               => "http://foursquare.com",
             :scheme             => :header,
             :http_method        => :post,
             :request_token_path => "/oauth/request_token",
             :access_token_path  => "/oauth/access_token",
             :authorize_path     => "/oauth/authorize"
            })
                                                  # add callback URL, or 4sq will ask you to
                                                  # enter a "pin" number in the app
      @request_token=@consumer.get_request_token :oauth_callback => "http://localhost:4567/"      
    end
    
    def get_tokens
      #store @request_token.token and @request_token.secret for use when you get the callback
      #ask user to visit @request_token.authorize_url
      
      @tokens = {}
      @tokens[:request_token] = @request_token.token
      @tokens[:secret] = @request_token.secret
      @tokens[:url] = @request_token.authorize_url
      
      @tokens
    end
    
    
    def access_token(oauth_token,secret,oauth_verifier)
      #... in your callback page:
      # request_token_key will be 'oauth_token' in the query paramaters of the incoming get request
      
      @request_token = OAuth::RequestToken.new(@consumer, oauth_token, secret)
      @access_token=@request_token.get_access_token :oauth_verifier => oauth_verifier
      
      @access_tokens = {}
      @access_tokens[:token] = @access_token.token
      @access_tokens[:secret] = @access_token.secret
      
      @access_tokens
      #store @access_token.token and @access_token.secret
    end
  
  end
  
  class IPGeocode
    
    def initialize(ip)
      # compensate for localhost
      # http://www.commandlinefu.com/commands/view/1733/get-own-public-ip-address
      if ip == "127.0.0.1"
        ip = `curl -s checkip.dyndns.org | grep -Eo '[0-9\.]+'`.strip
      end
      
      @g = Geokit::Geocoders::MultiGeocoder.geocode(ip)
    end
    
    def ll
      @ll = {}
    
      @ll[:lat] = @g.lat
      @ll[:long] = @g.lng
    
      @ll
    end
    
    def you_are_in
      @g.city
    end
    
  end

  class Checkins    
    def initialize(access,secret)
      
      @consumer = OAuth::Consumer.new(Fourrific::Authorize::CONSUMER_KEY,Fourrific::Authorize::CONSUMER_SECRET, {
             :site               => "http://api.foursquare.com",
             :scheme             => :header,
             :http_method        => :post,
            })  
            
      @access_token = OAuth::AccessToken.new(@consumer, access, secret)     
    end
    
    #g is a geocode array from IPGeocode.new
    def friends(g)
      
      ip = g.ll
      @friends = @access_token.get("/v1/checkins?geolat=#{ip[:lat]}&geolong=#{ip[:long]}", {'User-Agent' => "fourrific:#{Fourrific::VERSION}"}).body  
      
      begin
        @friends = Crack::XML.parse(@friends)
        if @friends['unauthorized']
          @error = "#{@friends['unauthorized']}. Clear your cookies & cache and try again."
        elsif @friends['ratelimited']
          @error = "#{@friends['ratelimited']}. Please try again later."
        elsif @friends['error']
          @error = "#{@friends['error']}"
        else
          @friends['checkins']['checkin'].each do |checkin|
            checkin['created'] = checkin['created'].to_time.iso8601
            checkin['distance'] = (checkin['distance'].to_i / 1609.344).to_i
          end
        end       
      end
      
  
      @friends
    
    end
    
    def first_is_far?
      checkin = @friends['checkins']['checkin'][0]
      return true if checkin['distance'] > 25
    end
    
    def error
      @error 
    end
    
  end
  

end

