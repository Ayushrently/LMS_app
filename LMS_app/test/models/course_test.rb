require "test_helper"

class CourseTest < ActiveSupport::TestCase
  test "adding an author automatically enrolls them in the course" do
    course = Course.create!(
      title: "Ruby on Rails Basics",
      description: "A complete beginner guide for learning Rails fundamentals.",
      tier: "free",
      creator: "creator_user"
    )
    author = User.create!(email: "author@example.com", password: "password123")
    author.create_profile!(name: "Author User", username: "author_user")

    assert_difference("Enrollment.count", 1) do
      course.authors << author
    end

    assert Enrollment.exists?(user: author, course: course)
  end

  test "removing an author also removes their enrollment from the course" do
    course = Course.create!(
      title: "Rails Associations Deep Dive",
      description: "Detailed coverage of Rails associations and lifecycle callbacks.",
      tier: "free",
      creator: "creator_user"
    )
    author = User.create!(email: "removed_author@example.com", password: "password123")
    author.create_profile!(name: "Removed Author", username: "removed_author")

    course.authors << author
    assert Enrollment.exists?(user: author, course: course)

    assert_difference("Enrollment.count", -1) do
      course.authors.delete(author)
    end

    assert_not Enrollment.exists?(user: author, course: course)
    assert_not_includes course.authors.reload, author
  end

  test "course creator cannot be removed from course authors" do
    creator = User.create!(email: "creator@example.com", password: "password123")
    creator.create_profile!(name: "Creator User", username: "creator_user")
    course = Course.create!(
      title: "Advanced Rails Patterns",
      description: "Patterns and practices for building maintainable Rails apps.",
      tier: "pro",
      creator: "creator_user"
    )

    course.authors << creator

    assert_no_difference("course.authors.reload.count") do
      course.authors.delete(creator)
    end

    assert_includes course.errors[:authors], "cannot remove course creator"
    assert_includes course.authors.reload, creator
  end
end
