logger = require("../../domain/logger") "config"

config = {
    serviceBusConnectionsStrings: process.env['SB_CONNECTION_STRING']
    azureStorageCredentials: JSON.parse(process.env['STORAGE_CREDENTIALS'] or "[]")
}

logger.debug "Config %j", config

module.exports = config