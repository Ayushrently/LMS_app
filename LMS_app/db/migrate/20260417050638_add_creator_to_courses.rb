class AddCreatorToCourses < ActiveRecord::Migration[7.0]
  def change
    add_column :courses, :creator, :string
  end
end
