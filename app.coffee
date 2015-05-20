express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
azure = Promise.promisifyAll require('azure')
azureStorage = Promise.promisifyAll require('azure-storage')
Q = require 'q'
_ = require 'lodash'

parse = (it) ->
  JSON['parse'] it

app = express()

exports.app = app

app.set 'port', process.env.port or 4000
app.use bodyParser()

sbcs = process.env['SB_CONNECTION_STRING']
credentials = process.env['STORAGE_CREDENTIALS']
credentials = JSON.parse credentias


class ResolvedPromise
  constructor: (value) ->
    @deferred = Q.defer()
    @deferred.resolve(value)
  promise: =>
    @deferred.promise

class StorageQueueService
  constructor: (@storageName, @storageSharedKey) ->
    @queueSvc = azureStorage.createQueueService @storageName, @storageSharedKey

  getPluckedDataWithName: =>
    @getPluckedData().then (queuesResults) =>
      obj = {}
      obj[@storageName] = queuesResults
      obj
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

app.get '/', (req, res) ->
  promises = []

  serviceBusQuery = new ServiceBusService(sbcs).getData()
  .then (result) ->
    serviceBus: result

  promises.push serviceBusQuery
  
  azureStorageQueries = credentials.map (credential) ->
    query = new StorageQueueService(credential.name, credential.shared).getPluckedDataWithName()

  azureStorageQuery = Q.all(azureStorageQueries).then (results) ->
    azureStorage: results

  promises.push azureStorageQuery

  Q.all(promises).then (data) ->
    res.contentType 'application/json'
    res.send(JSON.stringify(data))

app.get '/meli/errors/validation_error', (req, res) ->
  service = azure.createTableService process.env['TABLE_AZURE_STORAGE_NAME'], process.env['TABLE_AZURE_STORAGE_SHARED_KEY']
  tableName = 'ConflictStatus'
  query = new azure.TableQuery()
  .select()
  .where('PartitionKey eq ?', 'validation_error')

  service.queryEntitiesAsync(tableName, query, null)
  .then (results) ->
    console.log results
    results[0].entries
  .then (entries) ->
    entries.map (e) ->
      content = parse e.Content._

      productecaResource: e.ResourceFromMessage._
      meliResource:
        uri: content.RequestInformation.URI
        method: content.RequestInformation.HttpMethod
        body: parse _.findWhere(content.RequestInformation.Parameters, Type: 'RequestBody').Value
        errorMessage: content.RequestError.Message
      user:
        type: e.AuthenticationType._
        id: e.User._
      time: e.Timestamp._
  .then (results) ->
    res.contentType 'application/json'
    res.send(JSON.stringify(results))

app.listen app.get('port'), () ->
  console.log "listening on port #{app.get('port')}"
