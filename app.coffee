express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
azure = Promise.promisifyAll require('azure-storage')
Q = require 'q'

app = express()

exports.app = app

app.set 'port', process.env.port or 4000
app.use bodyParser()

queueSvc = azure.createQueueService process.env['STORAGE_NAME'], process.env['STORAGE_SHARED_KEY']

app.get '/', (req, res) ->
  queueSvc.listQueuesSegmentedAsync(null, null).then (result) =>
    queueNames = result[0].entries.map (entrie) =>
      entrie.name
    promises = queueNames.map (name) =>
      deff = Q.defer()
      deff.resolve(name)
      deff.promise.then (name) =>
          queueSvc.getQueueMetadataAsync(name, null).then (result) =>
            "#{name}: #{result[0].approximatemessagecount}, \t"

    Q.allSettled(promises).then (promisValues) ->
      resBody = ""
      promisValues.forEach (value) ->
        resBody += value.value
    
      res.send resBody

app.listen app.get('port'), () ->
  console.log "listening on port #{app.get('port')}"
