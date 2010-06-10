require 'rubygems'
require 'test_helper'
require 'active_record'
require 'active_record/fixtures'
require 'tempfile'

require "#{File.dirname(__FILE__)}/test_helper"
require "#{File.dirname(__FILE__)}/../init"

# アップロードディレクトリの指定
ActsAsFileUploadable::UPLOADS_DIR = "#{RAILS_ROOT}/uploads/test"

# データベース設定読み込み
ActiveRecord::Base.configurations = {
  "sqlite3" => {
    :adapter => "sqlite3",
    :database => ":memory:"
  }
}.update(YAML::load_file("#{File.dirname(__FILE__)}/../../../../config/database.yml"))

# testデータベースの選択
ActiveRecord::Base.establish_connection(:test)

# スキーマの定義
def build_schema
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Schema.define(:version => 1) do
    create_table :lists, :force => true do |t|
      t.integer :id
    end

    create_table :uploads, :force => true do |t|
      t.integer "list_id"
      t.string  "filename"
      t.string  "content_type"
    end
  end
end

# Modelの定義
class List < ActiveRecord::Base
  has_many :uploads
end

class Upload < ActiveRecord::Base
  belongs_to :list

  acts_as_image_uploads :dir => 'lists'
  validates_image_upload_of :file
end

# テストする前にごにょごにょ
class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures
  include FileUploadableHelper

  # デフォルトのfixturesのパスを書き換える
  self.fixture_path = File.dirname(__FILE__) + "/fixtures/"
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false
  
  build_schema

  fixtures :all
end

# やっとテスト
class ActsAsFileUploadsTest < ActiveSupport::TestCase
  fixtures :uploads

  test "define acts_as_file_uploads" do
    assert_nothing_raised do
      class DefineActsAsFileUploads < ActiveRecord::Base
        set_table_name :uploads
        acts_as_file_uploads :dir => 'uploads'
      end
    end
  end

  test "having instance each other" do
    class FileUploadableModel < ActiveRecord::Base
      set_table_name :uploads
      acts_as_file_uploads :dir => 'uploads'
    end

    class ImageUploadableModel < ActiveRecord::Base
      set_table_name :uploads
      acts_as_image_uploads :dir => 'uploads'
    end
    f = FileUploadableModel.new
    i = ImageUploadableModel.new
    assert_not_equal f.upload_dirpath, i.upload_dirpath
  end

  test "define without dir options" do
    assert_raise ArgumentError do
      class WithoutDir < ActiveRecord::Base
        set_table_name :uploads
        acts_as_image_uploads
      end
    end
  end

  test "define with content_type options" do
    assert_nothing_raised do
      class WithContentType < ActiveRecord::Base
        set_table_name :uploads
        acts_as_image_uploads :dir => 'uploads'
        validates_image_upload_of :file, :content_type => ['images/jpeg']
      end
    end
  end

  test "define with resize_list options" do
    assert_nothing_raised do
      class WithResizeList < ActiveRecord::Base
        set_table_name :uploads
        acts_as_image_uploads :dir => "uploads", :resize_list => [{:name => "mini", :width => 50, :height => 50}]
      end
    end
  end

  test "define with invalid hash resize_list options" do
    assert_raise ArgumentError do
      class WithInvalidHashResizeList < ActiveRecord::Base
        set_table_name :uploads
        acts_as_image_uploads :dir => "uploads", :resize_list => [{:width => 50, :height => 50}]
      end
    end
  end

  test "define with invalid type resize_list options" do
    assert_raise ArgumentError do
      class WithInvalidTypeResizeList < ActiveRecord::Base
        set_table_name :uploads
        acts_as_image_uploads :dir => "uploads", :resize_list => "string"
      end
    end
  end

  test "assign no TempFile to file_field" do
    assert_raise TypeError do
      class NotTempFile < ActiveRecord::Base
        set_table_name :uploads
        acts_as_image_uploads :dir => "uploads"
      end
      
      upload = NotTempFile.new
      upload.file = "string"
    end
  end

  test "assert jpeg image upload" do
    tmp = generate_tempfile(:jpeg)
    assert_difference('Upload.count') do
      upload = Upload.create :file => tmp
    end
  end

  test "assert gif image upload" do
    tmp = generate_tempfile(:gif)
    assert_difference('Upload.count') do
      upload = Upload.create :file => tmp
    end
  end

  test "assert png image upload" do
    tmp = generate_tempfile(:png)
    assert_difference('Upload.count') do
      upload = Upload.create :file => tmp
    end
  end

  test "assert not image upload" do
    tmp = generate_tempfile
    assert_no_difference('Upload.count') do
      upload = Upload.create :file => tmp
    end
  end

  test "define with file_field options" do
    class WithFileField < ActiveRecord::Base
      set_table_name :uploads
      acts_as_image_uploads :dir => :uploads, :file_field => :renamed_file_field
      validates_image_upload_of :renamed_file_field
    end
    tmp = generate_tempfile(:jpeg)
    assert_difference('Upload.count') do
      upload = WithFileField.create :renamed_file_field => tmp
    end
  end
end


