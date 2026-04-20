class LessonsController < ApplicationController

    before_action :get_course
    before_action :ensure_enrolled!, only: [:show]
    before_action :ensure_author_for_course!, only: [:edit, :update]

    def show
        @lesson = Lesson.find_by(id:params[:id])
        @comments = @lesson.comments.order(created_at: :desc).limit(10)
        @new_comment = Comment.new
    end

    def new
        @lesson = Lesson.new(course_id: params[:course_id])
    end

    def create
        @lesson = Lesson.new(lessons_params)
        if @lesson.save
            redirect_to edit_course_path(@course)
        else
            render :new, status: :unprocessable_entity
        end
    end

    def edit
        @lesson = @course.lessons.find_by(id:params[:id])
    end

    def update
        @lesson = @course.lessons.find_by(id:params[:id])

        if @lesson.update(lessons_params)
            redirect_to edit_course_path(@course)
        else
            render :edit, status: :unprocessable_entity
        end
    end
    private

    def get_course
        @course = Course.find_by(id:params[:course_id])
    end

    def lessons_params
        params.require(:lesson).permit(
            :course_id, :title, :content)
    end

    def ensure_enrolled!
        enrolled = current_user.present? && Enrollment.exists?(user_id: current_user.id, course_id: @course.id)
        redirect_to course_path(@course) unless enrolled
    end

    def ensure_author_for_course!
        redirect_to course_path(@course) unless current_user_author_for?(@course)
    end
end