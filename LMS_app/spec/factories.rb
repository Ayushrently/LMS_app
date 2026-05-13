# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password' }
    password_confirmation { 'password' }

    trait :with_profile do
      after(:create) do |user|
        create(:profile, user: user)
      end
    end
  end

  factory :course do
    title { Faker::Educator.course_name }
    description { Faker::Lorem.paragraph }

    trait :pro do
      tier { 'pro' }
    end

    trait :with_lessons do
      after(:create) do |course|
        create_list(:lesson, 3, course: course)
      end
    end
  end

  factory :enrollment do
    association :user
    association :course
  end

  factory :lesson do
    sequence(:title) { |n| "Lesson #{n}" }
    content { 'This lesson content is long enough to satisfy validation.' }
    association :course
  end

  factory :profile do
    association :user
    bio { Faker::Lorem.sentence }
    sequence(:name) { |n| "name#{n}" }
    sequence(:username) { |n| "user#{n}" }

    trait :pro do
      after(:create) do |profile|
        create(:subscription, profile: profile, plan_name: 'pro')
      end
    end
  end

  factory :subscription do
    association :profile
    plan_name { 'basic' }
  end

  # factory :comment do
  #   association :user
  #   commentable { association :course }
  #   body { Faker::Lorem.paragraph(sentence_count: 2) }
  # end
end
