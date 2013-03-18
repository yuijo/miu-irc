require 'miu'
require 'miu-irc/connection'

module Miu
  module Plugins
    class IRC
      include Miu::Plugin

      def initialize(options)
        @publisher = Miu::Publisher.new({
          :host => options[:'miu-pub-host'],
          :port => options[:'miu-pub-port'],
        })
        @subscriber = Miu::Subscriber.new({
          :host => options[:'miu-sub-host'],
          :port => options[:'miu-sub-port'],
          :subscribe => 'miu.output.irc.',
        })
        @irc_client = IRCClient.new(@publisher, {
          :host => options[:host],
          :port => options[:port],
          :nick => options[:nick],
          :user => options[:user],
          :real => options[:real],
          :pass => options[:pass],
          :channels => options[:channels],
        })

        @publisher.connect
        @subscriber.connect
        @irc_client.async.run

        @future = Celluloid::Future.new do
          @subscriber.each do |msg|
            p msg
          end
        end

        [:INT, :TERM].each do |sig|
          trap(sig) do
            shutdown
            exit
          end
        end

        sleep
      end

      private

      def shutdown
        @irc_client.close
        @subscriber.close
        @publisher.close
      end

      class IRCClient < Miu::IRC::Connection
        def initialize(publisher, options)
          @publisher = publisher
          super options
        end

        def on_privmsg(msg)
          publish_text_message msg
        end

        def on_notice(msg)
          publish_text_message msg, 'notice'
        end

        private

        def publish_text_message(msg, sub_type = nil)
          return unless msg.prefix

          m = Miu::Messages::Text.new(:sub_type => sub_type) do |m|
            m.network.name = 'irc'
            m.content.tap do |c|
              c.room.name = msg.params[0]
              c.user.name = msg.prefix.nick || msg.prefix.servername
              c.text = msg.params[1]
            end
          end

          @publisher.send 'miu.input.irc.', m
        rescue => e
          Mou::Logger.exception e 
        end
      end

      register :irc, :desc => %(IRC plugin for miu) do
        desc 'start', %(Start miu-irc plugin)
        option 'host', :type => :string, :desc => 'irc host', :required => true, :aliases => '-a'
        option 'port', :type => :numeric, :default => 6667, :desc => 'irc port', :aliases => '-p'
        option 'nick', :type => :string, :desc => 'irc nick', :required => true, :aliases => '-n'
        option 'user', :type => :string, :desc => 'irc user'
        option 'real', :type => :string, :desc => 'irc real'
        option 'pass', :type => :string, :desc => 'irc pass'
        option 'encoding', :type => :string, :default => 'UTF-8', :desc => 'irc encoding'
        option 'channels', :type => :array, :default => [], :desc => 'irc join channels', :banner => '#channel1 #channel2'
        add_miu_pub_options!
        add_miu_sub_options!
        def start
          IRC.new options
        end

        desc 'init', %(Generates a miu-irc configurations)
        def init
          append_to_file 'config/miu.god', <<-CONF

God.watch do |w|
  w.dir = Miu.root
  w.log = Miu.root.join('log/irc.log')
  w.name = 'irc'

  host = 'chat.freenode.net'
  nick = 'miu'
  w.start = "bundle exec miu irc start --host=\#{host} --nick=\#{nick}"

  w.keepalive
end
          CONF
        end
      end
    end
  end
end
