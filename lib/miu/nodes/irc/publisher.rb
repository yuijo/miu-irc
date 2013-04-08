require 'miu'
require 'celluloid/zmq'

module Miu
  module Nodes
    module IRC
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
    end
  end
end
