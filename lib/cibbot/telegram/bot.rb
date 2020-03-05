require 'dotenv'
require 'time'
require_relative 'logging'
require_relative 'telegram_client'
require 'sequel'


class Bot
  include Logging
  include TelegramClient
  Dotenv.load

  DB = if ENV['DATABASE_URL']
    Sequel.connect(ENV['DATABASE_URL'])
  else
    Sequel.sqlite(ENV['DATABASE_DEV'])
  end

  DB.create_table? :users do
    String :username
    String :firstname
    String :lastname
    String :chatid
    Date :start_date
  end

  def run!
    name = 'Cibbe telegram bot'
    Process.setproctitle(name)
    Process.daemon(true, true) unless ENV["DEVELOPMENT"]
    logger.info "Running as '#{name}', pid #{Process.pid}"
    run_telegram_loop
  end

  private

  def mentioned_user(message)
    message.split(':')[0].split('@')[-1]
  end

  def punta_message(message)
    punta = message.split(':').values_at(1..-1).join(" ")
  end

  def handle_message(message)
    # clean up text
    begin 
      text = message.text.to_s.tr("\n", ' ').squeeze(' ').strip
    rescue 
      text = message
    end
      
    case text
    when Telegram::Bot::Types::CallbackQuery
      # Here you can handle your callbacks from inline buttons
      message = text.message.text
      if text.data == 'yes'
        reply_chatid = DB[:users].where(:username=>mentioned_user(message)).get(:chatid)
        send_reply(reply_chatid, "@#{text.from.username} viene a '#{punta_message(message)}'")
        send_message(text.from.id, "Hai avvisato @#{mentioned_user(message)} che vai a '#{punta_message(message)}'")
        edit_message(text.from.id, text.message.message_id, message, nil)
        logger.info "Sending Reply: user=#{text.from.username} text=vado a #{text.message}, uid:#{text.from.id}"
      end
      if text.data == 'no'
        reply_chatid = DB[:users].where(:username=>mentioned_user(message)).get(:chatid)
        send_reply(reply_chatid, "@#{text.from.username} non viene a '#{punta_message(message)}'")
        logger.info "Sending Reply: user=#{text.from.username} text=non vado a #{text.message}, uid:#{text.from.id}"
      end

    # display an help message
    when '', /^\/help/i # /help
      send_help(message)
    when '', /^\/start/i # /start
      chatid = DB[:users].where(:chatid => "#{message.chat.id}").get(:chatid)
      if not chatid
        DB[:users].insert(
          :username => "#{message.from.username}", 
          :firstname => "#{message.from.first_name}", 
          :lastname => "#{message.from.last_name}", 
          :chatid => "#{message.chat.id}", 
          :start_date => "#{Time.now}"
        )
      end
      send_message(message.chat.id, "Ciao #{message.from.first_name}, benvenuto!!")
    when '', /^\/users/i # /users DEBUG
      users = DB[:users]
      send_message(message.chat.id, users.map(:username).join(", "))
    when /^\/punta (.+)/i # /punta
      kb = [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Vado Anche Io', callback_data: 'yes', one_time_keyboard: true),
        # Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Non Vado', callback_data: 'no', one_time_keyboard: true),
      ]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb, one_time_keyboard: true)
      chatids = DB[:users].select(:chatid).all
      for chatid in chatids
        send_message_inline_reply(chatid[:chatid], "from @#{message.from.username}: #{$1}", markup)
      end
    when '/stop'
      # See more: https://core.telegram.org/bots/api#replykeyboardremove
      kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      delete_chatid = DB[:users].where(:chatid=>message.chat.id).delete
      send_message_inline_reply(message.chat.id, 'Sorry to see you go :(', kb)
    end
  end

  def send_help(message)
    send_message(message.from.id, "Usage:\n/punta <descrizione, luogo, orario, link eccetera> - Notifica la tua punta a tutti i cibbers")
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