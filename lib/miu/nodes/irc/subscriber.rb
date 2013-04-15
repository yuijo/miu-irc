require 'miu'
require 'celluloid/zmq'

module Miu
  module Nodes
    module IRC
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
              Miu::Logger.debug "[SUB] #{packet}"

              data = packet.data
              class_name = data.class.name.split('::').last.downcase
              method_name = "on_#{class_name}"
              __send__ method_name, irc, data if respond_to?(method_name)
            rescue => e
              Miu::Logger.exception e
            end
          end
        end

        def close
          @sub.close
        end

        private

        def on_text(irc, data)
          target = data.content.room.name
          text = data.content.text
          notice = !!data.content.meta['notice']

          command = notice ? 'NOTICE' : 'PRIVMSG'
          irc.send_message command, target, text
        end

        def on_enter(irc, data)
          channel = data.content.room.name
          irc.send_message 'JOIN', channel
        end

        def on_leave(irc, data)
          channel = data.content.room.name
          irc.send_message 'PART', channel
        end
      end
    end
  end
end
