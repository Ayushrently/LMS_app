class EnrollmentsController < ApplicationController
  before_action :set_course

  def create

    enrollment = @course.enrollments.build(user: current_user, enrolled_at: Time.current)

    if enrollment.save
      redirect_to course_path(@course)
    else
      redirect_to course_path(@course)
    end
  end

  def destroy
    enrollment = @course.enrollments.find_by(user_id: current_user.id)
    if enrollment&.destroy
      redirect_to course_path(@course)
    else
      redirect_to course_path(@course)
    end
  end

  def hello
    render plain: "Hello from EnrollmentsController!"
  end

  private

  def set_course
    @course = Course.find_by(id:params[:course_id])
  end
end