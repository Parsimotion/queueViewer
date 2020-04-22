express = require("express") 
router = express.Router()
{ route } = require("endpoint-handler") router
{ index } = require("./controller")

route.get "/", index

module.exports = router
