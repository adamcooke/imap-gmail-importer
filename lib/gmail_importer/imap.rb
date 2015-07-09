require 'json'
require 'logger'
require 'net/imap'

module GmailImporter
  module IMAP

    def self.config
      @config ||= JSON.parse(File.read(File.join(GmailImporter::ROOT, "mailbox.json")))
    end

    def self.connection
      @connection ||= begin
        conn = Net::IMAP.new(config['host'], config['port'], config['ssl'])
        conn.login(config['username'], config['password'])
        conn
      end
    end

  end
end
