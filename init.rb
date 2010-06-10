require 'acts_as_file_uploadable'

ActiveRecord::Base.class_eval do 
  include ActsAsFileUploadable
  include ActsAsImageUploadable
end

%w{ models controllers helpers }.each do |dir|
   path = File.join(File.dirname(__FILE__), 'lib', dir)
   $LOAD_PATH << path
   ActiveSupport::Dependencies.load_paths << path
   ActiveSupport::Dependencies.load_once_paths.delete(path)
end 

