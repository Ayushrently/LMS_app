class CommentsController < ApplicationController
  before_action :set_commentable, except: [:edit, :update, :destroy]
  before_action :set_comment, only: [:edit, :update, :destroy]
  before_action :authorize_user, only: [:edit, :update, :destroy]

  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @redirect_path, notice: "Comment added successfully."
    else
      flash[:comment_error] = @comment.errors.full_messages.join(", ")
      redirect_to @redirect_path
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      if @comment.commentable_type == "Lesson"
        redirect_to course_lesson_path(@comment.commentable.course, @comment.commentable, anchor: "comments-section"), notice: "Comment updated successfully."
      else
        redirect_to course_path(@comment.commentable, anchor: "comments-section"), notice: "Comment updated successfully."
      end
    else
      render :edit
    end
  end

  def destroy
    if @comment.destroy
      if @comment.commentable_type == "Lesson"
        redirect_to course_lesson_path(@comment.commentable.course, @comment.commentable, anchor: "comments-section"), notice: "Comment deleted successfully."
      else
        redirect_to course_path(@comment.commentable, anchor: "comments-section"), notice: "Comment deleted successfully."
      end
    end
  end

  private

  def set_comment
    @comment = Comment.find_by( id:params[:id] )
  end

  def authorize_user
    return if @comment.user_id == current_user&.id
    redirect_to root_path
  end

  def set_commentable
    if params[:lesson_id]
      @course = Course.find_by(id: params[:course_id] )
      @commentable = @course.lessons.find_by( id: params[:lesson_id] )
      @redirect_path = course_lesson_path(@course, @commentable, anchor: "comments-section")
    else
      @commentable = Course.find_by(id: params[:course_id] )
      @redirect_path = course_path(@commentable, anchor: "comments-section")
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
