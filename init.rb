require 'acts_as_file_uploadable'
require 'acts_as_image_uploadable'

ActiveRecord::Base.class_eval do 
  include ActsAsFileUploadable
  include ActsAsImageUploadable
end

%w{ models controllers helpers }.each do |dir|
   path = File.join(File.dirname(__FILE__), 'lib', dir)
   $LOAD_PATH << path
   if ActiveSupport::Dependencies.method_defined?(:autoload_paths) 
     # for rails3
     ActiveSupport::Dependencies.autoload_paths << path
   else
     # for rails2
     ActiveSupport::Dependencies.load_paths << path
   end

   if ActiveSupport::Dependencies.method_defined?(:autoload_once_paths)
     # for rails3
     ActiveSupport::Dependencies.autoload_once_paths.delete(path)
   else
     # for rails2
     ActiveSupport::Dependencies.load_once_paths.delete(path)
   end
end 

