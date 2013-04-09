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
          publish_text msg, false
        end

        def on_notice(msg)
          publish_text msg, true
        end

        def on_join(msg)
          channels = msg.params[0].split(',') rescue []
          channels.each do |channel|
            publish Miu::Messages::Enter do |c|
              c.room.name = channel
              c.user.name = to_name(msg)
            end
          end
        end

        def on_part(msg)
          channels = msg.params[0].split(',') rescue []
          channels.each do |channel|
            publish Miu::Messages::Leave do |c|
              c.room.name = channel
              c.user.name = to_name(msg)
            end
          end
        end

        private

        def to_name(msg)
          msg.prefix.nick || msg.prefix.servername
        end

        def publish_text(msg, notice)
          publish Miu::Messages::Text do |c|
            c.room.name = msg.params[0]
            c.user.name = to_name(msg)
            c.text = msg.params[1]
            c.meta = {
              :notice => notice
            }
          end
        end

        def publish(type)
          msg = type.new do |m|
            m.network.name = 'irc'
            yield m.content
          end
          @node.publisher.write msg
        end
      end
    end
  end
end
