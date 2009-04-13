class YouTubeG
  module Model
    class State < YouTubeG::Record
      # *String*:: State of the video, valid values are: processing, restricted, deleted, rejected, failed.
      attr_reader :name
      
      # *Fixnum*:: Reason for the failure, valid values vary per the name field.
      attr_reader :reason
      
      # *String*:: Link to YouTube help page about this error.
      attr_reader :help_url
    end
  end
end

