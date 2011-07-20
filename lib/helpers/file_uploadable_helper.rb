module FileUploadableHelper
  def acts_as_file_uploads
    class_eval <<-EOS
    EOS
  end

  def acts_as_image_uploads
    class_eval <<-EOS
      acts_as_file_uploads

      alias :method_missing_old :method_missing
      def method_missing(method_id, *args, &block)
        method_name = method_id.to_s
        if /_image_tag$/ =~ method_name
          create_image_tag(method_name, args, block)
        else
          method_missing_old
        end
      end
    EOS
  end

  private

  def create_image_tag(method_name, args, block)
    path = __send__(method_name.gsub(/_image_tag$/, '_path'), *args) rescue nil
    path.nil? ? '' : image_tag(path)
  end
end
