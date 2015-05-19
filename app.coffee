express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
azure = Promise.promisifyAll require('azure')
azureStorage = Promise.promisifyAll require('azure-storage')
Q = require 'q'
_ = require 'lodash'

app = express()

exports.app = app

app.set 'port', process.env.port or 4000
app.use bodyParser()

sn = process.env['STORAGE_NAME']
ssk = process.env['STORAGE_SHARED_KEY']
sbcs = process.env['SB_CONNECTION_STRING']


class ResolvedPromise
  constructor: (value) ->
    @deferred = Q.defer()
    @deferred.resolve(value)
  promise: =>
    @deferred.promise

class StorageQueueService
  constructor: (@storageName, @storageSharedKey) ->
    @queueSvc = azureStorage.createQueueService @storageName, @storageSharedKey

  getPluckedData: =>
    @getData().then (queuesResults) ->
      _.object(_.pluck(queuesResults, 'name'), _.pluck(queuesResults, 'quantity'))
  getData: =>
    @_getQueueNames().then (queuesResults) =>
      fromNameQueries = queuesResults
      .map((result) => result.name)
      .map (name) =>
        new ResolvedPromise(name).promise().then (name) =>
            @queueSvc.getQueueMetadataAsync(name, null).then (result) =>
              name: name
              quantity: result[0].approximatemessagecount
      Q.all fromNameQueries

  _getQueueNames: =>
    @queueSvc.listQueuesSegmentedAsync(null, null).then (result) ->
      result[0].entries

class ServiceBusService
  constructor: (connectionString) ->
    @serviceBusService = azure.createServiceBusService connectionString

  getData: =>
    @serviceBusService.listQueuesAsync().then (result) ->
        queuesInformation = result[0]
        queuesInformation = queuesInformation.map (sbQueueData) ->
          name: sbQueueData.QueueName
          data:
            ActiveMessageCount: sbQueueData.CountDetails['d2p1:ActiveMessageCount']
            DeadLetterMessageCount: sbQueueData.CountDetails['d2p1:DeadLetterMessageCount']
            Status: sbQueueData.Status
        _.object(_.pluck(queuesInformation, 'name'), _.pluck(queuesInformation, 'data'))

app.get '/azureStorage', (req, res) ->
  service = new StorageQueueService(sn, ssk)
  service.getData().then (queueData) ->
      res.contentType 'application/json'
      res.send(JSON.stringify(queueData))


app.get '/', (req, res) ->
  debugger
  promises = []
  data =
    serviceBus: {}
    azureStorage: {}

  serviceBusQuery = new ServiceBusService(sbcs).getData()
  .then (result) ->
    azureStorage: result

    
  promises.push serviceBusQuery
  
  azureStorageQuery = new StorageQueueService(sn, ssk).getPluckedData()
  .then (result) ->
    serviceBus: result

  promises.push azureStorageQuery

  Q.all(promises).then (data) ->
    res.contentType 'application/json'
    res.send(JSON.stringify(data))

app.listen app.get('port'), () ->
  console.log "listening on port #{app.get('port')}"
