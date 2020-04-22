express = require 'express'
bodyParser = require 'body-parser'
Promise = require 'bluebird'
logger = require("./domain/logger") "app"

app = express()

exports.app = app

app.set 'port', process.env.port or 4000
app.use bodyParser()

app.get '/', require("./api")

app.listen app.get('port'), () ->
  console.log "listening on port #{app.get('port')}"
