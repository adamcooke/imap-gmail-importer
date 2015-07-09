$:.unshift(File.expand_path('../../lib', __FILE__))
require 'bundler/setup'
require 'colorize'
require 'gmail_importer/api'
api = GmailImporter::API.new
if api.test_login
  puts "You have logged in successfully. This script now has access to your Gmail account.".green
else
  puts "Login was not successful. Try again."
end
