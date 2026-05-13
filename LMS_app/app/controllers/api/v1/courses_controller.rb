# frozen_string_literal: true

module Api
  module V1
    class CoursesController < Api::V1::BaseController
      before_action :set_course, only: %i[show update destroy add_authors remove_authors authors]
      before_action :require_course_author!, only: %i[add_authors remove_authors update destroy]
      before_action -> { doorkeeper_authorize! :course_access }, only: %i[remove_authors update destroy add_authors]

      def index
        available_courses = Course.select(:title, :id, :creator, :deleted_at,
                                          :tier).order(created_at: :desc).limit(20)
        authored_course_ids = Course.joins(:authors).where(users: { id: current_user.id }).select(:id)
        enrolled_course_ids = Enrollment.where(user_id: current_user.id).select(:course_id)
        @enrolled_courses = Course.where(id: enrolled_course_ids).where.not(id: authored_course_ids).select(:title, :id,
                                                                                                            :creator, :deleted_at, :tier).order(created_at: :desc)
        @other_courses = available_courses.where.not(id: enrolled_course_ids).where.not(id: authored_course_ids)
        render json: {
          enrolled_courses: @enrolled_courses.as_json(only: %i[id title creator deleted_at tier]),
          other_courses: @other_courses.as_json(only: %i[id title creator deleted_at tier])
        }
      end

      def show
        @enrollment = Enrollment.find_by(user_id: current_user&.id, course_id: @course.id)
        render json: {
          course: @course.as_json(only: %i[id title creator deleted_at tier]),
          enrollment_status: @enrollment.present? ? 'enrolled' : 'not_enrolled'
        }
      end

      def create
        @course = Course.new(course_params)
        @course.creator = current_user.profile.username
        if @course.save
          @course.authors << current_user
          render json: @course.as_json(only: %i[id title creator deleted_at tier]), status: :created
        else
          render json: { errors: @course.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @course.update(course_params)
          render json: @course.as_json(only: %i[id title creator deleted_at tier])
        else
          render json: { errors: @course.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def workspace
        @courses = current_user.authored_courses.order(updated_at: :desc)
      end

      def destroy
        if @course.soft_delete!
          head :no_content
        else
          render json: { errors: 'Failed to delete course' }, status: :unprocessable_entity
        end
      end

      def add_authors
        parsed_usernames, users_by_username = fetch_and_validate_authors
        return if parsed_usernames.nil?

        existing_author_ids = @course.author_ids
        users_to_add = parsed_usernames.map { |username| users_by_username[username] }
        new_users_to_add = users_to_add.reject { |user| existing_author_ids.include?(user.id) }

        if new_users_to_add.empty?
          render json: { message: 'All provided users are already authors' }, status: :ok
          return
        end

        @course.authors << new_users_to_add

        added_usernames = new_users_to_add.filter_map { |user| user.profile&.username }
        skipped_usernames = parsed_usernames - added_usernames

        response = { message: 'Authors added successfully', added_usernames: added_usernames }
        response[:skipped_existing_usernames] = skipped_usernames if skipped_usernames.any?

        render json: response, status: :ok
      end

      def remove_authors
        creator_username = @course.creator
        parsed_usernames = Array(params[:authors_csv]).map(&:to_s).map(&:strip).compact_blank.uniq

        if parsed_usernames.include?(creator_username)
          render json: { error: 'Creator cannot be removed from authors' }, status: :unprocessable_entity
          return
        end

        parsed_usernames, users_by_username = fetch_and_validate_authors
        return if parsed_usernames.nil?

        users_to_remove = parsed_usernames.map { |username| users_by_username[username] }
        @course.authors.destroy(users_to_remove)
        render json: { message: 'Authors removed successfully' }, status: :ok
      end

      def authors
        @authors = @course.authors.select(:id, :email).map do |author|
          {
            id: author.id,
            email: author.email,
            username: author.profile&.username,
            name: author.profile&.name
          }
        end
        render json: { authors: @authors }
      end

      def search
        @courses = Course.where('title ILIKE ?', "%#{params[:title]}%")
                         .select(:id, :title, :creator, :deleted_at, :tier)
                         .order(created_at: :desc)
        render json: @courses.as_json(only: %i[id title creator deleted_at tier])
      end

      private

      def set_course
        @course = Course.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Course not found' }, status: :not_found
      end

      def course_params
        params.require(:course).permit(:title, :description, :tier)
      end

      def fetch_and_validate_authors
        parsed_usernames = Array(params[:authors_csv]).map(&:to_s).map(&:strip).compact_blank.uniq
        if parsed_usernames.empty?
          render json: { error: 'No valid author usernames provided' }, status: :unprocessable_entity
          return [nil, nil]
        end
        users = User.joins(:profile).where(profiles: { username: parsed_usernames }).includes(:profile)
        users_by_username = users.index_by { |user| user.profile.username }
        missing_usernames = parsed_usernames - users_by_username.keys

        if missing_usernames.any?
          render json: { error: 'Some users not found', missing: missing_usernames }, status: :unprocessable_entity
          return [nil, nil]
        end

        [parsed_usernames, users_by_username]
      end
    end
  end
end
