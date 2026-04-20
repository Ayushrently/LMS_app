class ApplicationController < ActionController::Base
  helper_method :current_user, :current_user_author?, :current_user_author_for?

  CURRENT_USER_FILE = Rails.root.join("tmp", "current_user_id.txt")

  def current_user
    id = File.exist?(CURRENT_USER_FILE) ? File.read(CURRENT_USER_FILE).strip : nil
    return nil if id.blank?

    @current_user ||= User.find_by(id: id)
  end

  def set_current_user(user)
    File.write(CURRENT_USER_FILE, user.id.to_s)
    @current_user = user
  end

  def clear_current_user
    File.delete(CURRENT_USER_FILE) if File.exist?(CURRENT_USER_FILE)
    @current_user = nil
  end

  def current_user_author?
    current_user.present? && current_user.authored_courses.exists?
  end

  def current_user_author_for?(course)
    return false unless current_user.present? && course.present?

    course.authors.exists?(id: current_user.id)
  end
end
