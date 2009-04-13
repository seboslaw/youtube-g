class YouTubeG
  module Request #:nodoc: 
    module Helper #:nodoc:
      def request_headers
        @request_headers ||= begin
          h = {}
          h['X-GData-Client'] = @init_options[:client] if @init_options[:client]
          h['X-GData-Key'] = "#{@init_options[:key] =~ /^key=/ ? "" : "key=" }#{@init_options[:key]}" if @init_options[:key]
          h['Authorization']  = "GoogleLogin auth=#{auth_token}" if :client_login == @init_options[:auth]
          h
        end
      end

      def request_options
        @request_options ||= begin
          h = {}
          h[:net_http] = @init_options[:oauth_token] if @init_options[:auth] == :oauth
          h
        end
      end

      def auth_token
        @auth_token ||= begin
          user = @init_options[:login_user] || @init_options[:user]
          response = YouTubeG.transport.post_req(
            :body => "Email=#{YouTubeG.esc user}&Passwd=#{YouTubeG.esc @init_options[:pass]}&service=youtube&source=#{YouTubeG.esc @init_options[:client_id]}",
            :url => "https://www.google.com/youtube/accounts/ClientLogin"
          )
          raise YouTubeG::Errors::AuthenticationError, response.body[/Error=(.+)/,1] if response.status.to_i != 200
          @auth_token = response.body[/Auth=(.+)/, 1]
        end
      end
      
    end
  end
end


