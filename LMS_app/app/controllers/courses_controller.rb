class CoursesController < ApplicationController

    def index
        return redirect_to new_user_path unless current_user.present?

        if current_user&.subscription&.plan_name == "pro"
            available_courses = Course.where(status: "published").select(:title, :id, :creator).order(created_at: :desc).limit(10)
        else
            available_courses = Course.where(status: "published",tier: "free").select(:title, :id, :creator).order(created_at: :desc).limit(10)
        end

        enrolled_course_ids = current_user.enrollments.select(:course_id)
        @enrolled_courses = available_courses.where(id: enrolled_course_ids)
        @other_courses = available_courses.where.not(id: enrolled_course_ids)
    end

    def new 
        @course = Course.new(tier: "free")
    end

    def create
        return redirect_to new_user_path unless current_user.present?

        @course = Course.new(course_params)
        @course.creator = current_course_creator
        
        if @course.save
            @course.authors << current_user
            redirect_to edit_course_path(@course)
        else
            render :new, status: :unprocessable_entity
        end
    end

    def update
        @course = Course.find_by( id: params[:id] )

        if @course.update(course_params)
            redirect_to courses_path(@course)
        else
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy
        @course = Course.find_by( id: params[:id] )
        @course.destroy
        redirect_to courses_path
    end

    def show
        @course = Course.find_by( id: params[:id] )
        @enrolled = current_user.present? && Enrollment.exists?(user_id: current_user.id, course_id: @course.id)
        @comments = @course.comments.order(created_at: :desc).limit(10)
        @new_comment = Comment.new
    end

    def workspace
        return redirect_to new_user_path unless current_user.present?

        authored_courses = current_user.authored_courses.order(updated_at: :desc)
        @draft_courses = authored_courses.where(status: "draft")
        @published_courses = authored_courses.where(status: "published")
    end

    def edit
        @course = Course.find_by( id: params[:id] )
        @authors_csv = authors_csv_for(@course)
    end

    def update_authors
        @course = Course.find_by( id: params[:id] )

        creator_username = @course.creator
        parsed_usernames = params[:authors_csv].to_s.split(",").map(&:strip).reject(&:blank?)
        usernames = ([creator_username] + parsed_usernames).compact.uniq

        users = User.joins(:profile).where(profiles: { username: usernames }).includes(:profile)
        users_by_username = users.index_by { |user| user.profile.username }

        ordered_users = usernames.filter_map { |username| users_by_username[username] }
        current_author_ids = @course.author_ids.sort
        next_author_ids = ordered_users.map(&:id).sort
        authors_updated = current_author_ids != next_author_ids

        @course.authors = ordered_users if authors_updated

        missing_usernames = usernames - ordered_users.map { |user| user.profile.username }

        found_msg = "Found users were updated." if authors_updated

        if missing_usernames.any?
            redirect_to edit_course_path(@course), flash: { authors_alert: "Users not found: #{missing_usernames.join(', ')}. #{found_msg}" }
        elsif authors_updated
            redirect_to edit_course_path(@course), flash: { authors_notice: "Authors updated." }
        else
            redirect_to edit_course_path(@course), flash: { authors_notice: "No author changes were made." }
        end
    end

    def course_params
        params.require(:course).permit(:title, :description, :tier, :status)
    end

    def current_course_creator
        current_user.profile&.username || current_user.profile&.name || current_user.email
    end

    def authors_csv_for(course)
        creator_username = course.creator
        author_usernames = course.authors.includes(:profile).map { |author| author.profile&.username }.compact
        ([creator_username] + author_usernames).compact.uniq.join(",")
    end

end