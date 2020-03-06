require 'dotenv'
require 'time'
require_relative 'logging'
require_relative 'telegram_client'
require 'sequel'


class Bot
  include Logging
  include TelegramClient
  
  def initialize 
    Dotenv.load
    
    @DB = if ENV['DATABASE_URL']
      Sequel.connect(ENV['DATABASE_URL'])
    else
      Sequel.sqlite(ENV['DATABASE_DEV'])
    end
  
    @DB.create_table? :users do
      String :username
      String :firstname
      String :lastname
      String :chatid
      Date :start_date
    end
    
    # unicode emoji
    @sos = "\u{1F198}"
    @info = "\u{2139}"
    @pushpin = "\u{1F4CD}"
    @calendar = "\u{1F4C5}"
    @check = "\u{2705}"
    @uncheck = "\u{274C}"
    @cry = "\u{1F622}"
    @lovehornsgesture = "\u{1F91F}"
    @callmegesture = "\u{1F919}"
    @likegesture = "\u{1F44D}"

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
    message.split(':')[0].split('@')[-1].strip
  end

  def punta_message(message)
    punta = message.split(':').values_at(1..-1).join(" ").strip
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
        reply_chatid = @DB[:users].where(:username=>mentioned_user(message)).get(:chatid)
        send_message(text.from.id, "[reply-confirm] Hai confermato a @#{mentioned_user(message)} che vai a #{punta_message(message)} #@check #@callmegesture")
        send_reply(reply_chatid, "[reply] @#{text.from.username} viene a #{punta_message(message)} #@check #@lovehornsgesture")
        edit_message(text.from.id, text.message.message_id, "#{message} #@check", nil)
        logger.info "Sending Reply: user=#{text.from.username} text=vado a #{text.message}, uid:#{text.from.id}"
      end
      if text.data == 'no'
        reply_chatid = @DB[:users].where(:username=>mentioned_user(message)).get(:chatid)
        send_message(text.from.id, "[reply-confirm] Hai avvisato a @#{mentioned_user(message)} che NON andrai a #{punta_message(message)} #@uncheck")
        send_reply(reply_chatid, "[reply-reject] @#{text.from.username} non viene a #{punta_message(message)} #@uncheck")
        edit_message(text.from.id, text.message.message_id, "#{message} #@uncheck", nil)
        logger.info "Sending Reply: user=#{text.from.username} text=non vado a #{text.message}, uid:#{text.from.id}"
      end

    # display an help message
    when '', /^\/help/i # /help
      send_help(message)
    when '', /^\/start/i # /start
      chatid = @DB[:users].where(:chatid => "#{message.chat.id}").get(:chatid)
      if not chatid
        @DB[:users].insert(
          :username => "#{message.from.username}", 
          :firstname => "#{message.from.first_name}", 
          :lastname => "#{message.from.last_name}", 
          :chatid => "#{message.chat.id}", 
          :start_date => "#{Time.now}"
        )
      end
      kb =[
        Telegram::Bot::Types::KeyboardButton.new(text: '/start'),
        Telegram::Bot::Types::KeyboardButton.new(text: '/help'),
        Telegram::Bot::Types::KeyboardButton.new(text: '/stop'),
      ]
      markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb, one_time_keyboard: true)
      send_message_inline_reply(message.chat.id, "Ciao #{message.from.first_name}, benvenuto!!", markup)
    when '', /^\/users/i # /users DEBUG
      users = @DB[:users]
      send_message(message.chat.id, users.map(:username).join(", "))
    when /^\/punta (.+)/i # /punta
      kb = [
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Vado Anche Io', callback_data: 'yes'),
        Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Non Vado', callback_data: 'no'),
      ]
      markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
      # chatids = @DB[:users].select(:chatid).all # DEBUG
      chatids = @DB[:users].exclude(username: message.from.username).select(:chatid).all
      for chatid in chatids
        send_message_inline_reply(chatid[:chatid], "#@pushpin #@calendar [punta] @#{message.from.username}: #{$1} ", markup)
      end
    when '/stop'
      # See more: https://core.telegram.org/bots/api#replykeyboardremove
      kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      delete_chatid = @DB[:users].where(:chatid=>message.chat.id).delete
      send_message_inline_reply(message.chat.id, "Ci dispiace vederti andare via #@cry", kb)
    end
  end

  def send_help(message)
    send_message(message.from.id, "Help Info #@sos #@info:\n/punta <descrizione, luogo, orario, link eccetera> - Notifica la tua punta a tutti i cibbers")
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