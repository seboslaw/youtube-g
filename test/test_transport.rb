require File.dirname(__FILE__) + '/helper'

class TestTransport < Test::Unit::TestCase
  
  def setup
    @klass = YouTubeG::Transport # save typing
  end
  
  def test_grab_raises_when_url_is_not_protocol_prefixed
    assert_raise(@klass::BadRequest) do
      @klass.grab("google.com/foo")
    end
  end
  
  def test_grab_should_obviously_grab
    mock_response = flexmock(:body => "fooResp")
    rewritten_args = {:path=>"/foo?bar=baz", :body=>"", :method=>"get", :host=>"google.com",
        :headers=>{"Content-Type"=>"application/x-www-form-urlencoded"}}
    
    flexmock(@klass).should_receive(:send_req).with(rewritten_args).once.and_return(mock_response)
    
    returned_body = @klass.grab("http://google.com/foo?bar=baz").body
    assert_equal "fooResp", returned_body
  end
  
  def test_raises_on_unsupported_method
    assert_raise(@klass::BadRequest) do
      @klass.send_req(:method => nil, :host => "google.com", :path => '/')
    end
  end
  
  def test_raises_without_host
    opts = {}
    assert_raise(@klass::BadRequest) { @klass.send(:rewrite_and_validate_options, opts) }
  end

  def test_rewrite_and_validate_options_should_make_sane_defaults
    opts = {:host => 'foo.com'}
    rewritten = @klass.send(:rewrite_and_validate_options, opts)
    
    assert_equal "get", rewritten[:method]
    assert_equal "/", rewritten[:path]
    assert_equal "", rewritten[:body]
    assert_equal 80, rewritten[:port]
    assert_equal false, rewritten[:ssl]
    assert_equal( {"Content-Type"=>"application/x-www-form-urlencoded"}, rewritten[:headers])
  end
  
  def test_rewrite_and_validate_options_should_make_sane_ssl_port
    opts = {:host => 'foo.com', :ssl => true}
    
    rewritten = @klass.send(:rewrite_and_validate_options, opts)
    
    assert_equal 443, rewritten[:port]
  end

  def test_should_perform_the_request
    
    mock_req = flexmock
    mock_req.should_receive(:body=).with("hello").once
    
    mock_req_class = flexmock
    mock_req_class.should_receive(:new).once.and_return(mock_req)
    
    mock_resp = flexmock(:code => "201", :body => "Hello from google")
    mock_resp.should_receive(:canonical_each).and_yield("X-Meta", "Test")
    
    flexmock(Net::HTTP).should_receive(:const_get).once.with("Post").and_return(mock_req_class)
    
    mock_session = flexmock
    mock_session.should_receive(:request).with(mock_req).once.and_return(mock_resp)
    
    flexmock(Net::HTTP).should_receive(:new).with("google.com", 80).and_return(mock_session)
    
    response = @klass.send_req(:method => 'post', :host => 'google.com', :body => "hello")
    
    assert_kind_of @klass::Response, response
    assert_equal 201, response.status
    assert_equal "Hello from google", response.body
    assert_equal({"X-Meta" => "Test"}, response.headers)
  end
end
