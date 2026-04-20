class RenameUsernameToEmailInUser < ActiveRecord::Migration[7.0]
  def change
    rename_column :users, :username, :email
    rename_column :profiles, :email, :username
  end
end
