class YouTubeG
  class Client
    include YouTubeG::Logging
    include YouTubeG::Request::Helper
    
    # Previously this was a logger instance but we now do it globally
    def initialize(options={})
      @init_options = options.kind_of?(Hash) ? options : {}
    end
    
    # Retrieves an array of standard feed, custom query, or user videos.
    # 
    # === Parameters
    # If fetching videos for a standard feed:
    #   params<Symbol>:: Accepts a symbol of :top_rated, :top_favorites, :most_viewed, 
    #                    :most_popular, :most_recent, :most_discussed, :most_linked, 
    #                    :most_responded, :recently_featured, and :watch_on_mobile.
    #  
    #   You can find out more specific information about what each standard feed provides
    #   by visiting: http://code.google.com/apis/youtube/reference.html#Standard_feeds                 
    #   
    #   options<Hash> (optional)::  Accepts the options of :time, :page (default is 1), 
    #                               and :per_page (default is 25). :offset and :max_results
    #                               can also be passed for a custom offset.
    #  
    # If fetching videos by tags, categories, query:
    #   params<Hash>:: Accepts the keys :tags, :categories, :query, :order_by, 
    #                  :author, :racy, :response_format, :video_format, :page (default is 1), 
    #                  and :per_page(default is 25)
    #                  
    #   options<Hash>:: Not used. (Optional)
    # 
    # If fetching videos for a particular user:
    #   params<Hash>:: Key of :user with a value of the username.
    #   options<Hash>:: Not used. (Optional)
    # === Returns
    # YouTubeG::Response::VideoSearch
    def videos_by(params, options={})
      request_params = params.respond_to?(:to_hash) ? params : options
      request_params[:page] = integer_or_default(request_params[:page], 1)
      
      unless request_params[:max_results]
        request_params[:max_results] = integer_or_default(request_params[:per_page], 25)
      end
      
      unless request_params[:offset]
        request_params[:offset] = calculate_offset(request_params[:page], request_params[:max_results] )
      end
      
      if params.respond_to?(:to_hash) and not params[:user]
        request = YouTubeG::Request::VideoSearch.new(request_params)
      elsif (params.respond_to?(:to_hash) && params[:user]) || (params == :favorites)
        request = YouTubeG::Request::UserSearch.new(params, request_params)
      else
        request = YouTubeG::Request::StandardSearch.new(params, request_params)
      end
      
      logger.debug "Submitting request [url=#{request.url}]."
      parser = YouTubeG::Parser::VideosFeedParser.new(request.url, request_headers, request_options)
      parser.parse
    end
    
    # Retrieves a single YouTube video.
    #
    # === Parameters
    #   params<Hash>:: key :video_id with the unique_id or video_id to load, optional key :user for the user to load
    #                  (:user is required to retrieve data on unpublished videos).  For legacy purposes, params can also
    #                  be a string containing the video_id
    # 
    # === Returns
    # YouTubeG::Model::Video
    def video_by(params)
      params = {:video_id => params} if !params.is_a?(Hash)
      url = "http://gdata.youtube.com/feeds/api/"
      video_id = params[:video_id].split("/").last
      if params[:user]
        url << "users/#{params[:user]}/uploads/#{video_id}"
      else
        url << "videos/#{video_id}"
      end
      parser = YouTubeG::Parser::VideoFeedParser.new(url, request_headers, request_options)
      parser.parse
    end
    
    # Retrieves a YouTube user profile.
    #
    # === Parameters
    #   user<String>:: The name of the user who you would like to retrieve, or nil for the logged in user
    # 
    # === Returns
    # YouTubeG::Model::User
    def user_by_name(user = "default")
      url = user =~ /^http/ ? user : "http://gdata.youtube.com/feeds/users/#{user}"
      parser = YouTubeG::Parser::UserFeedParser.new(url, request_headers, request_options)
      parser.parse
    end
    
    #private
    
    def calculate_offset(page, per_page)
      page == 1 ? 1 : ((per_page * page) - per_page + 1)
    end
    
    def integer_or_default(value, default)
      value = value.to_i
      value > 0 ? value : default
    end

  end
end
