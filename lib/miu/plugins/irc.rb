require 'miu'
require 'miu-irc/connection'
require 'celluloid/zmq'

module Miu
  module Plugins
    class IRC
      include Miu::Plugin
      description 'IRC plugin for miu'

      attr_reader :publisher
      attr_reader :subscriber
      attr_reader :options

      class Publisher
        include Celluloid::ZMQ

        def initialize(host, port, tag)
          @pub = Miu::Publisher.new host, port, :socket => Celluloid::ZMQ::PubSocket
          @tag = tag
        end

        def write(msg)
          packet = @pub.write @tag, msg
          Miu::Logger.debug "[PUB] #{packet.inspect}"
          packet
        end

        def close
          @pub.close
        end
      end

      class Subscriber
        include Celluloid::ZMQ

        def initialize(host, port, tag)
          @sub = Miu::Subscriber.new host, port, :socket => Celluloid::ZMQ::SubSocket
          @tag = tag
        end

        def run(irc)
          @sub.subscribe @tag
          @sub.each do |packet|
            begin
              Miu::Logger.debug "[SUB] #{packet.inspect}"
              data = packet.data
              case data
              when Miu::Messages::Text
                target = data.content.room.name
                text = data.content.text
                irc.send_message 'PRIVMSG', target, text
              end
            rescue => e
              Miu::Logger.exception e
            end
          end
        end

        def close
          @sub.close
        end
      end

      def initialize(options)
        @options = options

        Miu::Logger.info "Options:"
        @options.each do |k, v|
          Miu::Logger.info "  #{k}: #{v}"
        end

        @publisher = Publisher.new options[:'pub-host'], options[:'pub-port'], options[:'pub-tag']
        @subscriber = Subscriber.new options[:'sub-host'], options[:'sub-port'], options[:'sub-tag']
        @irc_client = IRCClient.new(self, {
          :host => options[:host],
          :port => options[:port],
          :nick => options[:nick],
          :user => options[:user],
          :real => options[:real],
          :pass => options[:pass],
          :channels => options[:channels],
        })

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
        attr_reader :plugin

        def initialize(plugin, options)
          @plugin = plugin
          super options

          async.run
        end

        def on_privmsg(msg)
          publish_text_message msg
        end

        def on_notice(msg)
          publish_text_message msg, 'notice'
        end

        def on_376(msg)
          super
          @plugin.subscriber.async.run self
        end

        def publish_text_message(irc_msg, sub_type = nil)
          return unless irc_msg.prefix

          miu_msg = Miu::Messages::Text.new(:sub_type => sub_type) do |m|
            m.network.name = 'irc'
            m.content.tap do |c|
              c.room.name = irc_msg.params[0]
              c.user.name = irc_msg.prefix.nick || irc_msg.prefix.servername
              c.text = irc_msg.params[1]
            end
          end

          @plugin.publisher.write miu_msg
        rescue => e
          Miu::Logger.exception e
        end
      end

      register :irc do
        desc 'start', %(Start miu-irc plugin)
        option 'host', :type => :string, :desc => 'irc host', :required => true, :aliases => '-a'
        option 'port', :type => :numeric, :default => 6667, :desc => 'irc port', :aliases => '-p'
        option 'nick', :type => :string, :desc => 'irc nick', :required => true, :aliases => '-n'
        option 'user', :type => :string, :desc => 'irc user'
        option 'real', :type => :string, :desc => 'irc real'
        option 'pass', :type => :string, :desc => 'irc pass'
        option 'encoding', :type => :string, :default => 'UTF-8', :desc => 'irc encoding'
        option 'channels', :type => :array, :default => [], :desc => 'irc join channels', :banner => '#channel1 #channel2'
        add_miu_pub_sub_options 'irc'
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
