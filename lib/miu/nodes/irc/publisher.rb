require 'miu'
require 'celluloid/zmq'

module Miu
  module Nodes
    module IRC
      class Publisher
        include Miu::Publisher
        include Celluloid::ZMQ
        socket_type Celluloid::ZMQ::PubSocket

        def initialize(client)
          @client = client
          @options = client.options
          super @options['pub-host'], @options['pub-port'], @options['pub-tag']
        end

        def write(msg)
          packet = super
          Miu::Logger.debug "[PUB] #{packet}"
          packet
        end

        def publish(type)
          msg = type.new do |m|
            m.network.name = @options[:network]
            yield m.content
          end
          write msg
        end

        def text(msg, notice = false)
          publish Miu::Messages::Text do |c|
            c.room.name = msg.params[0]
            c.user.name = extract_name msg
            c.text = msg.params[1]
            c.meta = {
              :notice => notice
            }
          end
        end

        def enter(msg)
          channels = msg.params[0].split(',') rescue []
          channels.each do |channel|
            publish Miu::Messages::Enter do |c|
              c.room.name = channel
              c.user.name = extract_name msg
            end
          end
        end

        def leave(msg)
          channels = msg.params[0].split(',') rescue []
          channels.each do |channel|
            publish Miu::Messages::Leave do |c|
              c.room.name = channel
              c.user.name = extract_name msg
            end
          end
        end

        private

        def extract_name(msg)
          msg.prefix.nick || msg.prefix.servername
        end
      end
    end
  end
end
