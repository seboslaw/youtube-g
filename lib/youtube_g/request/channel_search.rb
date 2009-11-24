class YouTubeG
  module Request #:nodoc:
    class ChannelSearch < BaseSearch #:nodoc:
      attr_reader :alt                             # alt
      attr_reader :query                           # q
      attr_reader :max_results                     # max_results
      attr_reader :offset                          # start-index
      attr_reader :strict                          # strict
      attr_reader :v                               # v (always 2 ???)

      def initialize(options={})
        @query, @max_results, @offset = nil
        @alt = 'atom'
        @strict = 'false'
        @v = 2

        @url = base_url
        set_instance_variables(options)

        @url << build_query_params(to_youtube_params)
      end

    private

      def base_url
        super << "channels"
      end

      def to_youtube_params
        {
          'alt' => @alt,
          'q' => @query,
          'max-results' => @max_results,
          'start-index' => @offset,
          'strict' => @strict,
          'v' => @v
        }
      end
    end
  end
end
