require 'set'

class YouTubeG
  # A very thin abstraction on top of Net::HTTP that we use exclusively. We need that to be able
  # to test the library without rewiring half of Net::HTTP. In client code:
  #
  #   response = Transport.post_req(:host => base_url, :port => 80, :headers => {"Content-Type" => "text/plain"}, :body => "Hello world")
  #   response.status # => 201
  #
  # In testing code:
  #
  #  fake_response = Trasnsport::Response.new(:status => 200, :body => "Google homepage")
  #  flexmock(Transport).should_receive(:get_req).with(:host => "google.com", :headers => {}).and_return(fake_response)
  #
  # We also use Transport to record our conversations with the server and to provide canned responses and requests, and it
  # can be used to inject a caching layer
  class Transport
    
    class BadRequest < ArgumentError
    end
    
    REQUIRED_OPTIONS = [:url, :method, :headers, :body].freeze
    METHODS = %w( get post put delete head )
    DEFAULT_HEADERS = { 'Content-Type' => 'application/x-www-form-urlencoded' }
    DEFAULTS = { :method => 'get',  :body => '', :headers => DEFAULT_HEADERS }
    
    # Grab the page body via GET, open-uri style
    def self.grab(url, extra_headers = {}, opts = {})
      raise BadRequest, "arg to grab should start with http(s) but was #{url}" unless url =~ /^http(s?)/ # and so on
      # Mixin headers
      headers = DEFAULTS[:headers].merge(extra_headers)
      opts = {:method => 'get', :body => '', :url => url, :headers => headers }.merge(opts)
      send_req(opts)
    end
    
    # Send a POST request
    def self.post_req(opts = {})
      send_req(opts.merge(:method => 'post'))
    end
    
    # Send a PUT request
    def self.put_req(opts = {})
      send_req(opts.merge(:method => 'put'))
    end
    
    def self.send_req(request_options = {})
      opts = rewrite_and_validate_options(request_options)

      net_http_resp = get_http_response(opts) 
      
      # Collect headers respecting the case, stupidly Net:HTTPHeaders does not do inject
      resp_headers = {}
      net_http_resp.canonical_each do | k, v |
        resp_headers[k] = v
      end
      
      # And return our own response
      Response.new(:status => net_http_resp.code, :body => net_http_resp.body, :headers => resp_headers)
    end
    
    # A response wrapper. Has three methods - status, headers and body
     # (these are the ones to be mocked when needed)
     class Response
       
       # Also defines the readers
       RESPONSE_ATTRS = [:status, :headers, :body]
       attr_accessor(*RESPONSE_ATTRS)
       
       def initialize(opts = {})
         raise BadRequest, "Wrong attributes for the response (got #{opts.keys})" unless (RESPONSE_ATTRS.to_set == opts.keys.to_set)

         # Assign options
         opts.map{|(k,v)| send("#{k}=", v) }

         # Integerize status, stringify body
         @status, @body = @status.to_i, @body.to_s
       end
     end
     
    private
    
    def self.get_http_response(opts)
      meth, url, headers, body, net_http = opts.values_at(:method, :url, :headers, :body, :net_http)

      if net_http
        args = [meth, url]
        args << body if [:post, :put].include? meth.to_sym
        args << headers
        net_http.send(*args)
      else
        url = URI.parse(url)
      
        # Translate "post" to Net::HTTP::Post and instantiate
        request = Net::HTTP.const_get(meth.to_s.capitalize).new(url.path, headers)
      
        # If body is IO, use body_stream
        if body.respond_to?(:read)
          request.body_stream = body
        else
          request.body = body
        end
      
        # We use new instead of start to be able to assert
        session = Net::HTTP.new(url.host, url.port)
        session.use_ssl = true if "https" == url.scheme
        session.request(request)
      end
    end

    def self.rewrite_and_validate_options(options)
      # Merge with defaults
      opts = DEFAULTS.merge(options)
      
      # Validate that _all_ options are there
      missing = REQUIRED_OPTIONS.to_set - opts.keys.to_set
      raise BadRequest, "Some options were missing (#{missing.to_a})" if missing.any?
      
      # Validate method
      opts[:method] = opts[:method].to_s
      raise BadRequest, "Unknown method #{opts[:method]}" unless METHODS.include?(opts[:method])
      
      opts
    end
    
  end

end
