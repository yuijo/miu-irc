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
          super @options['pub-topic'], @options['pub-host'], @options['pub-port']
        end

        def write(msg)
          packet = super
          Miu::Logger.debug "[PUB] #{packet}"
          packet
        end

        def publish(type)
          msg = type.new do |m|
            m.network.name = @options['network']
            m.network.input = @options['pub-topic']
            m.network.output = @options['sub-topic']
            yield m
          end
          write msg
        end

        def text(msg, notice = false)
          publish Miu::Messages::Text do |m|
            m.room.name = msg.params[0]
            m.user.name = extract_name msg
            m.text = msg.params[1]
            m.meta = {
              :notice => notice
            }
          end
        end

        def enter(msg)
          channels = msg.params[0].split(',') rescue []
          channels.each do |channel|
            publish Miu::Messages::Enter do |m|
              m.room.name = channel
              m.user.name = extract_name msg
            end
          end
        end

        def leave(msg)
          channels = msg.params[0].split(',') rescue []
          channels.each do |channel|
            publish Miu::Messages::Leave do |m|
              m.room.name = channel
              m.user.name = extract_name msg
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
