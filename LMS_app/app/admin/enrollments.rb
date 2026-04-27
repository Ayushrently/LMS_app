ActiveAdmin.register Enrollment do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  preserve_default_filters!

  permit_params :user_id, :course_id, :enrolled_at

  filter :user_email, as: :string, label: "User Email"
  filter :course_title, as: :string, label: "Course Title"
  filter :user_profile_username, as: :string, label: "Username"

  actions :all, except: [:edit, :update]

  form do |f|
    f.inputs "Enrollment Details" do
      f.input :user, as: :select, collection: User.all.map { |u| [u.email, u.id] }
      f.input :course, as: :select, collection: Course.active.map { |c| [c.title, c.id] }
    end
    f.actions
  end

  controller do
    def create
      @enrollment = Enrollment.new(permitted_params[:enrollment])
      @enrollment.enrolled_at ||= Time.current

      if @enrollment.save
        redirect_to admin_enrollment_path(@enrollment), notice: "Enrollment created successfully."
      else
        render :new, alert: @enrollment.errors.full_messages.to_sentence
      end
    end
  end

  action_item :bulk_enroll, only: :index do
    link_to "Bulk Enroll", bulk_enroll_admin_enrollments_path
  end

  collection_action :bulk_enroll, method: :get do
    @courses = Course.active
    render "admin/enrollments/bulk_enroll"
  end

  collection_action :process_bulk_enroll, method: :post do
    course = Course.active.find_by(id: params[:course_id])
    unless course
      redirect_to collection_path, alert: "Course not found or is soft-deleted."
      return
    end

    enrolled_count = 0
    User.find_each do |user|
      unless course.enrollments.exists?(user: user)
        course.enrollments.create(user: user)
        enrolled_count += 1
      end
    end

    redirect_to collection_path, notice: "#{enrolled_count} users enrolled in '#{course.title}'."
  end

  remove_filter :user, :course

end
