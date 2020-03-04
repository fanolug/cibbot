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
    Sequel.sqlite('cibbe.sql')
  end

  DB.create_table? :users do
    String :username
    String :firstname
    String :lastname
    String :chatid
    Date :start_date
  end

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
      chatid = DB[:users].where(:chatid => "#{message.chat.id}").get(:chatid)
      if not chatid
        DB[:users].insert(:username => "#{message.from.username}", :firstname => "#{message.from.first_name}", :lastname => "#{message.from.last_name}", :chatid => "#{message.chat.id}", :start_date => "#{Time.now}")
      end
      send_message(message.chat.id, "Ciao #{message.from.first_name}, benvenuto!!")
    when '', /^\/users/i # /users
      users = DB[:users]
      send_message(message.chat.id, users.map(:username).join(", "))
    when /^\/punta (.+)/i # /punta
      chatids = DB[:users].select(:chatid).all
      for chatid in chatids
        send_message(chatid[:chatid], $1)
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