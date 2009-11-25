class YouTubeG
  module Model
    class Channel < YouTubeG::Record
      include Utils
      include YouTubeG::Logging

      # id, updated, category*, title, content?, link*, author?, summary?, yt:countHint

      # *String*:: id for the channel.
      attr_reader :channel_id

      # *Time*:: When the channel's data was last updated.
      attr_reader :updated_at

      # *Array*:: A array of YouTubeG::Model::Category objects that describe the channels categories.
      attr_reader :categories

      # *String*:: Title for the channel.
      attr_reader :title

      # *String*:: User entered description for the channel.
      attr_reader :summary

      # YouTubeG::Model::Author:: Information about the YouTube user.
      attr_reader :author

      # *String*:: Link to channel videos feed
      attr_reader :videos_link

      # *Fixnum*:: Specifies the number of entries in a channel feed.
      attr_reader :count_hint

      # The ID of the channel, useful for searching for the channel again without having to store it anywhere.
      # A regular query search, with this id will return the same channel.
      #
      # === Example
      #   >> channel.unique_id
      #   => "ZTUVgYoeN_o"
      #
      # === Returns
      #   String: The Youtube channel id.
      def unique_id
        channel_id[/channel:([^<]+)/, 1]
      end

      # The maximal page number for channel videos set.
      #
      # === Example
      #   >> channel.max_page(per_page = 10)
      #   => 3
      #
      # === Returns
      #   Integer: The maximal page number.
      def max_page(per_page = 10)
        count_hint / per_page + (count_hint % per_page == 0 ? 0 : 1)
      end

      # Videos to the current channel.
      #
      #   params<Hash>::  :query, :page (default is 1) and :per_page(default is 25)
      #
      # === Returns
      #   YouTubeG::Response::VideoSearch
      def get_videos(options)
        options[:page] = integer_or_default(options[:page], 1)
        params = {}
        params['max-results'] = integer_or_default(options[:per_page], 25)
        params['start-index'] = calculate_offset(options[:page], params['max-results'] )
        params['q'] = options[:query]
        url_params = join_params(params)
        url_params = videos_link.include?("?") ? "&#{url_params}" : "?#{url_params}"
        url = "#{videos_link}#{url_params}"
        logger.debug "Submitting request [url=#{url}]." if logger
        YouTubeG::Parser::VideosFeedParser.new(url).parse
      end

    end
  end
end
