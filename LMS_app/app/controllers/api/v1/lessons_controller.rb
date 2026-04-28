class Api::V1::LessonsController < Api::V1::BaseController
  
    before_action :set_course
    before_action :ensure_enrolled!, only: [:show]
    before_action :ensure_author_for_course!, only: [:edit, :update]

    def show
        @lesson = Lesson.find_by(id:params[:id])
        render json: {
          lesson: @lesson.as_json(only: [:id, :title, :content]),
        }
    end

    def create
        @lesson = Lesson.new(lessons_params)
        if @lesson.save
            render json: @lesson.as_json(only: [:id, :title, :content]), status: :created
        else
            render json: { errors: @lesson.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def update
        @lesson = @course.lessons.find_by(id:params[:id])

        if @lesson.update(lessons_params)
            render json: @lesson.as_json(only: [:id, :title, :content])
        else
            render json: { errors: @lesson.errors.full_messages }, status: :unprocessable_entity
        end
    end

    private

    def set_course
        @course = Course.find_by(id:params[:course_id])
    end

    def lessons_params
        params.require(:lesson).permit(
            :course_id, :title, :content)
    end

    def ensure_enrolled!
        enrolled = current_user.present? && Enrollment.exists?(user_id: current_user.id, course_id: @course.id)
        render json: { error: "You must be enrolled to view this lesson" }, status: :forbidden unless enrolled
    end

    def ensure_author_for_course!
        render json: { error: "You must be an author to perform this action" }, status: :forbidden unless current_user_author_for?(@course)
    end

end