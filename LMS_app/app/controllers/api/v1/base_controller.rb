# app/controllers/api/v1/base_controller.rb
module Api
  module V1
    class BaseController < ActionController::API
      # rescue_from StandardError, with: :handle_server_error
      # rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      # rescue_from ActiveRecord::RecordInvalid, with: :handle_invalid

      # private

      # def handle_not_found(exception)
      #   render json: { error: exception.message }, status: :not_found
      # end

      # def handle_invalid(exception)
      #   render json: { errors: exception.record.errors.full_messages }, status: :unprocessable_entity
      # end

      # def handle_server_error(exception)
      #   render json: { error: "Something went wrong on our end" }, status: :internal_server_error
      # end

      def current_user
        @current_user ||= User.find_by( email:"" ) || User.first
      end
    end
  end
end