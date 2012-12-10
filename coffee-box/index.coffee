express       = require 'express'
app           = module.exports = express()
assets        = require 'connect-assets'
flash         = require 'connect-flash'
mongoose      = require 'mongoose'
{requireDir}  = require './lib/require_dir'

ROOT_DIR = "#{__dirname}/.."

app.configure ->
  app.set 'version', require("#{ROOT_DIR}/coffee-box.config.json").version
  app.set k, v for k, v of require("#{ROOT_DIR}/coffee-box.config.json")
  app.set 'utils', requireDir("#{ROOT_DIR}/coffee-box/lib")
  app.set 'helpers', requireDir("#{ROOT_DIR}/coffee-box/helpers")
  app.set 'models', requireDir("#{ROOT_DIR}/coffee-box/models")
  app.settings.models.Config.Load (err,config)->
    if err
      console.error err
      return process.exit 1
    app.locals.config = config.toJSON()
    app.locals.coffeeBox =
      version: app.settings.version
      nodejsVersion: process.version

  app.set 'controllersGetter', requireDir("#{ROOT_DIR}/coffee-box/controllers")
  app.set 'views', "#{ROOT_DIR}/coffee-box/views"
  app.set 'view engine', 'jade'
  app.set 'view options', layout: "#{ROOT_DIR}/coffee-box/views/layouts/layout"
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser()
  app.use express.session(secret: app.settings.secretKey)
  app.use flash()
  app.use assets(src: 'coffee-box/assets', build: true, detectChanges: false, buildDir: false)
  app.use express.static("#{ROOT_DIR}/coffee-box/public")

  # make some 2.x-style compatible helpers
  app.locals[k]=v for k,v of app.settings.helpers
  app.use (req,res,next)->
    res.locals.messages = require('express-messages')(req,res)
    res.locals.session = req.session
    next()

  app.use app.router
  app.use require './lib/exceptions'

app.configure 'development', ->
  app.use express.errorHandler(dumpException: true, showStack: true)

app.configure 'production', ->
  app.use express.errorHandler()

mongoose.connect app.settings.dbpath, (err) ->
  if err
    console.error err
    return process.exit()
require('./routes') app