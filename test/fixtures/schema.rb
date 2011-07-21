ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :uploads, :force => true do |t|
    t.string  "filename"
    t.string  "content_type"
  end
end
