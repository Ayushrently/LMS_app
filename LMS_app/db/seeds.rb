# Seed script for LMS demo data.
# Usage: bin/rails db:seed

puts "Cleaning existing data..."

ActiveAdmin::Comment.delete_all if defined?(ActiveAdmin::Comment)
Comment.delete_all
Enrollment.delete_all
Lesson.delete_all
Course.connection.execute("DELETE FROM courses_users")
Course.delete_all
Subscription.delete_all
Profile.delete_all
User.delete_all
AdminUser.delete_all if defined?(AdminUser)

puts "Creating users, profiles, and subscriptions..."

password = "password123"
role_column_present = User.column_names.include?("role")

author_payloads = [
	{ email: "alice.author@example.com", name: "Alice Writer", username: "alicewriter", bio: "Backend and systems-focused course creator.", plan: "pro" },
	{ email: "bob.author@example.com", name: "Bob Mentor", username: "bobmentor", bio: "Teaches practical coding and debugging.", plan: "pro" },
	{ email: "cara.author@example.com", name: "Cara Builder", username: "carabuilder", bio: "Builds full-stack learning paths for beginners.", plan: "pro" },
	{ email: "dan.author@example.com", name: "Dan Architect", username: "danarchitect", bio: "Designs scalable architecture content.", plan: "basic" },
	{ email: "eva.author@example.com", name: "Eva Coach", username: "evacoach", bio: "Focused on productivity and clean code.", plan: "basic" }
]

student_payloads = [
	{ email: "sam.student@example.com", name: "Sam Learner", username: "samlearner", bio: "Interested in web development basics.", plan: "basic" },
	{ email: "tina.student@example.com", name: "Tina Student", username: "tinastudent", bio: "Learning Ruby and Rails step by step.", plan: "basic" },
	{ email: "umar.student@example.com", name: "Umar Trainee", username: "umartrainee", bio: "Practicing with project-based courses.", plan: "basic" },
	{ email: "vera.student@example.com", name: "Vera Newbie", username: "veranewbie", bio: "Exploring backend fundamentals.", plan: "pro" },
	{ email: "will.student@example.com", name: "Will Rookie", username: "willrookie", bio: "Trying to become a junior developer.", plan: "pro" }
]

authors = author_payloads.map do |payload|
	attrs = {
		email: payload[:email],
		password: password,
		password_confirmation: password
	}
	attrs[:role] = "author" if role_column_present

	user = User.create!(attrs)
	profile = Profile.create!(
		user: user,
		name: payload[:name],
		username: payload[:username],
		bio: payload[:bio]
	)
	Subscription.create!(profile: profile, plan_name: payload[:plan])
	user
end

students = student_payloads.map do |payload|
	attrs = {
		email: payload[:email],
		password: password,
		password_confirmation: password
	}
	attrs[:role] = "student" if role_column_present

	user = User.create!(attrs)
	profile = Profile.create!(
		user: user,
		name: payload[:name],
		username: payload[:username],
		bio: payload[:bio]
	)
	Subscription.create!(profile: profile, plan_name: payload[:plan])
	user
end

puts "Creating courses and lessons..."

