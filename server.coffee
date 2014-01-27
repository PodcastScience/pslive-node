

require('coffee-script')
express = require('express')
routes = require('./routes')
user = require('./routes/user')
http = require('http')
https = require('https')
fs = require('fs')
path = require('path')
md5 = require('MD5')
mu = require('mu2')
validator = require('validator')

# google api
googleapis = require('googleapis')
readline = require('readline')
CLIENT_ID = process.env.GOOGLE_ID
CLIENT_SECRET = process.env.GOOGLE_SECRET
REDIRECT_URL = 'https://podcastscience.herokuapp.com/oauth2callback'
SCOPE = 'https://www.googleapis.com/auth/drive.file'

# https
options =
  key: fs.readFileSync('server.key').toString()
  cert: fs.readFileSync('server.crt').toString()

rl = readline.createInterface
  input: process.stdin
  output: process.stdout
auth = new googleapis.OAuth2Client(CLIENT_ID, CLIENT_SECRET, REDIRECT_URL);




app = express()

# functions
replaceURLWithHTMLLinks = (text) ->
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
  return text.replace(exp,"<a href='$1' target='_blank'>$1</a>")



#all environments
app.use require('connect-assets')()
app.set('port', process.env.PORT || 3000)
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon("/images/fav.png"));
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));


app.locals.css = css
app.locals.js = js

#development only
if ('development' == app.get('env'))
  app.use(express.errorHandler());


url = auth.generateAuthUrl({ scope: SCOPE })
console.log('Visit the url: ', url);







app.get('/', routes.index);

app.get '/oauth2callback', (req, res) ->
  code = req.query.code
  console.log "code : #{code}"
  auth.getToken code, (err, tokens) ->
    if (err)
      console.log('Error while trying to retrieve access token', err)
      return
    auth.credentials = tokens
    googleapis.discover('drive', 'v2').execute (err, client) ->
      client.drive.files
      .list
        maxResults: 10,
        q: "160"
      .withAuthClient(auth).execute(console.log)
  res.send "<h1>DONE!</h1>"

app.get('/admin', routes.admin);
app.get('/users', user.list);
app.get '/messages', (req, res) ->
  res.send all_messages.map((message) -> "<b>#{message.user.username} :</b> #{message.message}").join("<br/>")

httpServer = http.createServer(app).listen(app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))
)

https_port = 443 
https_port = 7675
httpsServer = https.createServer(options, app).listen(https_port, ->
  console.log('Express server listening https on port ' + https_port)
)

io = require('socket.io').listen(httpServer)

io.configure ->
  io.set("transports", ["xhr-polling"])
  io.set("polling duration", 10)
  io.set('close timeout', 20)
  # io.set('log colors',false)
  # io.set('log level',0)


users = new Object()
nb_conex = 0
all_messages = []
last_messages = []
history = 10
admin_password = process.env.PSLIVE_ADMIN_PASSWORD
livedraw_iframe = "Pas de dessins ce soir :("

io.sockets.on 'connection', (socket) ->
  console.log "Nouvelle connexion... ("+io.sockets.clients().length+" sockets)"

  # mise a jour du conmpteur de connectes
  nb_conex += 1
  io.sockets.emit('update_compteur',nb_conex)

  # gestion des utilisateurs
  me = false  



  for key, value of users
    socket.emit('newuser',value)

  for message in last_messages
    socket.emit('nwmsg',message)
    console.log(socket.id)

  socket.emit('new-drawings',livedraw_iframe)

  socket.on 'login', (user) ->

    try 
      validator.isEmail(user.mail)
    catch
      socket.emit('error',"Email invalide")

    try
      validator.isLength(user.username,3,30)
    catch
      socket.emit('error',"Le nom d'utilisateur doit être compris entre 3 et 30 lettres")

    try 
      validator.isEmail(user.mail)
      validator.isLength(user.username,3,30)

      # check if user already exist
      for key, existing_user of users
        if user.mail == existing_user.mail
          me = existing_user 
          console.log 'user already exist!'

      unless me
        me = user
  #      me.id = user.mail.replace('@','-').replace(/\./gi, "-")
        me.id = Date.now()
        me.avatar = 'https://gravatar.com/avatar/' + md5(user.mail) + '?s=40'
        users[me.id] = me
        io.sockets.emit('newuser',me)

      socket.emit('logged')




  socket.on 'disconnect', ->
    console.log(me.username+" s'est deconnecté...")
    nb_conex = nb_conex - 1    
    io.sockets.emit('update_compteur',nb_conex)
    console.log("nombre d'utilisateurs : "+nb_conex)
    console.log('me : '+me)
    unless me == false
      delete users[me.id]
      io.sockets.emit('disuser',me)


  # gestion des mesages
  socket.on 'nwmsg', (message) ->
    message.user = me
    date = new Date()

    message.message = replaceURLWithHTMLLinks(validator.escape(message.message))

    message.h = date.getHours()
    message.m = date.getMinutes()
    all_messages.push message
    last_messages.push message
    last_messages.shift() if (last_messages.length > history)

    io.sockets.emit('nwmsg',message)

  # Changement d'iframe
  socket.on 'new-iframe', (message) ->
    if message.password == admin_password
      livedraw_iframe = message.iframe
      io.sockets.emit('new-drawings',livedraw_iframe)

  # test

  # socket.on 'test', ->
  # 	console.log(users)













