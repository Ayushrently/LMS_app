# frozen_string_literal: true

# Seed script for LMS demo data.
# Usage: bin/rails db:seed

require 'faker'

Faker::Config.random = Random.new(42)

Rails.logger.debug 'Cleaning existing data...'

ActiveAdmin::Comment.delete_all if defined?(ActiveAdmin::Comment)
Comment.delete_all
Enrollment.delete_all
Lesson.delete_all
Course.connection.execute('DELETE FROM courses_users')
Course.delete_all
Subscription.delete_all
Profile.delete_all
User.delete_all
AdminUser.delete_all if defined?(AdminUser)

Rails.logger.debug 'Creating users, profiles, and subscriptions...'

AUTHOR_COUNT = 12
STUDENT_COUNT = 30
COURSE_COUNT = 18
LESSONS_PER_COURSE = 4
COMMENTS_COUNT = 80
MIN_STUDENT_COURSES = 3
MAX_STUDENT_COURSES = 6
PASSWORD = 'password123'

clamp_text = lambda do |text, min:, max:|
  cleaned = text.to_s.gsub(/\s+/, ' ').strip
  cleaned = cleaned[0, max] if cleaned.length > max
  cleaned = cleaned.ljust(min, 'x') if cleaned.length < min
  cleaned
end

used_usernames = Set.new
next_username = lambda do |seed_text|
  base = seed_text.to_s.downcase.gsub(/[^a-z0-9]/, '')[0, 16]
  base = "user#{Faker::Config.random.rand(1000..9999)}" if base.length < 3

  candidate = base
  suffix = 1
  while used_usernames.include?(candidate)
    suffix_str = suffix.to_s
    candidate = "#{base[0, 20 - suffix_str.length]}#{suffix_str}"
    suffix += 1
  end

  used_usernames << candidate
  candidate
end

build_people_payload = lambda do |kind, count:|
  Array.new(count) do |idx|
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
    name = clamp_text.call("#{first_name} #{last_name[0]}", min: 3, max: 20)
    username = next_username.call("#{first_name}#{last_name}#{kind}#{idx}")
    email = "#{username}.#{kind}@example.com"
    bio = clamp_text.call(Faker::Lorem.paragraph(sentence_count: 2), min: 20, max: 500)
    plan = %w[basic pro].sample(random: Faker::Config.random)

    {
      email: email,
      name: name,
      username: username,
      bio: bio,
      plan: plan
    }
  end
end

author_payloads = build_people_payload.call('author', count: AUTHOR_COUNT)
student_payloads = build_people_payload.call('student', count: STUDENT_COUNT)

# 1) Users
author_users = author_payloads.map do |payload|
  User.create!(
    email: payload[:email],
    password: PASSWORD,
    password_confirmation: PASSWORD
  )
end

student_users = student_payloads.map do |payload|
  User.create!(
    email: payload[:email],
    password: PASSWORD,
    password_confirmation: PASSWORD
  )
end

# 2) Profiles
author_profiles = author_users.zip(author_payloads).map do |user, payload|
  Profile.create!(
    user: user,
    name: payload[:name],
    username: payload[:username],
    bio: payload[:bio]
  )
end

student_profiles = student_users.zip(student_payloads).map do |user, payload|
  Profile.create!(
    user: user,
    name: payload[:name],
    username: payload[:username],
    bio: payload[:bio]
  )
end

# 3) Subscriptions
author_profiles.zip(author_payloads).each do |profile, payload|
  Subscription.create!(profile: profile, plan_name: payload[:plan])
end

student_profiles.zip(student_payloads).each do |profile, payload|
  Subscription.create!(profile: profile, plan_name: payload[:plan])
end

authors = author_users
students = student_users

Rails.logger.debug 'Creating courses, lessons, and enrollments...'

used_course_titles = Set.new
next_course_title = lambda do
  20.times do
    raw = Faker::Educator.course_name
    normalized = clamp_text.call(raw, min: 5, max: 100)
    key = normalized.downcase
    next if used_course_titles.include?(key)

    used_course_titles << key
    return normalized
  end

  fallback = "Course #{used_course_titles.size + 1}"
  used_course_titles << fallback.downcase
  fallback
end

courses = Array.new(COURSE_COUNT).map do
  primary_author = authors.sample(random: Faker::Config.random)
  collaborator_count = Faker::Config.random.rand(1..2)
  collaborators = authors.sample(collaborator_count, random: Faker::Config.random)
  authors_for_course = ([primary_author] + collaborators).uniq

  course = Course.create!(
    title: next_course_title.call,
    description: clamp_text.call(Faker::Lorem.paragraph(sentence_count: 4), min: 10, max: 600),
    tier: %w[free pro].sample(random: Faker::Config.random),
    creator: primary_author.profile.username
  )

  # Deduped insert prevents duplicate rows in courses_users.
  authors_for_course.each do |author|
    course.authors << author
    # Enforce that every course author is enrolled, even if callbacks are changed/bypassed.
    enrollment = Enrollment.find_or_create_by!(user: author, course: course)
    enrollment.update!(enrolled_at: Time.current) if enrollment.enrolled_at.nil?
  end

  used_lesson_titles = Set.new
  LESSONS_PER_COURSE.times do
    lesson_title = nil

    20.times do
      raw_title = "#{Faker::Verb.base.capitalize} #{Faker::ProgrammingLanguage.name}".gsub(/[^a-zA-Z0-9 ]/, '')
      candidate = clamp_text.call(raw_title, min: 5, max: 20)
      next if used_lesson_titles.include?(candidate.downcase)

      lesson_title = candidate
      used_lesson_titles << candidate.downcase
      break
    end

    lesson_title ||= "Lesson#{used_lesson_titles.size + 1}"

    Lesson.create!(
      course: course,
      title: lesson_title,
      content: clamp_text.call(Faker::Lorem.paragraph(sentence_count: 3), min: 20, max: 1000)
    )
  end

  course
end

Rails.logger.debug 'Creating student enrollments...'

students.each do |student|
  selected_courses = courses.sample(Faker::Config.random.rand(MIN_STUDENT_COURSES..MAX_STUDENT_COURSES), random: Faker::Config.random)
  selected_courses.each do |course|
    enrollment = Enrollment.find_or_create_by!(user: student, course: course)
    enrollment.update!(enrolled_at: Time.current) if enrollment.enrolled_at.nil?
  end
end

Rails.logger.debug 'Creating comments for activity...'

comment_targets = courses + courses.flat_map(&:lessons)
comment_authors = authors + students

COMMENTS_COUNT.times do
  Comment.create!(
    user: comment_authors.sample(random: Faker::Config.random),
    commentable: comment_targets.sample(random: Faker::Config.random),
    body: clamp_text.call(Faker::Lorem.sentence(word_count: 14), min: 5, max: 1000)
  )
end

AdminUser.create!(
  email: 'admin@example.com',
  password: 'password123',
  password_confirmation: 'password123'
)

Rails.logger.debug 'Seeding complete.'
Rails.logger.debug { "Users: #{User.count} (Authors: #{authors.count}, Students: #{students.count})" }
Rails.logger.debug { "Profiles: #{Profile.count}, Subscriptions: #{Subscription.count}" }
Rails.logger.debug do
  "Courses: #{Course.count}, Lessons: #{Lesson.count}, Enrollments: #{Enrollment.count}, Comments: #{Comment.count}"
end
