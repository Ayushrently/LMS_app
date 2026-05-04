require 'rails_helper'

RSpec.describe "Course",type: :request do

  describe "GET /courses" do
    context "authenticated users" do
      let(:user) { create(:user, :with_profile) }

      before { sign_in user }

      it "should show courses index page if user is authenticated and has profile" do
        get courses_path
        expect(response).to have_http_status(:ok)
      end

    end

    context "users not signed in" do
      it "redirects to sign in page if user is not authenticated" do
        get courses_path
        expect(response).to redirect_to(new_user_session_path)
      end
      
      
      context "users signed in" do
        let (:user) do
          User.create!(
            email: "a@gmail.com",
            password: "password",
            password_confirmation: "password"
          )
        end
        
        it "should redirect to complete profile after user creation" do
          sign_in user
  
          get courses_path
          expect(response).to redirect_to(new_user_profile_path(user))
        end
      end
      
    end
  end
  

  
end
