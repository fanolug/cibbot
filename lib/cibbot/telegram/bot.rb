require 'dotenv'
require 'time'
require_relative 'logging'
require_relative 'telegram_client'
require 'sequel'


class Bot
  include Logging
  include TelegramClient

  DB = if ENV['DATABASE_URL']
    Sequel.connect(ENV['DATABASE_URL'])
  else
    Sequel.sqlite(ENV['DATABASE_DEV']) # in-memory
  end
  DB.execute("CREATE TABLE IF NOT EXISTS users('firstname' char, 'lastname' char, 'username' char, 'chatid' char, 'date' integer)")
  
  def run!
    Dotenv.load
    name = 'Cibbe telegram bot'
    Process.setproctitle(name)
    Process.daemon(true, true) unless ENV["DEVELOPMENT"]
    logger.info "Running as '#{name}', pid #{Process.pid}"
    run_telegram_loop
  end

  private

  def handle_message(message)
    # clean up text
    text = message.text.to_s.tr("\n", ' ').squeeze(' ').strip

    case text
    # display an help message
    when '', /^\/help/i # /help
      send_help(message)
    when '', /^\/start/i # /start
      DB.execute("INSERT INTO users VALUES ('#{message.from.first_name}', '#{message.from.last_name}', '#{message.from.username}', '#{message.chat.id}', '#{Time.now}')")
      send_message(message.chat.id, "Ciao #{message.from.first_name}, benvenuto!!")
    when '', /^\/users/i # /users
      users = DB.execute("SELECT * FROM users")
      users.each do | user |
        send_message(message.chat.id, user.join(" "))
      end
    end
  end

  def send_help(message)
    send_message(message.from.id, "Usage:\n/punta <descrizione, link eccetera> - Notifica la tua punta a tutti i cibbers")
  end

  def validate_message(message, text)
    errors = []

    if result = Twitter::Validation.tweet_invalid?(text)
      errors << "Error: #{result.to_s.tr('_', ' ').capitalize}"
    end

    if message.from.username.to_s.empty?
      errors << "Error: You have to set up your Telegram username first"
    end

    if message.chat.id.to_s != ENV['TELEGRAM_CHAT_ID']
      errors << "Error: Commands from this chat are not allowed"
    end

    if text.to_s.size < 10
      errors << "Error: Message is too short"
    end

    if errors.any?
      error_messages = errors.join("\n")
      logger.warn error_messages
      telegram_client.api.send_message(chat_id: message.from.id, text: error_messages)
    end

    errors.none?
  end

end