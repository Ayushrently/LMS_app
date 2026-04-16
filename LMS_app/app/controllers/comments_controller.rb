class CommentsController < ApplicationController
  before_action :set_commentable

  def create
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @redirect_path
    else
      redirect_to @redirect_path
    end
  end

  private

  def set_commentable
    if params[:lesson_id]
      @course = Course.find(params[:course_id])
      @commentable = @course.lessons.find(params[:lesson_id])
      @redirect_path = course_lesson_path(@course, @commentable)
    else
      @commentable = Course.find(params[:course_id])
      @redirect_path = course_path(@commentable)
    end
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
