# frozen_string_literal: true

# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ActionController::API
      rescue_from StandardError, with: :handle_server_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid
      rescue_from ActiveRecord::RecordNotFound, with: :bad_request
      rescue_from ArgumentError, with: :handle_argument_error

      before_action :doorkeeper_authorize!

      private

      def bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end

      def handle_argument_error(exception)
        render json: { error: exception.message }, status: :unprocessable_entity
      end

      def handle_not_found(exception)
        render json: { error: exception.message }, status: :not_found
      end

      def handle_invalid(exception)
        render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
      end

      def handle_server_error(_exception)
        render json: { error: 'Something went wrong on our end' }, status: :internal_server_error
      end

      def current_user
        current_resource_owner
      end

      def require_course_author!
        authorized = current_user.present? && @course.present? && @course.authors.exists?(id: current_user.id)
        render json: { error: 'You must be an author to perform this action' }, status: :forbidden unless authorized
        authorized
      end

      def current_resource_owner
        User.find_by(id: doorkeeper_token&.resource_owner_id) if doorkeeper_token
      end
    end
  end
end
