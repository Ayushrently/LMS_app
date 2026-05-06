ActiveAdmin.register Comment, as: 'UserComment' do
  preserve_default_filters!

  permit_params :body, :user_id, :commentable_type, :commentable_id

  filter :user_email, as: :string, label: 'User Email'
  filter :user_profile_username, as: :string, label: 'Username'
  filter :commentable_type, as: :select, collection: %w[Course Lesson]
  filter :user, as: :select, collection: proc { User.all.pluck(:email, :id) }

  action_item :purge_old_comments, only: :index do
    link_to 'Purge Old Comments', purge_old_admin_user_comments_path,
            method: :delete, data: { confirm: 'Delete all comments older than 6 months?' }
  end

  collection_action :purge_old, method: :delete do
    count = Comment.where('created_at < ?', 6.months.ago).count
    Comment.where('created_at < ?', 6.months.ago).delete_all
    redirect_to collection_path, notice: "#{count} old comments purged."
  end

  remove_filter :user, :body

  form do |f|
    f.inputs 'Comment Details' do
      f.input :user, as: :select, collection: User.joins(:profile).map { |u|
        ["#{u.profile.username} (#{u.email})", u.id]
      }
      f.input :body
      f.input :commentable_type, as: :select, collection: %w[Course Lesson]
      f.input :commentable_id, label: 'Commentable ID'
    end
    f.actions
  end
end
