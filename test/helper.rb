require 'rubygems'
require 'test/unit'
require 'pp'
require 'flexmock'
require 'flexmock/test_unit'

require File.dirname(__FILE__) + '/../lib/youtube_g'
require File.dirname(__FILE__) + '/recorder'

YouTubeG.logger.level = Logger::ERROR