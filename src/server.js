_ = require('lodash')
require("coffee-script/register")

try { _.assign(process.env, require("./config/environment") ) } catch (err) {}

require('./app.coffee');