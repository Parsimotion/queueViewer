Promise = require("bluebird")
{ serviceBusConnectionsStrings, azureStorageCredentials } = require("../config/environment")
logger = require("../domain/logger") "controller"

StorageQueueService = require("../domain/storage.queue.service")
ServiceBusService = require("../domain/servicebus.service")

module.exports =

    index: ->
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

        Promise.all promises
        .then _.flattenDeep