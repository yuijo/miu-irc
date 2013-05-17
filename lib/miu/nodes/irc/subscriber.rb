require 'miu'
require 'celluloid/zmq'

module Miu
  module Nodes
    module IRC
      class Subscriber
        include Miu::Subscriber
        include Celluloid::ZMQ
        socket_type Celluloid::ZMQ::SubSocket

        def initialize(client)
          @client = client
          @options = client.options
          super @options['sub-host'], @options['sub-port'], @options['sub-tag']
        end

        private

        def on_packet(packet)
          Miu::Logger.debug "[SUB] #{packet}"
          super
        end

        def on_text(tag, msg)
          target = msg.content.room.name
          text = msg.content.text
          notice = !!msg.content.meta['notice']

          command = notice ? 'NOTICE' : 'PRIVMSG'
          echoback = @client.send_message command, target, text
          @client.publisher.text echoback, notice
        end

        def on_enter(tag, msg)
          channel = msg.content.room.name
          echoback = @client.send_message 'JOIN', channel
          @client.publisher.enter echoback
        end

        def on_leave(tag, msg)
          channel = msg.content.room.name
          echoback = @client.send_message 'PART', channel
          @client.publisher.leave echoback
        end
      end
    end
  end
end
