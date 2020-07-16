Promise = require 'bluebird'
azure = Promise.promisifyAll require('azure')
PAGE_SIZE = parseInt(process.env.SERVICEBUS_PAGE_SIZE) or 100

module.exports = 
class ServiceBusService
  constructor: (connectionString) ->
    @serviceBusService = azure.createServiceBusService connectionString

  getData: =>
    @serviceBusService.listTopicsAsync()
    .get 0
    .then (topics) =>
      Promise.map topics, (topic) =>
        Promise.all([
          @serviceBusService.listSubscriptionsAsync(topic.TopicName, { skip: 0, top: PAGE_SIZE }),
          @serviceBusService.listSubscriptionsAsync(topic.TopicName, { skip: PAGE_SIZE, top: PAGE_SIZE })
        ])
        .spread ([page1], [page2]) => page1.concat page2
        .then (result) =>
          queuesInformation = result.map (sbQueueData) =>
            name: sbQueueData.SubscriptionName
            data:
              ActiveMessageCount: sbQueueData.CountDetails['d2p1:ActiveMessageCount']
              DeadLetterMessageCount: sbQueueData.CountDetails['d2p1:DeadLetterMessageCount']
              Status: sbQueueData.Status
              Topic: topic.TopicName
          _.zipObject(_.map(queuesInformation, 'name'), _.map(queuesInformation, 'data'))
