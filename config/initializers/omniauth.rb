Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, Setting.github["client_id"], Setting.github["client_secret"], scope: "user, repo, gist"
end