# frozen_string_literal: true

module Api
  module V1
    class LessonsController < Api::V1::BaseController
      before_action :set_course
      before_action :require_course_author!, only: %i[update create]
      before_action :ensure_enrolled!, only: [:show]
      before_action :set_lesson, only: %i[show update]

      def index
        @lessons = @course.lessons.order(created_at: :desc).page(params[:page]).per(params[:per_page] || 20)
        render json: {
          lessons: @lessons.as_json(only: %i[id title]),
          pagination: {
            current_page: @lessons.current_page,
            next_page: @lessons.next_page,
            prev_page: @lessons.prev_page,
            total_pages: @lessons.total_pages,
            total_count: @lessons.total_count
          }
        }
      end

      def show
        render json: {
          lesson: @lesson.as_json(only: %i[id title content])
        }
      end

      def create
        @lesson = @course.lessons.new(lessons_params.except(:course_id))
        if @lesson.save
          render json: @lesson.as_json(only: %i[id title content]), status: :created
        else
          render json: { errors: @lesson.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @lesson.update(lessons_params)
          render json: @lesson.as_json(only: %i[id title content])
        else
          render json: { errors: @lesson.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_course
        @course = Course.find_by(id: params[:course_id])
        render json: { error: 'Course not found' }, status: :not_found unless @course
      end

      def set_lesson
        @lesson = @course.lessons.find_by(id: params[:id])
        render json: { error: 'Lesson not found' }, status: :not_found unless @lesson
      end

      def lessons_params
        params.require(:lesson).permit(
          :course_id, :title, :content
        )
      end

      def ensure_enrolled!
        enrolled = current_user.present? && Enrollment.exists?(user_id: current_user.id, course_id: @course.id)
        render json: { error: 'You must be enrolled to view this lesson' }, status: :forbidden unless enrolled
      end
    end
  end
end
