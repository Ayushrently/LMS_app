class CreateSubscriptions < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions do |t|
      t.string :plan_name
      t.date :expires_at
      t.references :profile, null: false, foreign_key: true, index: { unique: true }

      t.timestamps
    end
  end
end
