class CoursesController < ApplicationController do
    def index
        @courses = Course.select(:title, :id).order(created_at: :desc).limit(10)
    end
end