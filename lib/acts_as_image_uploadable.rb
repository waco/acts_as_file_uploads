module ActsAsImageUploadable #:nodoc:
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  module ClassMethods
    # == Configration options
    #
    # *<tt>dir</tt> - directory to upload (options, default: model name)
    # *<tt>file_field</tt> - name of file_field (option, default: "file")
    # *<tt>resize_list</tt> - list of resize image size. require follow format (option)
    # *<tt>convert</tt> - convert to your format (option)
    #  [
    #    { :name => 'size name', :width => 'resize width', :height => 'resize height'},
    #    { ... },
    #  ]
    #
    # Examples:
    #
    #  acts_as_image_uploads :dir => :users, :resize_list => [:name => 'thumbs', :width => 100, :height => 100]
    #
    def acts_as_image_uploads(options = {})
      return if self.included_modules.include?(ActsAsImageUploadable::InstanceMethods)
      include ActsAsImageUploadable::InstanceMethods

      raise ArgumentError, "options[:resize_list] are invalid format" unless
        options[:resize_list].blank? || (
          options[:resize_list].is_a?(Array) &&
          !options[:resize_list].index{|r| !(r.has_key?(:name) && r.has_key?(:width) && r.has_key?(:height)) }
        )
      options[:dir] = self.model_name.underscore if options[:dir].blank?

      ActsAsFileUploadable::FileUpload.class_eval do
        attr_accessor :resize_list, :dir, :file_field, :resize_name, :convert

        def initialize(file_uploadable_class, options)
          configuration = {
            :resize_list => [
              {:name => "middle", :width => 240, :height => 240},
              {:name => "thumbs", :width => 100, :height => 100}
            ],
            :file_field => "file"
          }

          @resize_list    = options[:resize_list] || configuration[:resize_list]
          @dir            = options[:dir].to_s
          @file_field     = (options[:file_field] || configuration[:file_field]).to_s
          @resize_name    = self.resize_list.map { |r| r[:name].to_s }
          @convert = options[:convert].nil? ? nil : options[:convert].to_s
        end
      end

      acts_as_file_uploads(options)

      class_eval do
        before_save :fix_jpeg_content_type
        alias :image_exist? :file_exist?

        alias :original_upload_dirpath :upload_dirpath

        # generate dirpath
        def upload_dirpath(size = "")
          dir = original_upload_dirpath(size)
          dir << (self.file_upload.resize_name.include?(size) ? size : "original")
        end

        private

        alias :original_save_upload_file :save_upload_file
        def save_upload_file
          return if @upload_tempfile.nil?
          @upload_tempfile.rewind
          mkdir(upload_dirpath(name))
          img = Magick::ImageList.new
          img.from_blob(@upload_tempfile.read)
          file_upload_class = self.file_upload
          img.write(upload_filepath(name)) do
            self.format = file_upload_class.convert if file_upload_class.convert
          end
          resize_files
        end

        def resize_files
          img = ::Magick::ImageList.new(self.upload_filepath)
          self.file_upload.resize_list.each do |o|
            img = resize_file img, o[:name], o[:width], o[:height]
          end
          run_gc
        end

        def resize_file(img, name, resize_width, resize_height)
          width = img.columns
          height = img.rows
          ratio = width > height ? resize_width.to_f / width.to_f : resize_height.to_f / height.to_f
          img = img.resize(ratio) if ratio < 1.0
          mkdir(upload_dirpath(name))
          img.write(upload_filepath(name))

          img
        end

      end
    end

    # == Configration options
    #
    # *<tt>message</tt> - message for error (option)
    # *<tt>content_type</tt> - list of allowed content_type (option, default: "jpeg, gif, png")
    #  :content_type => [ "image/jpeg", "image/gif" ]
    #
    # Examples:
    #
    #  validates_image_upload_of :content_type => "image/jpeg"
    #
    def validates_image_upload_of(*attr_names)
      configuration = {
        :message => 'disallowed image format',
        :content_type => [
          "image/png",
          "image/x-png",
          "image/jpeg",
          "image/pjpeg",
          "image/gif"
        ]
      }
      options = attr_names.pop if attr_names.last.is_a?(Hash)
      configuration.update options unless options.blank?
      attr_names.push configuration
      validates_file_upload_of(*attr_names)
    end
  end

  module InstanceMethods

    private
    def fix_jpeg_content_type
      self.content_type = 'image/jpeg' if /^image\/pjpeg/ =~ self.content_type
    end

    def mkdir(dir)
      `mkdir -p "#{dir}"` unless File.exist?(dir)
    end

    def run_gc
      fDisabled = GC.enable
      GC.start
      GC.disable if fDisabled
    end
  end
end

