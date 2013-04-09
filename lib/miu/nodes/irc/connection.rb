require 'celluloid/io'
require 'ircp'
require 'forwardable'

module Miu
  module Nodes
    module IRC
      class Connection
        include Celluloid::IO

        BUFFER_SIZE = 1024 * 4

        attr_reader :host, :port
        attr_reader :nick, :user, :real, :pass
        attr_reader :encoding
        attr_reader :socket

        def initialize(options)
          @host = options[:host]
          @port = options[:port] || 6667
          @nick = options[:nick]
          @user = options[:user] || @nick
          @real = options[:real] || @nick
          @pass = options[:pass]
          @encoding = options[:encoding] || 'UTF-8'

          @socket = TCPSocket.new @host, @port
        end

        def finalize
          close
        end

        def close
          @socket.close if @socket && !@socket.closed?
        end

        def send_message(*args)
          msg = Ircp::Message.new(*args)
          puts "[SEND] #{msg}"
          @socket.write msg.to_irc
        end

        def run
          attach
          readlines do |data|
            msg = Ircp.parse data rescue nil
            if msg
              puts "[RECV] #{msg}"
              on_message msg
            end
          end
        end

        def readlines(buffer_size = BUFFER_SIZE, &block)
          readbuf = ''.force_encoding('ASCII-8BIT')
          loop do
            readbuf << @socket.readpartial(buffer_size).force_encoding('ASCII-8BIT')
            while data = readbuf.slice!(/.+\r\n/)
              block.call encode(data, @encoding)
            end
          end
        end

        def encode(str, encoding)
          str.force_encoding(encoding).encode!(:invalid => :replace, :undef => :replace)
          str.chars.select { |c| c.valid_encoding? }.join
        end

        def attach
          send_message 'PASS', @pass if @pass
          send_message 'NICK', @nick
          send_message 'USER', @user, '*', '*', @real
        end

        def on_message(msg)
          begin
            method = "on_#{msg.command.to_s.downcase}"
            __send__ method, msg if respond_to? method
          rescue => e
            Miu::Logger.exception e
          end
        end
      end
    end
  end
end
