class Api::V1::CommentsController < Api::V1::BaseController 
    before_action :set_course
    before_action :set_comment, only: [:update, :destroy, :show]
    before_action :set_commentable, only: [:create, :show]
    before_action :ensure_author_for_comment!, only: [:update, :destroy]

    def create
        @comment = @commentable.comments.build(comment_params)
        @comment.user = current_user

        if @commentable.is_a?(Lesson) && !Enrollment.exists?(user_id: current_user.id, course_id: @course.id)
          render json: { error: "You must be enrolled in the course to comment on this lesson" }, status: :forbidden
          return
        end

        if @comment.save
            render json: @comment.as_json(only: [:id, :body, :user_id, :commentable_type, :commentable_id]), status: :created
        else
            render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def show
      render json: @comment.as_json(only: [:id, :body, :user_id, :commentable_type, :commentable_id])
    end

    def update
        if @comment.update(comment_params)
            render json: @comment.as_json(only: [:id, :body, :user_id, :commentable_type, :commentable_id])
        else
            render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def destroy
      if @comment.destroy
        head :no_content
      else
        render json: { errors: "Failed to delete comment" }, status: :unprocessable_entity
      end
    end

    private

    def set_comment
        @comment = Comment.find_by(id: params[:id])
        render json: { error: "Comment not found" }, status: :not_found unless @comment
    end

    def ensure_author_for_comment!
        return if @comment.user_id == current_user&.id
        render json: { error: "Not the author of the comment" }, status: :unauthorized
    end

    def set_commentable
        if params[:lesson_id]
            @commentable = @course.lessons.find_by(id: params[:lesson_id])
        else
            @commentable = @course
        end

        render json: { error: "Commentable not found" }, status: :not_found unless @commentable
    end

    def set_course
      @course = Course.find_by(id: params[:course_id])
      render json: { error: "Course not found" }, status: :not_found unless @course
    end

    def comment_params
        params.require(:comment).permit(:body)
    end

end