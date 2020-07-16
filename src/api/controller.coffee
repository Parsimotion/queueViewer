Promise = require("bluebird")
{ serviceBusConnectionsStrings, azureStorageCredentials, sqsCredentials } = require("../config/environment")
logger = require("../domain/logger") "controller"

SQSQueueService = require("../domain/sqs.queue.service")
StorageQueueService = require("../domain/storage.queue.service")
ServiceBusService = require("../domain/servicebus.service")

CURRENT_OPERATION = null

_queues = _.memoize (currentOperation) ->
    promises = []

    if serviceBusConnectionsStrings
        promises.push(
            Promise.map serviceBusConnectionsStrings.split(','), (connection) ->
                name = connection.match(/Endpoint=sb:\/\/(.+)\.servicebus\.windows\.net/)[1]
                logger.debug("Retrieve sb from %s", name)
                new ServiceBusService(connection).getData()
                    .then (result) -> { "#{name}-servicebus": result }
        )

    if azureStorageCredentials
        promises.push(
            Promise.map azureStorageCredentials, (credential) -> new StorageQueueService(credential.name, credential.shared)
            .map (service) -> service.getPluckedDataWithName()
            .then (results) -> { azureStorage: results }
        )
    if sqsCredentials
        promises.push(
            new SQSQueueService(sqsCredentials).getData()
            .then (results) -> [{ aws: results }]
        )

    Promise.all promises
    .then _.flattenDeep
    .finally _refreshCurrentOperation

_refreshCurrentOperation = () -> 
    CURRENT_OPERATION = parseInt(Math.random() * 9999999999)
    _queues.cache.clear()

_refreshCurrentOperation()

module.exports =
    index: -> _queues CURRENT_OPERATION
