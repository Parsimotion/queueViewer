_ = require 'lodash'
AWS = require 'aws-sdk'
Promise = require 'bluebird'

module.exports = 
class SQSQueueService
  constructor: ({ access, secret, region = "us-east-1" }) ->
    @client = new AWS.SQS { 
      apiVersion: '2012-11-05',
      accessKeyId: access,
      secretAccessKey: secret,
      region
    }
    @storageName = "aws"

  getPluckedDataWithName: =>
    @getPluckedData().then (queuesResults) =>
      _.zipObject [@storageName], [queuesResults]
  
  getPluckedData: =>
    @getData().then (queuesResults) ->
      _.zipObject(_.map(queuesResults, 'name'), _.map(queuesResults, 'quantity'))
  
  getData: =>
    @_getQueueNames()
    .map (result) => result.name
    .map (name) =>
      Promise.resolve(name)
      .then (name) => @queueSvc.getQueueMetadataAsync(name, null)
      .then (result) =>
        { name, quantity: result[0].approximatemessagecount }
    
  _getQueueNames: =>
    @_promisify(@client.listQueues)()
    .get "QueueUrls"
    .map (queueUrl) => Promise.props {
      name: _(queueUrl).split("/").last(),
      count:  @_queueCount(queueUrl)
    }
    .then (result) =>
      console.log "aaaa",result
#      result[0].entries
  _queueCount: (QueueUrl) =>
    countKey = "ApproximateNumberOfMessages"
    @_promisify(@client.getQueueAttributes)({
      QueueUrl,
      AttributeNames: [countKey]
    }).get("Attributes").get(countKey)

  _promisify: (fn) => Promise.promisify(fn).bind(@client)
