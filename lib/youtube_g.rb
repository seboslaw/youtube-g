require 'logger'
require 'open-uri'
require 'net/https'
require 'digest/md5'
require 'rexml/document'
require 'builder'

class YouTubeG
  
  # Base error class for the extension
  class Error < RuntimeError
  end
  
  class <<self
    # URL-escape a string. Stolen from Camping (wonder how many Ruby libs in the wild can say the same)
    def esc(s) #:nodoc:
      s.to_s.gsub(/[^ \w.-]+/n){'%'+($&.unpack('H2'*$&.size)*'%').upcase}.tr(' ', '+')
    end
  
    # The logger instance and the transport class
    attr_accessor :logger, :transport
  
    # Get the logger for the library (by default will log to STDOUT). TODO: this is where we grab the Rails logger too
    def logger
      @logger ||= create_default_logger
    end
  
    # Get the transport class (not instance) used for HTTP requests, can be swapped in
    def transport
      @transport ||= Transport
    end
    
    private
      def create_default_logger
        logger = Logger.new(STDOUT)
        logger.level = Logger::DEBUG
        logger
      end
  end

  # Gets mixed into the classes to provide the logger method
  module Logging #:nodoc:
    
    # Return the base logger set for the library
    def logger
      YouTubeG.logger
    end
  end
end

%w( 
  version
  transport
  client
  record
  parser
  model/author
  model/category
  model/contact
  model/content
  model/playlist
  model/rating
  model/thumbnail
  model/user
  model/video
  request/base_search
  request/user_search
  request/standard_search
  request/video_upload
  request/video_search
  response/video_search
  response/error
  chain_io
).each{|m| require File.dirname(__FILE__) + '/youtube_g/' + m }
