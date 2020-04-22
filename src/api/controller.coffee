Promise = require("bluebird")
{ serviceBusConnectionsStrings, azureStorageCredentials } = require("../config/environment")
logger = require("../domain/logger") "controller"

StorageQueueService = require("../domain/storage.queue.service")
ServiceBusService = require("../domain/servicebus.service")

module.exports =

    index: ->
        promises = []

        if serviceBusConnectionsStrings
            serviceBusConnectionsStrings.split(',').forEach (connection) ->
                name = connection.match(/Endpoint=sb:\/\/(.+)\.servicebus\.windows\.net/)[1]
                logger.debug("Retrieve sb from %s", name)
                serviceBusQuery = 
                    new ServiceBusService(connection).getData()
                    .then (result) -> { "#{name}-servicebus": result }

                promises.push serviceBusQuery
        
        if azureStorageCredentials
            azureStorageQuery =
                Promise.map azureStorageCredentials, (credential) -> new StorageQueueService(credential.name, credential.shared)
                .map (service) -> service.getPluckedDataWithName()
                .then (results) -> { azureStorage: results }
            
            promises.push azureStorageQuery

        Promise.all(promises)