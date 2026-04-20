class AddPositionToLesson < ActiveRecord::Migration[7.0]
  def change
    add_column :lessons, :position, :integer
  end
end
