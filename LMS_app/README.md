# LMS App

This document explains the recent Courses page API integration and the fix for
the recurring lock error.

## What Was Changed

The web Courses page was updated to read course lists through the API endpoint
instead of directly querying models in the primary path.

- Web endpoint: GET /courses
- API endpoint consumed: GET /api/v1/courses
- Controller updated: app/controllers/courses_controller.rb

Current flow in CoursesController#index:

1. Call fetch_courses_payload (Faraday request to /api/v1/courses)
2. Parse response JSON
3. Build view-ready Course objects with courses_from_api
4. If API fails, rescue and load data with load_courses_from_database

## Why The Previous Approach Failed

Earlier implementation used an internal Rack::MockRequest from inside the same
request cycle. That can cause threading/locking issues under server execution,
including:

- Concurrent::IllegalOperationError: Cannot release a read lock which is not held

To fix this, the internal Rack call was replaced with a normal HTTP call using
Faraday. This avoids re-entering the Rack stack in an unsafe way.

## API Authentication Used

The web controller creates a Doorkeeper access token for the signed-in user
using web_api_access_token and sends it as a Bearer token to the API request.

## Logging Added For Learning And Debugging

CoursesController#index writes a source marker:

- [CoursesController#index] source=api status=success
- [CoursesController#index] source=db_fallback reason=...

This makes it easy to confirm whether page data came from API or fallback DB.

## How To Verify Locally

1. Start server: bundle exec rails s
2. Visit /courses while logged in
3. Check log/development.log
4. Confirm one of the source markers above

Expected behavior:

- API succeeds: page renders from API response
- API fails: page still renders via fallback query and shows alert

## Tests Added/Updated

Request spec file:

- spec/requests/courses_spec.rb

Coverage includes:

- Renders API payload correctly when fetch succeeds
- Falls back to DB query when API fetch raises error

Run:

- bundle exec rspec spec/requests/courses_spec.rb

## Practical Learning Notes

- Prefer real HTTP client calls (Faraday/Net::HTTP) over in-process Rack calls
	when a controller consumes API endpoints.
- Always include fallback behavior for user-facing pages.
- Add clear logs so runtime data source can be verified quickly.
