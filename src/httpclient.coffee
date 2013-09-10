Q = require "q"
Q.longStackSupport = true
HTTP = require "q-io/http"

class BlackholeStatsClient
  incr: () ->
  time: (name, func) ->
    func()

class HttpClient
  class BadResponse
    constructor: (host, path, statusCode) ->
      @message = "Bad response from #{host}#{path} (#{statusCode})"
      @name = "HttpBadResponse"

  constructor: (@options) ->
    @hosts = @options.hosts
    @statClient = @options.statClient || new BlackholeStatsClient()
    @n = 0
    @hostsLength = @hosts.length

  request: (method, path) ->
    host = @hosts[@nextIndex()]
    @statClient.incr("httpClient.requests~total,#{host},#{path}")

    requestParams = { url: host + path, method: method }
    @statClient.time "httpClient.requestTime~total,#{host}", () =>
      HTTP.request(requestParams).then (response) =>
        if response.status == 200
          @statClient.incr("httpClient.success~total,#{host},#{host}#{path}")
          response.body.read().then (body) =>
            strResponse = body.toString("utf-8")
            JSON.parse(strResponse)
        else
          @statClient.incr("httpClient.error~total,#{host},#{host}#{path}")
          throw new BadResponse(host, path, response.status)

  get: (path) ->
    @request("GET", path)

  nextIndex: () ->
    @n = (@n + 1) % @hostsLength
    @n

client = new HttpClient
  hosts: ["https://api.potluck.it"]

module.exports = HttpClient
