class LessonsController < ApplicationController
    def new
        @lesson = Lesson.new
    end
end