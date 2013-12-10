$: << '.'

EXAMPLES_PATH = File.join(File.dirname(__FILE__), 'examples')

# Load the testing libraries
require 'rubygems'
require 'rspec'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

# Load the Sinatra app
require 'appconverter-server.rb'

# Make Rack::Test available to all spec contexts
RSpec.configure do |conf|
    conf.include Rack::Test::Methods
end


# Add an app method for RSpec
def app
    Sinatra::Application
end
