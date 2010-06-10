require 'rubygems'
require 'active_support'
require 'active_support/test_case'

module FileUploadableHelper
  def generate_tempfile(filetype = "")
    tmp = Tempfile.new("acts_as_file_uploads")
    open("#{File.dirname(__FILE__)}/misc/touhu.jpg") {|f| tmp.write f.read }
    tmp.rewind
    def tmp.original_filename; "touhu.jpg"; end
    case filetype.to_s
    when "jpeg"
      def tmp.content_type; "image/jpeg"; end
    when "gif"
      def tmp.content_type; "image/gif"; end
    when "png"
      def tmp.content_type; "image/png"; end
    else
      def tmp.content_type; "image/plain"; end
    end
    tmp
  end
end
