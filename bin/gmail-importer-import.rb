$:.unshift(File.expand_path('../../lib', __FILE__))
require 'bundler/setup'
require 'colorize'
require 'gmail_importer/api'
require 'gmail_importer/imap'
require 'mail'

begin
  trap("INT") {
    puts "Exiting..."
    $exit = true
  }

  api = GmailImporter::API.new
  imap = GmailImporter::IMAP.connection
  imap.select(GmailImporter::IMAP.config['folder'])

  ids_file_path = File.join(GmailImporter::ROOT, 'imported_ids.txt')
  if File.exists?(ids_file_path)
    imported_ids = File.read(ids_file_path).split("\n")
  else
    imported_ids = []
  end

  ids_file = File.open(ids_file_path, 'a')

  ids = imap.search(['ALL']).reverse
  if ids.empty?
    puts "There are no messages in the folder.".red
  else
    ids.each do |message_id|
      message = imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
      mail = Mail.new(message)

      if imported_ids.include?(mail.message_id)
        puts "Message #{mail.message_id} already exists (locally)".yellow
        next
      end

      if api.message_exists?(mail.message_id)
        puts "Message #{mail.message_id} already exists.".yellow
        ids_file.puts(mail.message_id)
        ids_file.flush
      else
        puts "Message #{mail.message_id} does not exist.".green
        if api.import_message(message)
          puts " --> Imported OK".green
          unless imported_ids.include?(mail.message_id)
            ids_file.puts(mail.message_id)
            ids_file.flush
          end
        else
          puts " --> Failed to import".red
        end
      end

      if $exit
        Process.exit
      end
    end
  end
ensure
  GmailImporter::IMAP.connection.disconnect
end



