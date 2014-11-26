
class GraphiteStopwatch
  constructor: (prefix, graphiteClient) ->
    if prefix
      @prefix = prefix

      # Ensure the prefix ends with a dot
      @prefix = "#{@prefix}." if @prefix[@prefix.length - 1] != '.'
    else
      @prefix = ''

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

    durationInSeconds

  stop: (name) ->
    duration = @_stop(name)
    console.log "Stopped graphite '#{name}' timer: #{duration}"

  stopButDontPrint: (name) ->
    duration = @_stop(name)
    "Stopped graphite '#{name}' timer: #{duration}"

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
    duration1 = @_stop name
    duration2 = @_stop @secondaryPrefix + name
    console.log "Stopped graphite '#{name}' timer: #{duration1}"
    console.log "Stopped graphite '#{@secondaryPrefix + name}' timer: #{duration2}"

  stopButDontPrint: (name) ->
    duration1 = @_stop name
    duration2 = @_stop @secondaryPrefix + name
    "Stopped graphite '#{name}' timer: #{duration1}\nStopped graphite '#{@secondaryPrefix + name}' timer: #{duration2}"

class FauxGraphiteStopwatch extends GraphiteStopwatch
  constructor: (prefix='') ->
    super(prefix, null)

  _write: (metrics) ->
    # for own name, duration of metrics
    #   console.log "#{name} took: #{duration}s"


module.exports = { GraphiteStopwatch, DualGraphiteStopwatch, FauxGraphiteStopwatch }
