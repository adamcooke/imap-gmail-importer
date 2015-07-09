require 'gmail_importer'
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'
require 'fileutils'

module GmailImporter
  class API

    CLIENT_SECRETS_PATH = File.join(GmailImporter::ROOT, 'client_secrets.json')
    CREDENTIALS_PATH = File.join(GmailImporter::ROOT, 'credentials.json')
    SCOPES = [
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.insert',
      'https://www.googleapis.com/auth/gmail.labels'
    ]

    def authorization
      FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

      file_store = Google::APIClient::FileStore.new(CREDENTIALS_PATH)
      storage = Google::APIClient::Storage.new(file_store)
      auth = storage.authorize

      if auth.nil? || (auth.expired? && auth.refresh_token.nil?)
        app_info = Google::APIClient::ClientSecrets.load(CLIENT_SECRETS_PATH)
        flow = Google::APIClient::InstalledAppFlow.new({
          :client_id => app_info.client_id,
          :client_secret => app_info.client_secret,
          :scope => SCOPES})
        auth = flow.authorize(storage)
        puts "Credentials saved to #{CREDENTIALS_PATH}" unless auth.nil?
      end
      auth
    end

    def client
      @client ||= begin
        client = Google::APIClient.new(:application_name => "IMAP Importer")
        client.authorization = self.authorization
        client
      end
    end

    def gmail_api
      @gmail_api ||= client.discovered_api('gmail', 'v1')
    end

    def test_login
      results = client.execute!(
        :api_method => gmail_api.users.labels.list,
        :parameters => { :userId => 'me' }
      )
      !results.data.labels.empty?
    end

    def message_exists?(message_id)
      result = client.execute!(
        :api_method => gmail_api.users.messages.list,
        :parameters => {:userId => 'me', :q => "rfc822msgid:#{message_id}"}
      )
      !result.data.messages.empty?
    end

    def import_message(message)
      media = Google::APIClient::UploadIO.new(StringIO.new(message), 'message/rfc822')

      begin
        result = client.execute!(
          :api_method => gmail_api.users.messages.import,
          :media => media,
          :parameters => {:userId => 'me', :neverMarkSpam => true, :uploadType => 'media'},
        )
        true
      rescue => e
        puts
        puts "#{e.class}: #{e.message}".red
        puts e.backtrace
        puts
        false
      end
    end

  end
end
