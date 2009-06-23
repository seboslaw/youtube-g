class YouTubeG
  module Parser #:nodoc:
    class FeedParser #:nodoc:
      def initialize(url, extra_headers={}, auth_opts={})
        @url = url
        @extra_headers = extra_headers
        @auth_opts = auth_opts
      end
      
      def parse
        content = YouTubeG.transport.grab(@url, @extra_headers, @auth_opts)
        parse_content content
      end      
    end
    
    class VideoFeedParser < FeedParser #:nodoc:
      
      def parse_content(response)
        doc = REXML::Document.new(response.body)
        entry = doc.elements["entry"]
        parse_entry(entry, response.status, YouTubeG::Response.parse_errors(doc.elements["errors"]))
      end
    
    protected
      def parse_entry(entry, response_code = 200, errors = []) 
        params = {:response_code => response_code, :errors => errors}

        if entry
          params[:video_id] = entry.elements["id"].text
          params[:published_at] = Time.parse(entry.elements["published"].text)
          params[:updated_at] = Time.parse(entry.elements["updated"].text)

          # parse the category and keyword lists
          categories = []
          keywords = []
          developer_tags = []
          entry.elements.each("category") do |category|
            # determine if  it's really a category, or just a keyword
            scheme = category.attributes["scheme"]
            if (scheme =~ /\/categories\.cat$/)
              # it's a category
              categories << YouTubeG::Model::Category.new(
                              :term => category.attributes["term"],
                              :label => category.attributes["label"])

            elsif (scheme =~ /\/keywords\.cat$/)
              # it's a keyword
              keywords << category.attributes["term"]
            elsif (scheme =~ /\/developertags\.cat$/)
              # it's a developer tag
              developer_tags << category.text
            end
          end
          params[:categories] = categories
          params[:keywords] = keywords
          params[:developer_tags] = developer_tags

          params[:title] = entry.elements["title"].text if entry.elements["title"]
          params[:html_content] = entry.elements["content"].text if entry.elements["content"]

          # parse the author
          author_element = entry.elements["author"]
          if author_element
            params[:author] = YouTubeG::Model::Author.new(
                              :name => author_element.elements["name"].text,
                              :uri => author_element.elements["uri"].text)
          end
      
          media_group = entry.elements["media:group"]
          if media_group
            params[:description] = media_group.elements["media:description"].text if media_group.elements["media:description"]
            params[:duration] = media_group.elements["yt:duration"].attributes["seconds"].to_i if media_group.elements["yt:duration"]

            media_content = []
            media_group.elements.each("media:content") do |mce|
              media_content << parse_media_content(mce)
            end
            params[:media_content] = media_content

            player = media_group.elements["media:player"]
            params[:player_url] = player.attributes["url"] if player

            media_group.elements.each("media:category") do |category|
              # determine if  it's really a category, or just a keyword
              scheme = category.attributes["scheme"]
              if (scheme =~ /\/developertags\.cat$/)
                # it's a developer tag
                developer_tags << category.text if !developer_tags.include?( category.text )
              end
            end
          end
          
          control = entry.elements["app:control"] 
          state = control.elements["yt:state"] if control
          params[:state] = YouTubeG::Model::State.new(
                              :name => state.attributes["name"],
                              :reason => state.attributes["reasonCode"],
                              :help_url => state.attributes["helpUrl"]) if state

          # parse thumbnails
          thumbnails = []
          media_group.elements.each("media:thumbnail") do |thumb_element|
            # TODO: convert time HH:MM:ss string to seconds?
            thumbnails << YouTubeG::Model::Thumbnail.new(
                            :url => thumb_element.attributes["url"],
                            :height => thumb_element.attributes["height"].to_i,
                            :width => thumb_element.attributes["width"].to_i,
                            :time => thumb_element.attributes["time"])
          end
          params[:thumbnails] = thumbnails

          rating_element = entry.elements["gd:rating"]
          if rating_element
            params[:rating] = YouTubeG::Model::Rating.new(
                               :min => rating_element.attributes["min"].to_i,
                               :max => rating_element.attributes["max"].to_i,
                               :rater_count => rating_element.attributes["numRaters"].to_i,
                               :average => rating_element.attributes["average"].to_f)
          end

          params[:view_count] = (el = entry.elements["yt:statistics"]) ? el.attributes["viewCount"].to_i : 0

          params[:noembed] = entry.elements["yt:noembed"] ? true : false
          params[:racy] = entry.elements["media:rating"] ? true : false

          if where = entry.elements["georss:where"]
            params[:where] = where
            params[:position] = where.elements["gml:Point"].elements["gml:pos"].text
            params[:latitude], params[:longitude] = params[:position].split(" ")
          end
        end

        YouTubeG::Model::Video.new( params )
      end

      def parse_media_content (media_content_element) 
        content_url = media_content_element.attributes["url"]
        format_code = media_content_element.attributes["yt:format"].to_i
        format = YouTubeG::Model::Video::Format.by_code(format_code)
        duration = media_content_element.attributes["duration"].to_i
        mime_type = media_content_element.attributes["type"]
        default = (media_content_element.attributes["isDefault"] == "true")

        YouTubeG::Model::Content.new(
          :url => content_url,
          :format => format,
          :duration => duration,
          :mime_type => mime_type,
          :default => default)
      end      
    end

    class VideosFeedParser < VideoFeedParser #:nodoc:

    private
      def parse_content(response)
        doc = REXML::Document.new(response.body)
        errors = YouTubeG::Response.parse_errors(doc.elements["errors"])
        feed = doc.elements["feed"]

        params = {:response_code => response.status, :errors => errors}

        if feed
          params[:feed_id] = feed.elements["id"].text
          params[:updated_at] = Time.parse(feed.elements["updated"].text)
          params[:total_result_count] = feed.elements["openSearch:totalResults"].text.to_i
          params[:offset] = feed.elements["openSearch:startIndex"].text.to_i
          params[:max_result_count] = feed.elements["openSearch:itemsPerPage"].text.to_i

          videos = []
          feed.elements.each("entry") do |entry|
            videos << parse_entry(entry)
          end
          params[:videos] = videos
        end

        YouTubeG::Response::VideoSearch.new( params )
      end
    end
    
  class UserFeedParser < FeedParser #:nodoc:

    def parse_content(response)
      doc = REXML::Document.new(response.body)
      errors = YouTubeG::Response.parse_errors(doc.elements["errors"])
      entry = doc.elements["entry"]

      params = {:response_code => response.status, :errors => errors}

      if entry
        params[:id] = entry.elements["id"].text
        params[:joined] = Time.parse(entry.elements["published"].text)

        params[:username] = entry.elements["yt:username"].text

        params[:view_count] = (el = entry.elements["yt:statistics"]) ? el.attributes["viewCount"].to_i : 0
        params[:watch_count] = (el = entry.elements["yt:statistics"]) ? el.attributes["videoWatchCount"].to_i : 0
        params[:subscriber_count] = (el = entry.elements["yt:statistics"]) ? el.attributes["subscriberCount"].to_i : 0

        thumbnail = entry.elements["media:thumbnail"]
        params[:thumbnail] = YouTubeG::Model::Thumbnail.new(:url => thumbnail.attributes["url"]) if thumbnail

      end

      YouTubeG::Model::User.new(params)
    end
    
  end

  end 

end
