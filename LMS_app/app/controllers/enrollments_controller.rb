class EnrollmentsController < ApplicationController
  before_action :set_course

  def create
    enrollment = @course.enrollments.build(user: current_user, enrolled_at: Time.current)
    privileged_user = current_user.profile.subscription&.pro? || @course.free?
    if privileged_user && enrollment.save
      redirect_to course_path(@course), notice: "Successfully enrolled in course."
    elsif !privileged_user
      redirect_to course_path(@course), alert: "You need a Pro subscription to enroll in this course."
    else
      redirect_to course_path(@course), alert: "Unable to enroll. Please try again."
    end
  end

  def destroy
    enrollment = @course.enrollments.find_by(user_id: current_user.id)
    if enrollment&.destroy
      @course.hard_delete_if_no_enrollments! if @course.soft_deleted?
      redirect_to courses_path(@course)
    else
      redirect_to course_path(@course)
    end
  end

  private
  def enrollment_params
    params.require(:enrollment).permit(:user_id)
  end

  def set_course
    @course = Course.find_by(id:params[:course_id])
  end
end