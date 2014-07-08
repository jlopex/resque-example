# Imports
RACK_ENV ||= ENV['RACK_ENV'] || 'development'
ENV['RACK_ENV'] = RACK_ENV.to_s

RACK_COUNTRY ||= ENV['COUNTRY'] || 'es'

Dir.glob('{lib/*.rb').each { |file|
  require_relative file
}

# Initialize REDIS

# Initialize

