_ = require('lodash')
require("coffee-script/register")

try { _.assign(process.env, require("./config/environment/local.env") ) } catch (err) {}

require('./app.coffee');