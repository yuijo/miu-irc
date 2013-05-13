require 'miu'
require 'celluloid/zmq'

module Miu
  module Nodes
    module IRC
      class Subscriber
        include Miu::Subscriber
        include Celluloid::ZMQ
        socket_type Celluloid::ZMQ::SubSocket

        def run(irc)
          @irc = irc
          super
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
          irc.send_message command, target, text
        end

        def on_enter(tag, msg)
          channel = msg.content.room.name
          irc.send_message 'JOIN', channel
        end

        def on_leave(tag, msg)
          channel = msg.content.room.name
          irc.send_message 'PART', channel
        end
      end
    end
  end
end
