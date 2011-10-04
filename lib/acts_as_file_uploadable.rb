module ActsAsFileUploadable #:nodoc:
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  module ClassMethods
    # == Configration options
    #
    # *<tt>dir</tt> - directory to upload (options, default: model name)
    # *<tt>file_field</tt> - name of file_field (option, default: "file")
    #
    # Examples:
    #
    #  acts_as_file_uploads :dir => :users
    #
    def acts_as_file_uploads(options = {})
      return if self.included_modules.include?(ActsAsFileUploadable::InstanceMethods)
      include ActsAsFileUploadable::InstanceMethods

      options[:dir] = self.model_name.underscore if options[:dir].blank?

      # create scope
      cattr_accessor :file_upload
      self.file_upload = FileUpload.new(self, options)

      class_eval do
        after_save :save_upload_file

        # use for file_field
        # example)
        # acts_as_file_uploads :dir => "uploads", :file_field => "file"
        #  <%= file_field :file %>
        define_method("#{self.file_upload.file_field}=") do |data|
          if defined?(data.content_type) && defined?(data.original_filename)
            self.content_type = data.content_type
            self.filename = data.original_filename
            @upload_tempfile = data
          else
            raise TypeError, "#{self.file_upload.file_field} is not UploadedFile, but #{data.class}"
          end
        end

        define_method("#{self.file_upload.file_field}") do
          @upload_tempfile
        end

        # generate filepath
        def upload_filepath(size = "")
          dirpath = self.upload_dirpath(size)
          "#{dirpath}/#{self.id.to_s}"
        end

        # generate dirpath
        def upload_dirpath(size = "")
          dir = "#{ActsAsFileUploadable::Config.upload_dir}/#{self.file_upload.dir}/"
        end

        # whether exist file
        def file_exist?(size = "")
          !!self.id && !!self.content_type && File.exist?(upload_filepath(size))
        end

        # whether upload file
        def upload_tempfile?
          !@upload_tempfile.nil?
        end
      end
    end
    # == Configration options
    #
    # *<tt>message</tt> - message for error (option)
    #
    # Examples:
    #
    #  validates_file_upload_of
    #
    def validates_file_upload_of(*attr_names)
      configuration = {
        :message => 'disallowed file format'
      }
      options = attr_names.pop if attr_names.last.is_a?(Hash)
      configuration.update options unless options.blank?

      unless configuration[:content_type].blank? || configuration[:content_type].is_a?(Array)
        configuration[:content_type] = [ configuration[:content_type] ]
      end

      validates_each attr_names do |record, attr_name, value|
        next if value.blank?
        ActiveRecord::Base.logger.debug(value.content_type)
        record.errors.add(attr_name, configuration[:message]) unless
          configuration[:content_type].blank? || configuration[:content_type].include?(value.content_type)
      end
    end
  end

  module InstanceMethods
    private
    def save_upload_file
      return if @upload_tempfile.nil?
      @upload_tempfile.rewind
      mkdir(upload_dirpath)
      File.open(self.upload_filepath, 'wb') do |f|
        f.write @upload_tempfile.read
      end
    end

    def mkdir(dir)
      FileUtils.mkdir_p dir unless File.exist?(dir)
    end
  end

  # interface for FileUploadable class
  class FileUpload
    attr_accessor :dir, :file_field

    def initialize(file_uploadable_class, options)
      configuration = {
        :file_field => "file"
      }

      @dir            = options[:dir].to_s
      @file_field     = (options[:file_field] || configuration[:file_field]).to_s
    end
  end

  # configuration
  class Config
    @@upload_dir = nil
    def self.upload_dir=(value)
      @@upload_dir = value
    end
    def self.upload_dir
      raise RuntimeError, "must config acts_as_file_uploadable.upload_dir" if @@upload_dir.blank?
      @@upload_dir
    end
  end

  class Railtie < ::Rails::Railtie
    config.acts_as_file_uploadable = Config
    initializer "acts_as_file_uploadable.initialize" do |app|
    end
  end
end
