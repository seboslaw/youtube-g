class YouTubeG
  module Model
    class User < YouTubeG::Record

      # *Fixnum*:: HTTP response code, this is only set for methods which return a single video
      attr_reader :response_code

      # *Array*:: an array of Error object, only set in methods which return a single video and only if the request failed
      attr_reader :errors
      
      attr_reader :age
      attr_reader :books
      attr_reader :company
      attr_reader :gender
      attr_reader :hobbies
      attr_reader :hometown
      attr_reader :location
      attr_reader :movies
      attr_reader :music
      attr_reader :occupation
      attr_reader :relationship
      attr_reader :school
      attr_reader :description
      attr_reader :username
      attr_reader :view_count
      attr_reader :watch_count
      attr_reader :subscriber_count
      attr_reader :joined
      attr_reader :thumbnail
    end
  end
end
