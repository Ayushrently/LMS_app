ActiveAdmin.register Course do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  preserve_default_filters!

  permit_params :title, :description, :tier, :creator
  #
  # or
  #
  # permit_params do
  #   permitted = [:title, :description, :tier, :creator]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  filter :title
  # filter :authors_email, as: :string, label: "Creator Email"
  filter :authors_profile_username, as: :string, label: 'Creator Username'
  # filter :tier, as: :select, collection: Course.tiers.keys

  # Disable default destroy — courses must go through soft_delete!
  actions :all, except: [:destroy]

  # scope :all, default: true
  scope :all
  scope :active, -> { where(deleted_at: nil) }
  scope :soft_deleted, -> { where.not(deleted_at: nil) }

  batch_action :destroy, false

  batch_action :soft_delete, confirm: 'Soft delete selected courses?' do |ids|
    Course.where(id: ids).each(&:soft_delete!)
    redirect_to collection_path, notice: 'Selected courses have been soft deleted.'
  end

  batch_action :hard_delete, confirm: 'Course will be deleted for all' do |ids|
    Course.transaction do
      Course.where(id: ids).find_each(&:destroy!)
    end
    redirect_to collection_path, notice: 'Selected courses have been permanently deleted.'
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to collection_path, alert: "Hard delete failed: #{e.record.errors.full_messages.to_sentence}"
  end

  batch_action :restore, confirm: 'Restore selected courses?' do |ids|
    Course.where(id: ids).each do |course|
      course.update!(deleted_at: nil)
      creator = User.find_by(id: course.creator)
      course.authors << creator if creator && !course.authors.include?(creator)
    end
    redirect_to collection_path, notice: 'Selected courses have been restored.'
  end

  index do
    selectable_column
    id_column
    column :title
    column :tier
    column :creator
    column :deleted_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :title
      row :description
      row :tier
      row :creator
      row :deleted_at
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end

  action_item :soft_delete, only: :show do
    unless resource.soft_deleted?
      link_to 'Soft Delete', soft_delete_admin_course_path(resource), method: :put,
                                                                      data: { confirm: 'Soft delete this course?' }
    end
  end

  member_action :soft_delete, method: :put do
    resource.soft_delete!
    redirect_to admin_courses_path, notice: 'Course soft deleted.'
  end

  remove_filter :enrollments, :comments, :lessons, :users, :authors, :creator

  form do |f|
    f.inputs 'Course Details' do
      f.input :title
      f.input :description
      f.input :tier, as: :select, collection: Course.tiers.keys
      f.input :creator, required: true
    end
    f.actions
  end

  controller do
    def create
      @course = Course.new(permitted_params[:course])
      creator_user = user_from_creator_identifier(@course.creator)

      unless creator_user
        @course.errors.add(:creator, 'must be an existing user (username, name, or email)')
        return render :new, status: :unprocessable_entity
      end

      if @course.save
        @course.authors << creator_user
        redirect_to show_admin_course_path(@course), notice: 'Course created successfully.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def user_from_creator_identifier(identifier)
      return nil if identifier.blank?

      User
        .joins(:profile)
        .includes(:profile)
        .find_by('profiles.username = :value OR profiles.name = :value OR users.email = :value', value: identifier)
    end
  end
end
