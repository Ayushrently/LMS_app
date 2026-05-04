# LMS App Test Suite Documentation

## Overview

This document provides a comprehensive guide to the test suite for the LMS (Learning Management System) application. The test suite covers all models, web controllers, and API endpoints with extensive mocking of external dependencies.

## Test Structure

### Model Tests (`test/models/`)

All model tests are located in `test/models/` and follow Rails testing conventions.

#### User Model Tests (`user_test.rb`)
- ✅ Associations (profile, comments, enrollments, courses, authored_courses)
- ✅ Devise authentication (creation, validation, encryption)
- ✅ Email uniqueness and validation
- ✅ Profile management and destruction
- ✅ Course enrollment and authorship
- ✅ Comment creation and destruction

#### Course Model Tests (`course_test.rb`)
- ✅ Associations (enrollments, users, lessons, authors, comments)
- ✅ Title and description validations (length, uniqueness)
- ✅ Tier enum (free/pro) and defaults
- ✅ Soft delete functionality
- ✅ Hard delete when no enrollments
- ✅ Author management (add, remove, prevent duplicates)
- ✅ Cascade destruction (lessons, enrollments, comments)

#### Lesson Model Tests (`lesson_test.rb`)
- ✅ Title and content validations
- ✅ Title uniqueness per course
- ✅ Content minimum length validation
- ✅ Whitespace preprocessing callback
- ✅ Comment association and destruction
- ✅ Cascade destruction with course

#### Enrollment Model Tests (`enrollment_test.rb`)
- ✅ User-course association
- ✅ User ID uniqueness per course
- ✅ Multiple course enrollments per user
- ✅ Cascade destruction (user and course)
- ✅ Multiple users per course

#### Comment Model Tests (`comment_test.rb`)
- ✅ Polymorphic association (Course/Lesson)
- ✅ Body length validation (5-1000 chars)
- ✅ User association
- ✅ Cascade destruction on user/commentable deletion
- ✅ Multiple comments per commentable
- ✅ Multiple users commenting

#### Profile Model Tests (`profile_test.rb`)
- ✅ User association
- ✅ Subscription association
- ✅ Name and username validations
- ✅ Username uniqueness
- ✅ Bio maximum length
- ✅ Nested attributes for subscription
- ✅ Cascade destruction

#### Subscription Model Tests (`subscription_test.rb`)
- ✅ Profile association
- ✅ Plan name enum (basic/pro)
- ✅ Plan updates
- ✅ Cascade destruction

#### Admin User Model Tests (`admin_user_test.rb`)
- ✅ Devise authentication
- ✅ Email and password validation
- ✅ Email uniqueness
- ✅ Password encryption

### Web Controller Tests (`test/controllers/`)

Web controller tests use ActionDispatch::IntegrationTest with Devise authentication mocking.

#### Courses Controller Tests (`courses_controller_test.rb`)
- ✅ Authentication requirement
- ✅ Index action (enrolled, authored, other courses)
- ✅ Show action (with enrollment check)
- ✅ Create action (with author assignment)
- ✅ Edit/Update actions (author-only)
- ✅ Destroy action (soft delete)
- ✅ Workspace action (authored courses)
- ✅ Update authors action

#### Lessons Controller Tests (`lessons_controller_test.rb`)
- ✅ Authentication requirement
- ✅ Show action (enrollment required)
- ✅ New/Create actions (author-only)
- ✅ Edit/Update actions (author-only)
- ✅ Authorization checks

#### Enrollments Controller Tests (`enrollments_controller_test.rb`)
- ✅ Create action (free and pro courses)
- ✅ Subscription requirement for pro courses
- ✅ Duplicate enrollment prevention
- ✅ Destroy action (with cascade behavior)
- ✅ Author cannot unenroll

#### Comments Controller Tests (`comments_controller_test.rb`)
- ✅ Create for course and lesson
- ✅ Enrollment requirement for lesson comments
- ✅ Edit/Update (owner-only)
- ✅ Destroy (owner-only)
- ✅ Validation error handling

#### Profiles Controller Tests (`profiles_controller_test.rb`)
- ✅ Show action (redirect if not exists)
- ✅ Create action (with optional subscription)
- ✅ Edit/Update actions (permission-based)
- ✅ Subscription management

