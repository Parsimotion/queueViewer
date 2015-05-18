express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
azure = Promise.promisifyAll require('azure')
azureStorage = Promise.promisifyAll require('azure-storage')
Q = require 'q'

app = express()

exports.app = app

app.set 'port', process.env.port or 4000
app.use bodyParser()

serviceBusService = azure.createServiceBusService process.env['STORAGE_NAME']
queueSvc = azureStorage.createQueueService process.env['STORAGE_NAME'], process.env['STORAGE_SHARED_KEY']

app.get '/', (req, res) ->
  debugger
  promises = []
  data =
    serviceBus: {}
    azureStorage: {}
  serviceBusQuery = serviceBusService.listQueuesAsync().then (result) ->
    queuesInformation = result[0]
    queuesInformation.forEach (sbQueueData) ->
      data.serviceBus[sbQueueData.QueueName] = 
        ActiveMessageCount: sbQueueData.CountDetails['d2p1:ActiveMessageCount']
        DeadLetterMessageCount: sbQueueData.CountDetails['d2p1:DeadLetterMessageCount']
        Status: sbQueueData.Status
  
  promises.push serviceBusQuery
  
  azureStorageQuery = queueSvc.listQueuesSegmentedAsync(null, null).then (result) ->
    queueNames = result[0].entries.map (entrie) ->
      entrie.name
    fromNameQueries = queueNames.map (name) ->
      deff = Q.defer()
      deff.resolve(name)
      deff.promise.then (name) =>
          queueSvc.getQueueMetadataAsync(name, null).then (result) ->
            data.azureStorage[name] = result[0].approximatemessagecount
    promises = promises.concat fromNameQueries

    Q.allSettled(promises).then (promisValues) ->
      res.contentType 'application/json'
      res.send(JSON.stringify(data))

app.listen app.get('port'), () ->
  console.log "listening on port #{app.get('port')}"
