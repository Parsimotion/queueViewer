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
        pageCount = Math.ceil(parseInt(topic.SubscriptionCount) / PAGE_SIZE) or 1
        $pages = _.times pageCount, (i) => @serviceBusService.listSubscriptionsAsync(topic.TopicName, { skip: PAGE_SIZE * i, top: PAGE_SIZE }).get("0")
        Promise.all($pages)
        .then _.flatten
        .then (result) =>
          queuesInformation = result.map (sbQueueData) =>
            name: sbQueueData.SubscriptionName
            data:
              ActiveMessageCount: sbQueueData.CountDetails['d2p1:ActiveMessageCount']
              DeadLetterMessageCount: sbQueueData.CountDetails['d2p1:DeadLetterMessageCount']
              Status: sbQueueData.Status
              Topic: topic.TopicName
          _.zipObject(_.map(queuesInformation, 'name'), _.map(queuesInformation, 'data'))
