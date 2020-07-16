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

  getData: =>
    @_promisify(@client.listQueues)()
    .get "QueueUrls"
    .map (queueUrl) => Promise.props {
      name: _(queueUrl).split("/").last(),
      quantity:  @_queueCount(queueUrl)
    }
    .map ({ name, quantity}) => [name, quantity]
    .then _.fromPairs 
    .then (sqs) => { sqs }

  _queueCount: (QueueUrl) =>
    countKey = "ApproximateNumberOfMessages"
    @_promisify(@client.getQueueAttributes)({
      QueueUrl,
      AttributeNames: [countKey]
    }).get("Attributes").get(countKey)

  _promisify: (fn) => Promise.promisify(fn).bind(@client)
