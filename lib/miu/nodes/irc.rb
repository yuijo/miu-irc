require 'miu'
require 'miu/nodes/irc/version'
require 'miu/nodes/irc/connection'
require 'miu/nodes/irc/client'
require 'miu/nodes/irc/publisher'
require 'miu/nodes/irc/subscriber'
require 'miu/nodes/irc/node'

Celluloid.logger = nil if defined?(Celluloid)
