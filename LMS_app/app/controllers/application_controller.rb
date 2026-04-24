class ApplicationController < ActionController::Base
  helper_method :current_user_author?, :current_user_author_for?
  before_action :authenticate_user!, unless: -> { devise_controller? || admin_path?}
  before_action :ensure_profile_completed, if: :profile_completion_required?

  def current_user_author?
    user_signed_in? && current_user.authored_courses.exists?
  end

  def current_user_author_for?(course)
    return false unless current_user.present? && course.present?

    course.authors.exists?(id: current_user.id)
  end

  private

  def profile_completion_required?
    user_signed_in? && !devise_controller?
  end

  def admin_path?
    request.path.start_with?("/admin")
  end

  def ensure_profile_completed
    return if current_user.profile.present?
    return if profile_completion_route?

    redirect_to new_user_profile_path(current_user)
  end

  def profile_completion_route?
    controller_name == "profiles" &&
      %w[new create edit update].include?(action_name) &&
      params[:user_id].to_s == current_user.id.to_s
  end
end
