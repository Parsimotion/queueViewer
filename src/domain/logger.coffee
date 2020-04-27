winston = require("winston")
{ format } = winston

module.exports = (service) -> winston.createLogger {
  level: 'debug',
  format: format.combine(
    format.splat(),
    format.simple()
  ),
  defaultMeta: { service },
  transports: [
    new winston.transports.Console {}
  ]
}