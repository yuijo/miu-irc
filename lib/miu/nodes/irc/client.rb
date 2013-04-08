require 'miu/nodes/irc/connection'

module Miu
  module Nodes
    module IRC
      class Client < Connection
        attr_reader :channels
        attr_reader :node

        def initialize(node, options)
          super options
          @node = node
          @channels = Array(options[:channels])

          async.run
        end

        def on_376(msg)
          @channels.each do |channel|
            send_message 'JOIN', *channel.split(/ +/)
          end

          @node.subscriber.async.run self
        end

        def on_ping(msg)
          send_message 'PONG'
        end

        def on_privmsg(msg)
          publish_text_message msg
        end

        def on_notice(msg)
          publish_text_message msg, 'notice'
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

          @node.publisher.write miu_msg
        rescue => e
          Miu::Logger.exception e
        end
      end
    end
  end
end
