Q = require "q"
Q.longStackSupport = true
request = require 'request'

class BlackholeStatsClient
  incr: () ->
  time: (name, func) ->
    func()

class HttpClient
  class BadResponse
    constructor: (host, path, statusCode) ->
      @message = "Bad response from #{host}#{path} (#{statusCode})"
      @name = "HTTPBadResponse"

  constructor: (@options) ->
    @hosts = @options.hosts
    @statClient = @options.statClient || new BlackholeStatsClient()
    @n = 0
    @hostsLength = @hosts.length

  request: (method, path, query, body) ->
    host = @hosts[@nextIndex()]
    @statClient.incr("httpClient.requests~total,#{host},#{path}")

    requestParams = { url: host + path, method: method, json: body, qs: query }

    deferred = Q.defer()

    request requestParams, (error, response, body) ->
      if error
        @statClient.incr("httpClient.error~total,#{host},#{host}#{path}")
        deferred.reject(new BadResponse(host, path, response.statusCode))
      else
        @statClient.incr("httpClient.success~total,#{host},#{host}#{path}")
        deferred.resolve
          response: response
          body: JSON.parse(body)

    @statClient.time("httpClient.requestTime~total,#{host}", deferred.promise)

  get: (path, query) ->
    @request("GET", path, query)

  post: (path, body) ->
    @request("POST", path, null, body)

  nextIndex: () ->
    @n = (@n + 1) % @hostsLength
    @n

module.exports = HttpClient
