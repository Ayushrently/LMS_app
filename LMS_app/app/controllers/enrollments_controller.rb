class EnrollmentsController < ApplicationController
  before_action :set_course
  before_action :redirect

  def create

    enrollment = @course.enrollments.build(user: current_user, enrolled_at: Time.current)

    if enrollment.save
      redirect_to course_path(@course)
    else
      redirect_to course_path(@course)
    end
  end

  def destroy
  end

  private

  def redirect
    return redirect_to new_user_path unless current_user.present?
  end

  def set_course
    @course = Course.find(params[:course_id])
  end
end