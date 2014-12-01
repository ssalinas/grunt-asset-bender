dns = require('dns')
os = require('os')

createOpenTSDBSocket = require 'opentsdb-socket'

HOSTNAME = os.hostname()

# Quick-n-dirty client to mimic the graphite module's metric write API
class SimpleOpenTSDBClient
  constructor: (host, port) ->
    @socket = createOpenTSDBSocket()
    @socket.host host
    @socket.port parseInt(port, 10)

    @socket.on 'connect', -> console.log('connected to socket')
    @socket.on 'error', (e) -> console.log('error with socket', e)
    @socket.on 'close', -> console.log('socket closed')

    # Connect immediately
    @socket.connect()


  write: (metricsObject) ->
    toSend = ''
    now = Date.now()

    for own metricKey, metricValue of metricsObject
      toSend += "put #{metricKey} #{now} #{metricValue} host=#{HOSTNAME}\n"

    console.log "toSend:\n", toSend, "\n"

    @socket.write toSend, =>
      console.log "@socket.bytesWritten", @socket.bytesWritten
      # @socket.end()

module.exports = SimpleOpenTSDBClient
