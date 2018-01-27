require 'cinch'
require 'mysql2'
require 'sequel'
require 'yaml'
require 'pp'



def addChannelToList(channel, channelList)
  if channelList[channel].nil?
    channelList[channel] = []
    users = Channel(channel).users
    users.each_key { |key| channelList[channel].push key.to_s }
  end
end

def logToDB(channel, person, text, messageType)
  channel = channel.to_s
  createChannelTable(channel) unless DB.table_exists?(channel)
  channelTable = DB.from(:"#{channel}")
  time = Time.now.utc
  person = person.split("!")
  nick = person[0]
  ident = ""
  host = ""
  if person[1].nil?
    ident = nick
    host = nick
  else
    ident = person[1].split("@")[0]
    host = person[1].split("@")[1]
  end
  channelTable.insert(
    :nick        => nick,
    :ident       => ident,
    :host        => host,
    :message     => text,
    :messageType => messageType,
    :year        => time.year,
    :month       => time.month,
    :day         => time.day,
    :hour        => time.hour,
    :minute      => time.min,
    :second      => time.sec )
end

def createChannelTable(channelName)
  DB.create_table channelName do
    primary_key :line
    String :nick
    String :ident
    String :host
    String :message
    String :messageType
    Integer :year
    Integer :month
    Integer :day
    Integer :hour
    Integer :minute
    Integer :second
  end
end

bot = Cinch::Bot.new do
  config = YAML::load_file('witness.yaml')
  DB = Sequel.connect(:adapter => 'mysql2', :user => config['dbUser'], :password => config['dbPass'], :database => config['dbName'])
  channelList = Hash.new
  configure do |c|
    c.server = config['server']
    c.nick = config['nick']
    c.user = config['ident']
  end

  on :connect do
    if config['oper']
      bot.oper(config['operPass'], config['operUser'])
    end
    bot.set_mode(config['modes'])
    timer = Timer(60, {:shots => 1}) { bot.irc.send("list") }
  end

  on 322 do |m|
    bot.join(m.channel.name)
  end


  on :message, "hello" do |m|
    return if m.events.include?(:channel)
    m.reply "Hello, #{m.user.nick}"
    m.reply "I am just a logging bot, you can disregard my presence" 
  end

  on :join do |m|
    if m.user.nick == "witness"
      addChannelToList(m.channel.name, channelList)
    else
      channelList[m.channel.name].push(m.user.nick)
    end
    logToDB(m.channel, m.prefix, "has joined the channel", "join")
    log("#{m.user.nick} just joined #{m.channel}")
  end

  on :leaving do |m,nick|
    type = ""
    if m.channel?
      message = "has left the channel" if m.message == "Leaving" or m.message == ""
      channelList[m.channel.name].delete(m.user.nick)
      if m.events.include?(:kick)
        type = "kick"
      elsif m.events.include?(:kill)
        type = "kill"
      elsif m.events.include?(:part)
        type = "part"
      end
      logToDB(m.channel, m.prefix, m.message, type)
      bot.part(m.channel.name) if channelList[m.channel.name].size == 1
      log("#{m.prefix} left #{m.channel}: (#{m.message})")
    else
      if m.events.include?(:kill) 
        type = "kill"
      else
        type = "quit"
      end
      channelList.each do |name,users|
        if users.include?(nick.to_s)
          channelList[name].delete(nick.to_s)
          logToDB(name, m.prefix, m.message, type)
          pp channelList[name]
          bot.part(name) if channelList[name].size == 1
        end
      end
      log("#{m.prefix} quit (#{m.message})")
    end
  end

  on :action do |m|
    return unless m.channel?
    logToDB(m.channel, m.prefix, m.ctcp_message.sub(/^ACTION /, ""), "emote")
    log("#{m.channel} *#{m.user} #{m.ctcp_message.sub(/^ACTION /, '')}")
  end

  on :ctcp do |m|
    return unless m.channel?
    return if m.events.include?(:action)
    logToDB(m.channel, m.prefix, m.ctcp_message, "ctcp")
    log("#{m.channel}: #{m.user} CTCP #{m.ctcp_message}")
  end

  on :channel do |m|
    return if m.events.include?(:ctcp)
    return if m.events.include?(:leaving)
    return unless m.prefix
    logToDB(m.channel, m.prefix, m.message, "normal")
    log("#{m.channel}: #{m.prefix} said: #{m.message}")
  end

  on :invite do |m|
    bot.join m.channel
  end

end

bot.start
