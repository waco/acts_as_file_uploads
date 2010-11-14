module FileUploadableHelper
  def acts_as_file_uploads(model, upload_model, options = {})
    class_eval <<-EOS
      def #{options[:prefix]}#{model}_file_path(model, options = {})
        file = acts_as_file_uploads_find_first(model.#{upload_model}s, options[:name])
        #{options[:prefix]}#{upload_model}_file_path(file, options)
      end

      def #{options[:prefix]}#{model}_file_url(model, options = {})
        file = acts_as_file_uploads_find_first(model.#{upload_model}s, options[:name])
        #{options[:prefix]}#{upload_model}_file_url(file, options)
      end

      def #{options[:prefix]}#{upload_model}_file_path(file, options = {})
        options[:params] ||= {}
        !file.blank? && file.file_exist?(options[:size]) ?
          #{upload_model}_path(file, {:size => options[:size]}.merge(options[:params])) : nil
      end

      def #{options[:prefix]}#{upload_model}_file_url(file, options = {})
        options[:params] ||= {}
        !file.blank? && file.file_exist?(options[:size]) ? 
          #{upload_model}_url(file, {:size => options[:size]}.merge(options[:params])) : nil
      end
    EOS
  end

  def acts_as_image_uploads(model, upload_model, options = {})
    class_eval <<-EOS
      acts_as_file_uploads(:#{model}, :#{upload_model},
        :prefix => options[:prefix]) unless respond_to?(:#{options[:prefix]}#{model}_file_path)

      def #{options[:prefix]}#{model}_image_tag(model, options = {})
        file = acts_as_file_uploads_find_first(model.#{upload_model}s, options[:name])
        #{upload_model}_image_tag(file, options)
      end

      def #{options[:prefix]}#{upload_model}_image_tag(file, options = {})
        html = ''
        options = { :image_attr => { :alt => '' } }.update(options)
        path = #{options[:prefix]}#{upload_model}_file_path(file, options)
        unless path.blank?
          html = image_tag(path, options[:image_attr])
          html = link_to(html, options[:url], options[:link_attr]) unless options[:url].blank?
        end

        html
      end
    EOS
  end

  private

  def acts_as_file_uploads_find_first(model, name = nil)
    name.blank? ? model.first : model.find_by_name(name)
  end
end
