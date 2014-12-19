dns = require('dns')
os = require('os')

Nopents = require('nopents')

HOSTNAME = os.hostname()

# Quick-n-dirty client to mimic the graphite module's metric write API
class SimpleOpenTSDBClient
  constructor: (host, port) ->
    @client = new Nopents
      host: host
      port: parseInt(port, 10)


  write: (metricsObject) ->
    toSend = []

    for own metricKey, metricValue of metricsObject
      toSend.push
        key: metricKey
        val: metricValue
        tags:
          host: HOSTNAME

    @client.send toSend


module.exports = SimpleOpenTSDBClient
