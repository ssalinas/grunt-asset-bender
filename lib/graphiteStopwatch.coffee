
class GraphiteStopwatch
  constructor: (prefix, graphiteClient) ->
    @prefix = prefix or  ''
    @client = graphiteClient

  _start: (name) ->
    console.log "Starting graphite '#{name}' timer"
    @start_times = @start_times ? {}
    @start_times[name] = new Date() if name

  start: (name, callback) ->
    @_start name

    # Automatically stop if given a block
    if callback?
      yielded_value = callback()
      @stop name
      yielded_value

  _stop: (name) ->
    new Error "No such timer called #{name}" unless @start_times[name]

    durationInMillis = (new Date()).getTime() - @start_times[name].getTime()
    durationInSeconds = durationInMillis * 1/1000.0

    metrics = {}
    metrics[@prefix + name] = durationInSeconds

    @_write metrics
    delete @start_times[name]

    console.log "Stopped graphite '#{name}' timer: #{durationInSeconds}"
    durationInSeconds

  stop: (name) ->
    @_stop(name)

  _write: (metrics) ->
    @client.write metrics


class DualGraphiteStopwatch extends GraphiteStopwatch
  constructor: (prefix, secondaryPrefix, graphiteClient) ->
    @secondaryPrefix = secondaryPrefix
    super prefix, graphiteClient

  start: (name) ->
    @_start name
    @_start @secondaryPrefix + name

    # Automatically stop if given a block
    if callback?
      yielded_value = callback()
      @stop name
      yielded_value

  stop: (name) ->
    @_stop name
    @_stop @secondaryPrefix + name


class FauxGraphiteStopwatch extends GraphiteStopwatch
  constructor: ->
    super('', null)

  _write: (metrics) ->
    for own name, duration of metrics
      console.log "#{name} took: #{duration}s"


module.exports = { GraphiteStopwatch, DualGraphiteStopwatch, FauxGraphiteStopwatch }
