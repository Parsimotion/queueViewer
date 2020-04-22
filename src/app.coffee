express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
azure = Promise.promisifyAll require('azure')
StorageQueueService = require("./domain/storage.queue.service")

winston = require("winston")
{ format } = winston

logger = winston.createLogger {
  level: 'debug',
  format: format.combine(
    format.splat(),
    format.simple()
  )
  transports: [
    new winston.transports.Console {}
  ]
}

sbcs = process.env['SB_CONNECTION_STRING']
credentials = process.env['STORAGE_CREDENTIALS']
logger.silly "Credentials Servicebus %s", sbcs
logger.silly "Credentials Azure storage %s", credentials

credentials = JSON.parse credentials if credentials

parse = (it) -> JSON['parse'] it

app = express()

exports.app = app

app.set 'port', process.env.port or 4000
app.use bodyParser()




class ServiceBusService
  constructor: (connectionString) ->
    @serviceBusService = azure.createServiceBusService connectionString

  getData: =>
    @serviceBusService.listTopicsAsync()
    .get 0
    .then (topics) =>
      Promise.map topics, (topic) =>
        @serviceBusService.listSubscriptionsAsync(topic.TopicName)
        .then (result) =>
          queuesInformation = result[0].map (sbQueueData) =>
            name: sbQueueData.SubscriptionName
            data:
              ActiveMessageCount: sbQueueData.CountDetails['d2p1:ActiveMessageCount']
              DeadLetterMessageCount: sbQueueData.CountDetails['d2p1:DeadLetterMessageCount']
              Status: sbQueueData.Status
              Topic: topic.TopicName
          _.zipObject(_.map(queuesInformation, 'name'), _.map(queuesInformation, 'data'))

app.get '/', (req, res) ->
  promises = []

  if sbcs
    sbcs.split(',').forEach (connection) ->
      name = connection.match(/Endpoint=sb:\/\/(.+)\.servicebus\.windows\.net/)[1]
      logger.debug("Retrieve sb from %s", name)
      serviceBusQuery = 
        new ServiceBusService(connection).getData()
        .then (result) -> { "#{name}-servicebus": result }
        .tap (result) -> logger.silly "Status services=%j", result

      promises.push serviceBusQuery
  
  if credentials
    azureStorageQuery = 
      Promise.map credentials, (credential) -> new StorageQueueService(credential.name, credential.shared).getPluckedDataWithName()
      .then (results) -> { azureStorage: results }
  
    promises.push azureStorageQuery

  Promise.all(promises).then (data) ->
    res.contentType 'application/json'
    res.send(JSON.stringify(data))

app.listen app.get('port'), () ->
  console.log "listening on port #{app.get('port')}"
