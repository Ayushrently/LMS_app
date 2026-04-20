class CoursesController < ApplicationController
    def index
        if current_user&.subscription&.plan_name == "pro"
            @courses = Course.select(:title, :id, :creator).order(created_at: :desc).limit(10)
        else
            @courses = Course.where(tier: "free").select(:title, :id, :creator).order(created_at: :desc).limit(10)
        end
    end

    def new 
        @course = Course.new(tier: "free")
    end

    def create
        return redirect_to new_user_path unless current_user.present?

        @course = Course.new(course_params)
        @course.creator = current_course_creator
        
        if @course.save
            redirect_to edit_course_path(@course)
        else
            render :new, status: :unprocessable_entity
        end
    end

    def update
        @course = Course.find(params[:id])

        if @course.update(course_params)
            redirect_to courses_path(@course)
        else
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy
        @course = Course.find(params[:id])
        @course.destroy
        redirect_to courses_path
    end

    def show
        @course = Course.find(params[:id])
        @enrolled = current_user.present? && Enrollment.exists?(user_id: current_user.id, course_id: @course.id)
        @comments = @course.comments.order(created_at: :desc).limit(10)
        @new_comment = Comment.new
    end

    def edit
        @course = Course.find(params[:id])
    end

    def course_params
        params.require(:course).permit(:title, :description, :tier, :status)
    end

    def current_course_creator
        current_user.profile&.username || current_user.profile&.name || current_user.email
    end

end