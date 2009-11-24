class YouTubeG
  module Request #:nodoc: 
    class BaseSearch #:nodoc:

      attr_reader :url

      include Utils
      
      private
      
      def base_url
        "http://gdata.youtube.com/feeds/api/"                
      end
      
      def set_instance_variables( variables )
        variables.each do |key, value| 
          name = key.to_s
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
      end
      
      def build_query_params(params)
        qs = join_params(params)
        qs.empty? ? '' : "?#{qs}"
      end

    end
    
  end
end