class CoursesController < ApplicationController
    def index
        if current_user&.subscription&.plan_name == "pro"
            @courses = Course.select(:title, :id).order(created_at: :desc).limit(10)
        else
            @courses = Course.where(tier: "free").select(:title, :id).order(created_at: :desc).limit(10)
        end
    end

    def new 
        @course = Course.new(tier: "free")
    end

    def create
        @course = Course.new(course_params)
        
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
        @comments = @course.comments.order(created_at: :desc).limit(10)
        @new_comment = Comment.new
    end

    def edit
        @course = Course.find(params[:id])
    end

    def course_params
        params.require(:course).permit(:title, :description, :tier, :status)
    end

end