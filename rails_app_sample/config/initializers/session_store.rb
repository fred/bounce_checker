# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_mail_session',
  :secret      => '1644df72db7fc0feb64277e8ead2f8b1b3f15717036ec9d861809ad80850a30facc1469934603f11d64c3f1e50b9ef415b84104274e5450e03d29692220d8459'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
