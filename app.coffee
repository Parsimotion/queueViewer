express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
azure = Promise.promisifyAll require('azure-storage')
Q = require 'q'

app = express()

exports.app = app

app.set 'port', process.env.port or 4000
app.use bodyParser()

queueSvc = azure.createQueueService 'mercadolibrequeue', '7x5+6He/11uSIbxXNFb+KL9L4dist1v13H717noOUIgbPRV3909ryxqTxn3kvOWma1a7/WFESW1RnJxeWjeZYA=='

app.get '/', (req, res) ->
  data = {}
  queueSvc.listQueuesSegmentedAsync(null, null).then (result) =>
    queueNames = result[0].entries.map (entrie) =>
      entrie.name
    promises = queueNames.map (name) =>
      deff = Q.defer()
      deff.resolve(name)
      deff.promise.then (name) =>
          queueSvc.getQueueMetadataAsync(name, null).then (result) =>
            data[name] = result[0].approximatemessagecount

    Q.allSettled(promises).then (promisValues) ->
      res.contentType 'application/json'
      res.send(JSON.stringify(data))

app.listen app.get('port'), () ->
  console.log "listening on port #{app.get('port')}"
