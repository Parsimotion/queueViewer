express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
logger = require("./domain/logger") "app"

app = express()

exports.app = app

app.set 'port', process.env.PORT or 9000
app.use bodyParser()

app.get '/', require("./api")

app.listen app.get('port'), () ->
  logger.info "listening on port #{app.get('port')}"
