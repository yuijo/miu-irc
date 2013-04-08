require 'miu/nodes/irc'

module Miu
  module Nodes
    module IRC
      class Node
        include Miu::Node
        description 'IRC node for miu'

        attr_reader :publisher
        attr_reader :subscriber
        attr_reader :options

        def initialize(options)
          @options = options

          Miu::Logger.info "Options:"
          @options.each do |k, v|
            Miu::Logger.info "  #{k}: #{v}"
          end

          @publisher = Publisher.new options['pub-host'], options['pub-port'], options['pub-tag']
          @subscriber = Subscriber.new options['sub-host'], options['sub-port'], options['sub-tag']
          @client = Client.new(self, {
            :host => options[:host], :port => options[:port],
            :nick => options[:nick], :user => options[:user], :real => options[:real],
            :pass => options[:pass],
            :channels => options[:channels],
          })

          [:INT, :TERM].each do |sig|
            trap(sig) do
              shutdown
              exit
            end
          end

          sleep
        end

        private

        def shutdown
          @client.close
          @subscriber.close
          @publisher.close
        end

        register :irc do
          desc 'start', %(Start miu-irc node)
          option 'host', :type => :string, :desc => 'irc host', :required => true, :aliases => '-a'
          option 'port', :type => :numeric, :default => 6667, :desc => 'irc port', :aliases => '-p'
          option 'nick', :type => :string, :desc => 'irc nick', :required => true, :aliases => '-n'
          option 'user', :type => :string, :desc => 'irc user'
          option 'real', :type => :string, :desc => 'irc real'
          option 'pass', :type => :string, :desc => 'irc pass'
          option 'encoding', :type => :string, :default => 'utf-8', :desc => 'irc encoding'
          option 'channels', :type => :array, :default => [], :desc => 'irc join channels', :banner => '#channel1 #channel2'
          add_miu_pub_sub_options 'irc'
          def start
            Node.new options
          end

          desc 'init', %(Generates a miu-irc configurations)
          def init
            append_to_file 'config/miu.god', <<-CONF

God.watch do |w|
  w.dir = Miu.root
  w.log = Miu.root.join('log/irc.log')
  w.name = 'irc'

  host = 'chat.freenode.net'
  nick = 'miu'
  w.start = "bundle exec miu irc start --host=\#{host} --nick=\#{nick}"

  w.keepalive
end
            CONF
          end
        end
      end
    end
  end
end
