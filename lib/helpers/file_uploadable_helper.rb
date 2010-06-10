module FileUploadableHelper
  def acts_as_image_uploads(model, upload_model)
    class_eval <<-EOS
      def #{model}_image_tag(model, options = {})
        unless options[:name].blank?
          file = model.#{upload_model}s.find_by_name(options[:name])
        else
          file = model.#{upload_model}s.first
        end
        #{upload_model}_image_tag(file, options)
      end

      def #{upload_model}_image_tag(file, options = {})
        html = ''
        options = { :html => {} }.update(options)
        if !file.nil? && file.file_exist?(options[:size])
          html = image_tag #{upload_model}_path(file, :size => options[:size]), options[:html]
          html = link_to html, options[:url] unless options[:url].blank?
        end

        html
      end
    EOS
  end

end
