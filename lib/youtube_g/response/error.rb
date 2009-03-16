class YouTubeG
  module Response
    class Error
      attr_reader :domain, :code, :location

      def initialize(domain, code, location = nil)
        @domain = domain
        @code = code
        @location = location
      end
    end

    def self.parse_errors(errors)
      ret = []

      if errors
        errors.elements.each("error") do |error|
          domain = error.elements["domain"].text.split(":").last.to_sym
          code = error.elements["code"].text.to_sym
          location = error.elements["location"].text if error.elements["location"]

          ret << Error.new(domain, code, location)
        end
      end

      ret
    end
  end
end
