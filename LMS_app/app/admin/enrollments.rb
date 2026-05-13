# frozen_string_literal: true

ActiveAdmin.register Enrollment do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  preserve_default_filters!

  permit_params :user_id, :course_id, :enrolled_at, :username

  filter :user_email, as: :string, label: 'User Email'
  filter :course_title, as: :string, label: 'Course Title'
  filter :user_profile_username, as: :string, label: 'Username'

  actions :all, except: %i[edit update]

  form do |f|
    f.inputs 'Enrollment Details' do
      f.input :username, as: :string, required: true
      f.input :course, as: :select, collection: Course.active.map { |c| [c.title, c.id] }
    end
    f.actions
  end

  controller do
    def destroy
      enrollment = Enrollment.find_by(id: params[:id])
      unless enrollment
        redirect_to collection_path, alert: 'Enrollment not found.'
        return
      end

      if enrolled_user_creator(enrollment)
        redirect_to collection_path, alert: "Cannot remove creator's enrollment."
        return
      end

      unless enrollment.destroy
        redirect_to collection_path,
                    alert: enrollment.errors.full_messages.to_sentence.presence || 'Failed to remove enrollment.'
        return
      end

      redirect_to collection_path, notice: 'Enrollment removed'
    end

    def create
      username = permitted_params[:enrollment][:username]
      user = user_from_username(username)

      unless user
        flash.now[:error] = username.blank? ? "Username can't be blank." : "User '#{username}' not found."
        @enrollment = Enrollment.new
        render :new, status: :unprocessable_entity
        return
      end

      @enrollment = Enrollment.new(
        user_id: user.id,
        course_id: permitted_params[:enrollment][:course_id],
        enrolled_at: Time.current
      )

      if @enrollment.save
        redirect_to admin_enrollment_path(@enrollment), notice: 'Enrollment created successfully.'
      else
        flash.now[:error] = @enrollment.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    private

    def enrolled_user_creator(enrollment)
      return false if enrollment.blank? || enrollment.course.blank? || enrollment.user.blank?

      enrollment.course.creator_identifier_matches?(enrollment.user)
    end

    def user_from_username(username)
      return nil if username.blank?

      User.joins(:profile).find_by('profiles.username = ?', username)
    end
  end

  action_item :bulk_enroll, only: :index do
    link_to 'Bulk Enroll', bulk_enroll_admin_enrollments_path
  end

  collection_action :bulk_enroll, method: :get do
    @courses = Course.active
    render 'admin/enrollments/bulk_enroll'
  end

  batch_action 'Unenroll users', confirm: 'Are you sure you want to unenroll the selected users?' do |ids|
    enrollments = Enrollment.where(id: ids).includes(:course, user: :profile)

    skipped = 0
    to_destroy = enrollments.reject do |enrollment|
      is_creator = enrollment.course.creator_identifier_matches?(enrollment.user)
      skipped += 1 if is_creator
      is_creator
    end

    Enrollment.where(id: to_destroy.map(&:id)).destroy_all

    msg = "#{to_destroy.size} enrollment(s) removed."
    msg += " #{skipped} skipped (course creator cannot be unenrolled)." if skipped.positive?
    redirect_to collection_path, notice: msg
  end

  collection_action :process_bulk_enroll, method: :post do
    course = Course.active.find_by(id: params[:course_id])
    unless course
      redirect_to collection_path, alert: 'Course not found or is soft-deleted.'
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
