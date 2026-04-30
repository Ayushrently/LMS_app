class Api::V1::EnrollmentsController < Api::V1::BaseController
    before_action :set_course
    before_action :set_enrollment, only: [:destroy]

    def create
        privileged_user = current_user&.profile&.subscription&.pro? || @course.free?
        unless privileged_user
            render json: { error: "You need a Pro subscription to enroll in this course" }, status: :forbidden
            return
        end

        @enrollment = @course.enrollments.new(user: current_user, enrolled_at: Time.current)
        if @enrollment.save
            render json: { message: "Enrolled successfully" }, status: :created
        else
            render json: { errors: @enrollment.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def destroy
      if @course.creator == current_user.profile.username || @course.authors.exists?(id: current_user.id)
        render json: { error: "Authors cannot unenroll from their own course" }, status: :forbidden
        return
      end

      if @enrollment.destroy
          head :no_content
      else
          render json: { errors: "Failed to unenroll" }, status: :unprocessable_entity
      end
    end

    private

    def set_course
        @course = Course.active.find_by(id: params[:course_id])
        return if @course

        render json: { error: "Course not found" }, status: :not_found
    end

    def set_enrollment
        @enrollment = @course.enrollments.find_by(user_id: current_user&.id)
        return if @enrollment

        render json: { error: "Enrollment not found" }, status: :not_found
    end

end