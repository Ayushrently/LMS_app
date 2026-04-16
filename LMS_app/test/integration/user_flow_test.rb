require "test_helper"

class UserFlowTest < ActionDispatch::IntegrationTest
  test "temporary login creates and updates profile with subscription" do
    post users_path, params: {
      user: {
        email: "learner@example.com",
        role: "student"
      }
    }

    user = User.find_by(email: "learner@example.com")

    assert_redirected_to new_user_profile_path(user)
    follow_redirect!
    assert_response :success

    post user_profile_path(user), params: {
      profile: {
        name: "Learner One",
        username: "learner01",
        bio: "Starting profile",
        subscription_attributes: {
          plan_name: "Basic",
          expires_at: Date.new(2026, 12, 31)
        }
      }
    }

    assert_redirected_to user_path(user)
    follow_redirect!
    assert_response :success
    assert_match "Learner One", response.body
    assert_match "Basic", response.body

    patch user_profile_path(user), params: {
      profile: {
        name: "Learner Updated",
        username: "learner01",
        bio: "Updated profile",
        subscription_attributes: {
          id: user.subscription.id,
          plan_name: "Pro",
          expires_at: Date.new(2027, 1, 31)
        }
      }
    }

    assert_redirected_to user_path(user)
    follow_redirect!
    assert_match "Learner Updated", response.body
    assert_match "Pro", response.body
  end
end