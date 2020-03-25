require 'tumblr_client'
require 'yaml'
require 'discordrb'

class Checker
  def initialize(config)
    @blog_url = config["tumblr_url"]
    @channel_id = config["discord_channel"]
    @tumblr = Tumblr::Client.new({
      consumer_key: config["tumblr_consumer_key"],
      consumer_secret: config["tumblr_consumer_secret"],
      oauth_token: config["tumblr_access_token"],
      oauth_token_secret: config["tumblr_access_secret"]
    })
    @discord = Discordrb::Bot.new(token: config["discord_token"])
  end

  def run
    puts "Here's the Discord invite url: " + @discord.invite_url
    @discord.run(true)

    first_post = @tumblr.posts(@blog_url, limit: 1)["posts"].first
    @last_post_id = first_post["id"]
    handle_post(first_post)

    while true
      sleep(300)
      begin
        posts = @tumblr.posts(@blog_url, limit: 10)["posts"]
        posts.reverse_each do |post|
          if post["id"] > @last_post_id
            @last_post_id = post["id"]
            handle_post(post)
          end
        end
      rescue Exception => e
        puts e
      end
    end
  end

  def handle_post(post)
    puts post["post_url"]
    @discord.send_message(@channel_id, post["post_url"])
  end
end

config = YAML.load_file("config.yml")
checker = Checker.new(config)
checker.run
