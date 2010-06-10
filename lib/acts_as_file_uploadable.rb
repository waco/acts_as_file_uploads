module ActsAsFileUploadable #:nodoc:
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  module ClassMethods
    # == Configration options
    #
    # *<tt>dir</tt> - directory to upload (required)
    # *<tt>file_field</tt> - name of file_field (option, default: "file")
    #
    # Examples:
    #
    #  acts_as_file_uploads :dir => :users
    #
    def acts_as_file_uploads(options = {})
      return if self.included_modules.include?(ActsAsFileUploadable::InstanceMethods)
      include ActsAsFileUploadable::InstanceMethods

      # errors
      raise ArgumentError, ["Define 'ActsAsFileUploadable::UPLOADS_DIR' in 'config/developments/ENV.rb'",
        "(ex. ActsAsFileUploadable::UPLOADS_DIR = \"\#{RAILS_ROOT}/uploads/development\")"
        ].join("\n") unless defined? ActsAsFileUploadable::UPLOADS_DIR  

      raise ArgumentError, "options[:dir] is required" if options[:dir].blank?  

      # create scope
      cattr_accessor :file_upload
      self.file_upload = ActsAsFileUploadable::FileUpload.new(self, options)

      class_eval do
        after_save :save_upload_file

        # use for file_field
        # example) 
        # acts_as_file_uploads :dir => "uploads", :file_field => "file"
        #  <%= file_field :file %>
        define_method("#{self.file_upload.file_field}=") do |data|
          raise TypeError, "#{self.file_upload.file_field} is not TempFile" unless data.is_a? Tempfile

          self.content_type = data.content_type 
          self.filename = data.original_filename   

          @upload_tempfile = data
        end 

        define_method("#{self.file_upload.file_field}") do
          @upload_tempfile
        end 

        # generate filepath
        def upload_filepath(size = "")
          dirpath = self.upload_dirpath(size)
          filename = "#{dirpath}/#{self.id.to_s}"
        end

        # generate dirpath
        def upload_dirpath(size = "")
          size = size.to_s
          dir = "#{ActsAsFileUploadable::UPLOADS_DIR}/#{self.file_upload.dir}/"
        end

        def file_exist?(size = "")
          !!self.id && !!self.content_type && File.exist?(upload_filepath(size))
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
      `mkdir -p "#{dir}"` unless File.exist?(dir)
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

end
