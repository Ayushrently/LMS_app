class RemovePositionFromLessons < ActiveRecord::Migration[7.0]
  def change
    remove_column :lessons, :position, :integer
  end
end
