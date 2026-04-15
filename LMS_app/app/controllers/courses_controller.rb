class CoursesController < ApplicationController
    def index
        @courses = Course.select(:title, :id).order(created_at: :desc).limit(10)
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

        if Course.update(course_params)
            redirect_to edit_course_path(@course)
        else
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy

    end

    def edit
        @course = Course.find(params[:id])
    end

    def course_params
        params.require(:course).permit(:title, :description, :tier, :status)
    end

end