#### Users Controller Tests (`users_controller_test.rb`)
- ✅ Show action (redirect to profile)

### API Controller Tests (`test/controllers/api/v1/`)

API controller tests use ActionDispatch::IntegrationTest with mocked Doorkeeper OAuth tokens.

#### API Courses Controller Tests (`courses_controller_test.rb`)
- ✅ Index action (returns courses)
- ✅ Show action (with enrollment status)
- ✅ Create action (requires scope)
- ✅ Update action (author + scope required)
- ✅ Destroy action (soft delete, author-only)
- ✅ Authors action (list course authors)
- ✅ Add authors action
- ✅ Remove authors action
- ✅ Workspace action (authored courses)

#### API Lessons Controller Tests (`lessons_controller_test.rb`)
- ✅ Index action (paginated, enrollment required)
- ✅ Show action (enrollment required)
- ✅ Create action (author-only)
- ✅ Update action (author-only)
- ✅ Validation error handling

#### API Comments Controller Tests (`comments_controller_test.rb`)
- ✅ Create for course and lesson
- ✅ Enrollment requirement
- ✅ Show action
- ✅ Update action (owner-only)
- ✅ Destroy action (owner-only)

#### API Enrollments Controller Tests (`enrollments_controller_test.rb`)
- ✅ Create action (free and pro courses)
- ✅ Subscription validation
- ✅ Duplicate prevention
- ✅ Destroy action
- ✅ Author restrictions

#### API Profiles Controller Tests (`profiles_controller_test.rb`)
- ✅ Show action
- ✅ Create action
- ✅ Update action (permission-based)
- ✅ Subscription management
- ✅ Scope validation

## Mocking and Test Utilities

### Mocked Dependencies

1. **Devise Authentication**
   - Mocked via `Devise::Test::IntegrationHelpers`
   - Sign in users with `sign_in(user)` helper

2. **Doorkeeper OAuth**
   - Mocked access tokens created with `create_oauth_token(user, scopes:)`
   - Doorkeeper authorize mocked with `allow_any_instance_of`

3. **External Services**
   - No real external API calls
   - All tests are isolated and independent

### Test Helper Methods (`test/test_helper.rb`)

Reusable helper methods available in all tests:

#### User Helpers
```ruby
create_test_user(email:, password:, name:, username:)
create_test_users(count = 3)
```

#### Course Helpers
```ruby
create_test_course(title:, description:, tier:, creator:, author:)
create_test_courses(count = 3, author:)
```

#### Lesson Helpers
```ruby
create_test_lesson(course, title:, content:)
create_test_lessons(course, count = 3)
```

#### Enrollment Helpers
```ruby
enroll_user(user, course)
create_enrollments(users, course)
```

#### Comment Helpers
```ruby
create_test_comment(commentable, user, body:)
create_test_comments(commentable, users, count = 1)
```

#### OAuth Helpers
```ruby
create_oauth_token(user, scopes: "public")
```

#### Subscription Helpers
```ruby
create_subscription(user, plan_name: :basic)
```

#### Authorization Helpers
```ruby
add_author_to_course(user, course)
```

#### Assertion Helpers
```ruby
assert_enrolled(user, course)
assert_not_enrolled(user, course)
assert_author_of(user, course)
assert_not_author_of(user, course)
```

## Running Tests

### Run All Tests
```bash
rails test
```

### Run Specific Test File
```bash
rails test test/models/user_test.rb
rails test test/controllers/courses_controller_test.rb
rails test test/controllers/api/v1/courses_controller_test.rb
```

### Run Specific Test
```bash
rails test test/models/user_test.rb:UserTest:test_user_can_be_created_with_valid_email_and_password
```

### Run Tests with Verbose Output
```bash
rails test -v
```

### Run Tests with Parallel Workers
```bash
rails test -w 4
```

### Run Only Model Tests
```bash
rails test test/models/
```

### Run Only Controller Tests
```bash
rails test test/controllers/
```

### Run Only API Tests
```bash
rails test test/controllers/api/
```

## Test Coverage

