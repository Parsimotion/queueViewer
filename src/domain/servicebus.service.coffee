Promise = require 'bluebird'
azure = Promise.promisifyAll require('azure')

module.exports = 
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
