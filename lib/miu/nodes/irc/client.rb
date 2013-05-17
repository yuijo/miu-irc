require 'miu/nodes/irc/connection'
require 'miu/nodes/irc/publisher'
require 'miu/nodes/irc/subscriber'

module Miu
  module Nodes
    module IRC
      class Client < Connection
        attr_reader :channels
        attr_reader :node, :options, :publisher, :subscriber

        def initialize(node, options)
          super options
          @node = node
          @channels = Array(options[:channels])
          @publisher = Publisher.new self
          @subscriber = Subscriber.new self

          async.run
        end

        def close
          @publisher.close
          @subscriber.close
          super
        end

        def options
          @node.options
        end

        def on_376(msg)
          @channels.each do |channel|
            send_message 'JOIN', *channel.split(/ +/)
          end

          @subscriber.async.run
        end

        def on_ping(msg)
          send_message 'PONG', msg.params[0]
        end

        def on_privmsg(msg)
          @publisher.text msg, false
        end

        def on_notice(msg)
          @publisher.text msg, true
        end

        def on_join(msg)
          @publisher.enter msg
        end

        def on_part(msg)
          @publisher.leave msg
        end
      end
    end
  end
end
