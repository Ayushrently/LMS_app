ActiveAdmin.register Course do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
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
  filter :created_at
  filter :price
  filter :deleted_at

  scope :all, default: true
  scope :active, -> { where(deleted_at: nil) }
  scope :soft_deleted, -> { where.not(deleted_at: nil) }

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
    link_to "Soft Delete", soft_delete_admin_course_path(resource), method: :put, data: { confirm: "Soft delete this course?" } unless resource.soft_deleted?
  end

  member_action :soft_delete, method: :put do
    resource.soft_delete!
    redirect_to admin_courses_path, notice: "Course soft deleted."
  end

end
