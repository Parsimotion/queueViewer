express = require 'express'
bodyParser = require 'body-parser'
azure = require 'azure-storage'
Q = require 'q'

app = express()

exports.app = app

app.set 'port', process.env['WEB_PORT'] or 4000
app.use bodyParser()

queueSvc = azure.createQueueService process.env['STORAGE_NAME'], process.env['STORAGE_SHARED_KEY']

app.get '/', (req, res) ->
  queueSvc.listQueuesSegmented null, (err, result, response) =>
  	queueNames = result.entries.map (entrie) =>
  	  entrie.name
    promises = queueNames.map (name) =>
      class PromiseContext
        constructor: (@name) ->
        execute: =>
          deferred =  Q.defer()
          queueSvc.getQueueMetadata @name, null, (err, result, response) =>
            deferred.reject(new Error(error)) if err
            deferred.resolve "#{@name}: #{result.approximatemessagecount}, \t" if !err
          deferred.promise
      new PromiseContext(name).execute()

    Q.allSettled(promises).then (promisValues) ->
      resBody = ""
      promisValues.forEach (value) ->
        resBody += value.value
    
      res.send resBody

app.listen app.get('port'), () ->
  console.log "listening on port #{app.get('port')}"
