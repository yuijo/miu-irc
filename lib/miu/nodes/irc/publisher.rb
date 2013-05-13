require 'miu'
require 'celluloid/zmq'

module Miu
  module Nodes
    module IRC
      class Publisher
        include Miu::Publisher
        include Celluloid::ZMQ
        socket_type Celluloid::ZMQ::PubSocket

        def write(msg)
          packet = super
          Miu::Logger.debug "[PUB] #{packet}"
          packet
        end
      end
    end
  end
end
