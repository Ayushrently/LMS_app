class RemoveExpiresAtFromSubscriptions < ActiveRecord::Migration[7.0]
  def change
    remove_column :subscriptions, :expires_at, :datetime
  end
end
