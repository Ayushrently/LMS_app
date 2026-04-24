class RemoveStatusFromCourses < ActiveRecord::Migration[7.0]
  def change
    remove_column :courses, :status, :string
  end
end
