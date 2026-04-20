class DropAuthorsCoursesTable < ActiveRecord::Migration[7.0]
  def change
    drop_table :authors_courses
  end
end
