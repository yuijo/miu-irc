require 'miu/nodes/irc/client'

module Miu
  module Nodes
    module IRC
      class Node
        include Miu::Node
        description 'IRC node for miu'

        attr_reader :options

        def initialize(options)
          @options = options

          Miu::Logger.info "Options:"
          @options.each do |k, v|
            Miu::Logger.info "  #{k}: #{v}"
          end

          @client = Client.new(self, {
            :host => options[:host], :port => options[:port],
            :nick => options[:nick], :user => options[:user], :real => options[:real],
            :pass => options[:pass],
            :channels => options[:channels],
          })

          [:INT, :TERM].each do |sig|
            trap(sig) { exit }
          end

          sleep
        end

        private

        def shutdown
          @client.close
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
          option 'channels', :type => :array, :default => [], :desc => 'irc join channels', :banner => %('#channel1 password' '#channel2')
          option 'network', :type => :string, :default => 'IRC', :desc => 'network name'
          add_miu_pub_options 'miu.input.irc.'
          add_miu_sub_options 'miu.output.irc.'
          def start
            Node.new options
          end

          desc 'init', %(Generates a miu-irc configurations)
          def init
            config <<-EOS
Miu.watch 'irc' do |w|
  w.start = 'miu irc start', {
    '--host' => 'chat.freenode.net',
    '--nick' => 'miu',
    '--channels' => ['#miu'],
    '--verbose' => false
  }
  w.keepalive
end
            EOS
          end
        end
      end
    end
  end
end
