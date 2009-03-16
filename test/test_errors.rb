
require File.dirname(__FILE__) + '/helper'

class TestErrors < Test::Unit::TestCase
 
  QUOTA_TOO_MANY_CALLS_ERROR = "<error><domain>yt:quota</domain><code>too_many_recent_calls</code></error>"
  AUTHENTICATION_TOKEN_EXPIRED_ERROR = "<error><domain>yt:authentication</domain><code>TokenExpired</code><location type='header'>Authorization: GoogleLogin</location></error>"

  def setup
  end

  def test_simple_error
    mock_response = flexmock(:status => 403, :body => "<?xml version='1.0' encoding='UTF-8'?><errors>>#{QUOTA_TOO_MANY_CALLS_ERROR}</errors>")
    
    YouTubeG.transport = flexmock(:grab => mock_response)
    client = YouTubeG::Client.new

    video = client.video_by("xxxxx")
    assert_equal 403, video.response_code
    assert_instance_of Array, video.errors
    assert_equal 1, video.errors.length
    assert_equal :quota, video.errors[0].domain
    assert_equal :too_many_recent_calls, video.errors[0].code
  end

  def test_two_errors
    mock_response = flexmock(:status => 403, :body => "<?xml version='1.0' encoding='UTF-8'?><errors>>#{QUOTA_TOO_MANY_CALLS_ERROR}#{AUTHENTICATION_TOKEN_EXPIRED_ERROR}</errors>")
    
    YouTubeG.transport = flexmock(:grab => mock_response)
    client = YouTubeG::Client.new

    video = client.video_by("xxxxx")
    assert_equal 403, video.response_code
    assert_instance_of Array, video.errors
    assert_equal 2, video.errors.length
    assert_equal :quota, video.errors[0].domain
    assert_equal :too_many_recent_calls, video.errors[0].code
    assert_equal :authentication, video.errors[1].domain
    assert_equal :TokenExpired, video.errors[1].code
  end
end
  
