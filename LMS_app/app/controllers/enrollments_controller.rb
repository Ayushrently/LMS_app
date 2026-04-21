class EnrollmentsController < ApplicationController
  before_action :set_course

  def create
    @user = User.find_by(id: enrollment_params[:user_id])
    return redirect_back(fallback_location: course_path(@course), alert: "User not found") unless @user
    enrollment = @course.enrollments.build(user: @user, enrolled_at: Time.current)
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
  def enrollment_params
    params.require(:enrollment).permit(:user_id)
  end

  def set_course
    @course = Course.find_by(id:params[:course_id])
  end
end