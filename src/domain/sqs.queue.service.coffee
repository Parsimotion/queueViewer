Promise = require 'bluebird'
AWS = require('aws-sdk')

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
    @_promisify(@client.listQueues)().then (result) ->
      console.log "aaaa",result
#      result[0].entries

  _promisify: (fn) => Promise.promisify(fn).bind(@client)
