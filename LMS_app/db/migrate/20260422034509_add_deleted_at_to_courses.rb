class AddDeletedAtToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :deleted_at, :datetime
    add_index :courses, :deleted_at
  end
end
