Rails.application.config.after_initialize do
  # NOTE: fetch jwks
  FirebaseIdTokenDecoder.instance
end