course_payloads = [
	{
		title: "Ruby Basics",
		description: "Start your Ruby journey with syntax, control flow, and simple object-oriented patterns.",
		tier: "free",
		creator: authors[0].profile.username,
		primary_author: authors[0],
		collaborators: [authors[1], authors[2]],
		lessons: [
			{ title: "Ruby Intro", content: "Learn Ruby syntax, variables, and conditional logic with practical examples." },
			{ title: "Ruby OOP", content: "Understand classes, objects, and method design while building simple features." }
		]
	},
	{
		title: "Rails Essentials",
		description: "Build and ship a Rails app using MVC, routing, controllers, and Active Record.",
		tier: "pro",
		creator: authors[1].profile.username,
		primary_author: authors[1],
		collaborators: [authors[3]],
		lessons: [
			{ title: "Rails MVC", content: "Understand the Rails request flow and how models, views, and controllers connect." },
			{ title: "Rails Models", content: "Design database-backed models with validations, associations, and query scopes." }
		]
	},
	{
		title: "Testing Rails",
		description: "Write dependable tests for models and controllers to keep your app stable as it grows.",
		tier: "pro",
		creator: authors[2].profile.username,
		primary_author: authors[2],
		collaborators: [authors[0]],
		lessons: [
			{ title: "Model Tests", content: "Create robust model tests with edge cases, validations, and association coverage." },
			{ title: "Ctrl Tests", content: "Test controller behavior and responses to keep application endpoints reliable." }
		]
	},
	{
		title: "API Design",
		description: "Learn to design clear API endpoints with versioning, authentication, and response standards.",
		tier: "free",
		creator: authors[3].profile.username,
		primary_author: authors[3],
		collaborators: [authors[4]],
		lessons: [
			{ title: "API Basics", content: "Define resources, verbs, and status codes to create predictable APIs." },
			{ title: "API Secure", content: "Apply authentication and input validation to keep APIs protected and stable." }
		]
	},
	{
		title: "SQL for Rails",
		description: "Improve Rails performance with SQL fundamentals, indexing strategy, and query analysis.",
		tier: "pro",
		creator: authors[4].profile.username,
		primary_author: authors[4],
		collaborators: [authors[1], authors[2]],
		lessons: [
			{ title: "SQL Intro", content: "Use filtering, sorting, and joins to fetch useful data from relational databases." },
			{ title: "SQL Index", content: "Apply indexing and query planning techniques to improve data access speed." }
		]
	}
]

courses = course_payloads.map do |payload|
	course = Course.create!(
		title: payload[:title],
		description: payload[:description],
		tier: payload[:tier],
		creator: payload[:creator]
	)

	# Adding authors triggers callbacks that also ensure author enrollments.
	course.authors << payload[:primary_author]
	payload[:collaborators].each { |author| course.authors << author }

	# Enforce that every course author is enrolled, even if callbacks are changed/bypassed.
	authors_for_course = [payload[:primary_author], *payload[:collaborators]].uniq
	authors_for_course.each do |author|
		enrollment = Enrollment.find_or_create_by!(user: author, course: course)
		enrollment.update!(enrolled_at: Time.current) if enrollment.enrolled_at.nil?
	end

	payload[:lessons].each do |lesson_attrs|
		Lesson.create!(course: course, title: lesson_attrs[:title], content: lesson_attrs[:content])
	end

	course
end

puts "Creating student enrollments..."

enrollment_map = {
	students[0] => [courses[0], courses[1], courses[3]],
	students[1] => [courses[0], courses[2]],
	students[2] => [courses[1], courses[4]],
	students[3] => [courses[2], courses[3], courses[4]],
	students[4] => [courses[0], courses[4]]
}

enrollment_map.each do |student, selected_courses|
	selected_courses.each do |course|
		Enrollment.find_or_create_by!(user: student, course: course) do |enrollment|
			enrollment.enrolled_at = Time.current
		end
	end
end

puts "Creating comments for activity..."

Comment.create!(user: students[0], commentable: courses[0], body: "This course is clear and very easy to follow.")
Comment.create!(user: students[3], commentable: courses[1], body: "Loved the examples and practical structure in each lesson.")
Comment.create!(user: authors[2], commentable: courses[4], body: "We will add an advanced query optimization module soon.")
Comment.create!(user: students[2], commentable: courses[2].lessons.first, body: "The testing examples helped me understand assertions better.")

AdminUser.create!(email: "admin@example.com", password: "password", password_confirmation: "password")

puts "Seeding complete."
puts "Users: #{User.count} (Authors: #{authors.count}, Students: #{students.count})"
puts "Courses: #{Course.count}, Lessons: #{Lesson.count}, Enrollments: #{Enrollment.count}"