Promise = require 'bluebird'
azureStorage = Promise.promisifyAll require('azure-storage')

module.exports = 
class StorageQueueService
  constructor: (@storageName, @storageSharedKey) ->
    @queueSvc = azureStorage.createQueueService @storageName, @storageSharedKey

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
    @queueSvc.listQueuesSegmentedAsync(null, null).then (result) ->
      result[0].entries