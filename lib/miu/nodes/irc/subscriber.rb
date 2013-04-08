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
              Miu::Logger.debug "[SUB] #{packet.inspect}"
              data = packet.data
              case data
              when Miu::Messages::Text
                target = data.content.room.name
                text = data.content.text
                notice = !!data.content.meta['notice']

                command = notice ? 'NOTICE' : 'PRIVMSG'
                irc.send_message command, target, text
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
    end
  end
end
