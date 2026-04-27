class Api::V1::CoursesController < Api::V1::BaseController
  before_action :set_course, only: [:show, :edit, :update, :destroy, :update_authors]

  def index
    available_courses = Course.active.select(:title, :id, :creator, :deleted_at, :tier).order(created_at: :desc).limit(20)
    authored_course_ids = Course.joins(:authors).where(users: { id: current_user.id }).select(:id)
    enrolled_course_ids = Enrollment.where(user_id: current_user.id).select(:course_id)
    @enrolled_courses = Course.where(id: enrolled_course_ids).where.not(id: authored_course_ids).select(:title, :id, :creator, :deleted_at, :tier).order(created_at: :desc)
    @other_courses = available_courses.where.not(id: enrolled_course_ids).where.not(id: authored_course_ids)
    render json: {
      enrolled_courses: @enrolled_courses.as_json(only: [:id, :title, :creator, :deleted_at, :tier]),
      other_courses: @other_courses.as_json(only: [:id, :title, :creator, :deleted_at, :tier])
    }
  end

  def show
    @enrollment = Enrollment.find_by(user_id: current_user&.id, course_id: @course.id)
    @comments = @course.comments.order(created_at: :desc).limit(10)
    render json: {
      course: @course.as_json(only: [:id, :title, :creator, :deleted_at, :tier]),
      enrollment_status: @enrollment.present? ? "enrolled" : "not_enrolled",
      comments: @comments.as_json(only: [:id, :content, :user_id, :created_at])
    }
  end

  def create
    @course = Course.new(course_params)
    @course.creator = current_user.profile.username
    if @course.save
      @course.authors << current_user
      render json: @course.as_json(only: [:id, :title, :creator, :deleted_at, :tier]), status: :created
    else
      render json: { errors: @course.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @course.update(course_params)
      render json: @course.as_json(only: [:id, :title, :creator, :deleted_at, :tier])
    else
      render json: { errors: @course.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def workspace
    @courses = current_user.authored_courses.active.order(updated_at: :desc)
  end

  def destroy
    @course.soft_delete!
    head :no_content
  end

  def update_authors
    creator_username = @course.creator
    parsed_usernames = params[:authors_csv].to_s.split(",").map(&:strip).reject(&:blank?)
    requested_identifiers = ([creator_username] + parsed_usernames).compact.uniq

    users = User.joins(:profile).where(profiles: { username: parsed_usernames }).includes(:profile)
    users_by_username = users.index_by { |user| user.profile.username }
    creator_user = user_from_creator_identifier(creator_username)
    
    ordered_users = parsed_usernames.filter_map { |username| users_by_username[username] }
    ordered_users.unshift(creator_user) if creator_user.present?
    ordered_users.uniq!(&:id)

    current_author_ids = @course.author_ids.sort
    next_author_ids = ordered_users.map(&:id).sort
    authors_updated = current_author_ids != next_author_ids

    @course.authors = ordered_users if authors_updated

    found_identifiers = ordered_users.flat_map { |user| [user.profile&.username, user.profile&.name, user.email] }.compact
    missing_usernames = requested_identifiers - found_identifiers

    if missing_usernames.any?
      render json: { 
        error: "Some users not found", 
        missing: missing_usernames,
        updated: authors_updated 
      }, status: :multi_status
    elsif authors_updated
      render json: { message: "Authors updated successfully" }, status: :ok
    else
      render json: { message: "No author changes were made" }, status: :ok
    end
  end

  private

  def set_course
    @course = Course.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Course not found" }, status: :not_found
  end

  def course_params
    params.require(:course).permit(:title, :description, :tier)
  end

end
