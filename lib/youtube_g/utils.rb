class YouTubeG
  module Utils

    private

      def calculate_offset(page, per_page)
        page == 1 ? 1 : ((per_page * page) - per_page + 1)
      end

      def integer_or_default(value, default)
        value = value.to_i
        value > 0 ? value : default
      end

      def join_params(params)
        params.to_a.map { | k, v | v.nil? ? nil : "#{YouTubeG.esc(k)}=#{YouTubeG.esc(v)}" }.compact.sort.join('&')
      end

    public

  end

end