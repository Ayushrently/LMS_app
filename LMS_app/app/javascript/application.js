// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Turbo Drive strips URL fragments on redirects — scroll to anchor manually
document.addEventListener("turbo:load", () => {
  const hash = window.location.hash
  if (hash) {
    const target = document.querySelector(hash)
    if (target) {
      target.scrollIntoView({ behavior: "smooth" })
    }
  }
})
