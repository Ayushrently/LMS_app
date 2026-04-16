class LessonsController < ApplicationController

    before_action :get_course

    def show
        @lesson = Lesson.find(params[:id])
        @comments = @lesson.comments.order(created_at: :desc).limit(10)
        @new_comment = Comment.new
    end

    def new
        @lesson = Lesson.new(
            course_id: params[:course_id],
            position: Lesson.where(course_id: params[:course_id]).count + 1
        )
    end

    def create
        @lesson = Lesson.new(lessons_params)
        if @lesson.save
            redirect_to course_path(@lesson.course_id)
        else
            render :new, status: :unprocessable_entity
        end
    end
    private

    def get_course
        @course = Course.find(params[:course_id])
    end

    def lessons_params
        params.require(:lesson).permit(
            :position, :course_id, :title, :content)
    end
end