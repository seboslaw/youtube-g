require 'fileutils'
require 'yaml'

SESSIONS_DIR = File.dirname(__FILE__) + '/session-transcripts'
FileUtils.rm_rf(SESSIONS_DIR)
FileUtils.mkdir_p(SESSIONS_DIR)

class Recorder < YouTubeG::Transport
    
  def self.send_req(opts = {})
    opts = rewrite_and_validate_options(opts)
    
    # Make a directory
    session_dir = File.join(SESSIONS_DIR, get_session_name)
    FileUtils.mkdir_p(session_dir)
    
    File.open(File.join(session_dir + '/request.txt'), 'w'){|f| f << format_request(opts) }
    
    # Run request
    resp = super(opts)
    
    # Dump response and return
    File.open(File.join(session_dir + '/response.txt'), 'w'){|f| f << format_headers_and_body(resp.headers, resp.body) }
    
    resp
  end
  
  # Return the name of the test case where this request gets initiated (indirectly)
  def self.get_session_name
    above = caller(3)
    begin
      above.grep(/test_/).shift.split(/\:in/).pop.gsub(/[\`\']/, '')
    rescue
      Time.now.to_s
    end
  end
  
  def self.format_request(options)
    first_line = [options[:method].upcase, options[:host], options[:path]].join(" ")
    first_line + "\n\n" + format_headers_and_body(options[:headers], options[:body])
  end
  
  def self.format_headers_and_body(headers, body)
    [headers.map{|(k,v)| "#{k}:  #{v}"}.join("\n"), body].join("\n\n")
  end
end