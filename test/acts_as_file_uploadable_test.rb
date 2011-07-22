require 'rubygems'
require 'test_helper'
require 'active_record'
require 'active_record/fixtures'

require "#{File.dirname(__FILE__)}/../init"
require "#{File.dirname(__FILE__)}/test_helper"

ActiveRecord::Base.establish_connection({ :adapter => "sqlite3", :database => ":memory:" })

# Modelの定義
class Upload < ActiveRecord::Base
  acts_as_file_uploads :dir => 'uploads'
  validates_file_upload_of :file
end
class Image < ActiveRecord::Base
  acts_as_image_uploads :dir => 'uploads'
  validates_image_upload_of :file
end

class ActsAsFileUploadsTest < Test::Unit::TestCase
  def setup
    load(File.dirname(__FILE__) + "/fixtures/schema.rb")
    Fixtures.create_fixtures(File.dirname(__FILE__) + "/fixtures/", :uploads)
  end

  def test_define_acts_as_file_uploads
    assert_nothing_raised do
      Class.new(ActiveRecord::Base) do
        set_table_name :uploads
        acts_as_file_uploads :dir => 'uploads'
      end
    end
  end

  def test_define_acts_as_image_uploads
    assert_nothing_raised do
      Class.new(ActiveRecord::Base) do
        set_table_name :uploads
        acts_as_image_uploads :dir => 'uploads'
      end
    end
  end

  def test_define_without_dir_options
    assert_raise ArgumentError do
      Class.new(ActiveRecord::Base) do
        set_table_name :uploads
        acts_as_image_uploads
      end
    end
  end

  def test_define_with_content_type_options
    assert_nothing_raised do
      Class.new(ActiveRecord::Base) do
        set_table_name :uploads
        acts_as_image_uploads :dir => 'uploads'
        validates_image_upload_of :file, :content_type => ['images/jpeg']
      end
    end
  end

  def test_define_with_resize_list_options
    assert_nothing_raised do
      Class.new(ActiveRecord::Base) do
        set_table_name :uploads
        acts_as_image_uploads :dir => "uploads", :resize_list => [{:name => "mini", :width => 50, :height => 50}]
      end
    end
  end

  def test_define_with_invalid_hash_resize_list_options
    assert_raise ArgumentError do
      Class.new(ActiveRecord::Base) do
        set_table_name :uploads
        acts_as_image_uploads :dir => "uploads", :resize_list => [{:width => 50, :height => 50}]
      end
    end
  end

  def test_define_with_invalid_type_resize_list_options
    assert_raise ArgumentError do
      Class.new(ActiveRecord::Base) do
        set_table_name :uploads
        acts_as_image_uploads :dir => "uploads", :resize_list => "string"
      end
    end
  end

  def test_assign_no_TempFile_to_file_field
    assert_raise TypeError do
      not_tmp_file = Class.new(ActiveRecord::Base) do
        set_table_name :uploads
        acts_as_image_uploads :dir => "uploads"
      end

      upload = not_tmp_file.new
      upload.file = "string"
    end
  end

  def test_assert_file_upload
    tmp = generate_tempfile(:jpeg)
    assert Upload.create(:file => tmp).errors.blank?
  end

  def test_assert_jpeg_image_upload
    tmp = generate_tempfile(:jpeg)
    assert Image.create(:file => tmp).errors.blank?
  end

  def test_assert_not_image_upload
    tmp = generate_tempfile(:text)
    assert !Image.create(:file => tmp).errors.blank?
  end

  def test_assert_upload_methods
    tmp = generate_tempfile(:text)
    upload = Upload.create(:file => tmp)
    assert_not_nil upload.upload_filepath
    assert_not_nil upload.upload_dirpath
    assert_not_nil upload.file_exist?
    assert_not_nil upload.upload_tempfile?
  end

  def test_assert_image_methods
    tmp = generate_tempfile(:jpeg)
    image = Image.create(:file => tmp)
    assert_not_nil image.upload_filepath
    assert_not_nil image.upload_dirpath
    assert_not_nil image.file_exist?
    assert_not_nil image.image_exist?
    assert_not_nil image.upload_tempfile?
    assert_not_nil image.width
    assert_not_nil image.height
  end

  def test_define_with_file_field_options
    with_file_field = Class.new(ActiveRecord::Base) do
      set_table_name :uploads
      acts_as_image_uploads :dir => :uploads, :file_field => :renamed_file_field
      validates_image_upload_of :renamed_file_field
    end
    tmp = generate_tempfile(:jpeg)
    assert with_file_field.create(:renamed_file_field => tmp).errors.blank?
  end
end