### Models
- **User**: 19 tests
- **Course**: 29 tests
- **Lesson**: 20 tests
- **Enrollment**: 11 tests
- **Comment**: 20 tests
- **Profile**: 19 tests
- **Subscription**: 8 tests
- **AdminUser**: 8 tests

**Total Model Tests**: 134 tests

### Web Controllers
- **CoursesController**: 16 tests
- **LessonsController**: 12 tests
- **EnrollmentsController**: 11 tests
- **CommentsController**: 18 tests
- **ProfilesController**: 14 tests
- **UsersController**: 3 tests

**Total Web Controller Tests**: 74 tests

### API Controllers
- **Api::V1::CoursesController**: 16 tests
- **Api::V1::LessonsController**: 8 tests
- **Api::V1::CommentsController**: 11 tests
- **Api::V1::EnrollmentsController**: 9 tests
- **Api::V1::ProfilesController**: 12 tests

**Total API Tests**: 56 tests

**Grand Total**: 264+ tests

## Test Coverage Areas

### Positive Cases (Happy Path)
- ✅ Successful CRUD operations
- ✅ Valid data submissions
- ✅ Authorized operations
- ✅ Correct associations

### Negative Cases
- ✅ Invalid data (validation failures)
- ✅ Unauthorized operations
- ✅ Missing required fields
- ✅ Duplicate records
- ✅ Not found errors

### Edge Cases
- ✅ Cascade deletions
- ✅ Soft deletes
- ✅ Multiple associations
- ✅ Scope-based access
- ✅ Role-based authorization

### Authorization Tests
- ✅ Authentication requirements
- ✅ Author-only operations
- ✅ Ownership verification
- ✅ Subscription tier validation
- ✅ Enrollment requirements
- ✅ OAuth scope validation

## Best Practices Used

1. **Isolation**: Each test is independent and doesn't depend on other tests
2. **Fixtures**: All fixtures loaded for each test
3. **Mocking**: External dependencies properly mocked
4. **DRY**: Helper methods reduce code duplication
5. **Descriptive Names**: Test names clearly describe what's being tested
6. **Assertions**: Multiple assertions per test where appropriate
7. **Cleanup**: Proper teardown and cascade deletion handling

## Common Testing Patterns

### Testing Authentication
```ruby
test "should redirect to login when not authenticated" do
  get course_path(@course)
  assert_redirected_to new_user_session_path
end
```

### Testing Authorization
```ruby
test "update requires author permission" do
  other_user = User.create!(...)
  patch course_path(@course), params: { course: { title: "Hacked" } }
  assert_not_equal "Hacked", @course.reload.title
end
```

### Testing API with OAuth
```ruby
test "show returns course details" do
  allow_any_instance_of(Api::V1::BaseController).to receive(:doorkeeper_token).and_return(@token)
  get api_v1_course_path(@course)
  assert_response :ok
end
```

### Testing Validations
```ruby
test "course title must be between 5 and 100 characters" do
  short_course = Course.new(title: "abc", ...)
  assert_not short_course.valid?
  assert short_course.errors[:title].present?
end
```

### Testing Associations
```ruby
test "destroying user destroys profile" do
  user = User.create!(...)
  profile = user.create_profile!(...)
  profile_id = profile.id
  user.destroy
  assert_nil Profile.find_by(id: profile_id)
end
```

## Troubleshooting

### Test Fails with "undefined method"
- Ensure helper methods are defined in `test/test_helper.rb`
- Check that ActiveSupport::TestCase extensions are loaded

### OAuth Tests Fail
- Verify Doorkeeper token is properly mocked
- Check `allow_any_instance_of` is correctly configured
- Ensure token has appropriate scopes

### Devise Authentication Tests Fail
- Verify Devise::Test::IntegrationHelpers is included
- Ensure user is signed in before protected routes
- Check devise_controller? conditions

### Database Tests Fail
- Clear test database: `rails db:test:prepare`
- Check for uniqueness constraints
- Verify fixtures are loaded

## Future Enhancements

1. Add request/response body assertions for API tests
2. Add performance benchmarks
3. Add system tests for critical user workflows
4. Add integration tests for cross-model flows
5. Add API documentation via test examples
6. Add code coverage reporting
