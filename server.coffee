

require('coffee-script')
express = require('express')
routes = require('./routes')
user = require('./routes/user')
http = require('http')
path = require('path')
md5 = require('MD5')
mu = require('mu2')
validator = require('validator')

app = express()

# functions
replaceURLWithHTMLLinks = (text) ->
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
  return text.replace(exp,"<a href='$1' target='_blank'>$1</a>")



#all environments
app.use require('connect-assets')()
console.log js('client')
app.set('port', process.env.PORT || 3000)
app.set('views', __dirname + '/views')
app.set('view engine', 'jade')
app.use(express.favicon("/images/fav.png"))
app.use(express.logger('dev'))
app.use(express.bodyParser())
app.use(express.methodOverride())
app.use(app.router)
app.use(express.static(path.join(__dirname, 'public')))

app.locals.css = css
app.locals.js = js

#development only
if ('development' == app.get('env'))
  app.use(express.errorHandler())


app.get('/', routes.index)
app.get('/admin', routes.admin)
app.get('/users', user.list)
app.get '/messages', (req, res) ->
  res.send all_messages.map((message) -> "<b>#{message.user.username} :</b> #{message.message}").join("<br/>")
app.get '/noshary', (req, res) ->
  res.send "Pas de dessins ce soir :("

httpServer = http.createServer(app).listen(app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))
)


io = require('socket.io').listen(httpServer)

io.configure ->
  io.set("transports", ['websocket','flashsocket','htmlfile','xhr-polling','jsonp-polling'])
  #io.set("polling duration", 100)
  #io.set('close timeout', 200)
  io.set('heartbeat timeout', 200)
  # io.set('log colors',false)
  # io.set('log level',0)




#fonction pour compter (.length ne marche pas.... a voir)
compte = (tab)->
  cpt=0
  for key,elt of tab
    cpt=cpt+1
  return cpt


#Initialisation des variables
users = new Object()
liste_connex    = []
all_messages    = []
last_messages   = []
history         = 10
console.log('Init de la liste des connexions: '+compte(liste_connex)+' connexion(s)')
admin_password = process.env.PSLIVE_ADMIN_PASSWORD
livedraw_iframe = "/noshary"
episode = 'Bienvenue sur le balado qui fait aimer la science!'
io.sockets.on 'connection', (socket) ->
  console.log "Nouvelle connexion... ("+io.sockets.clients().length+" sockets)"



  #connexion a la page de live. L'utilisateur n'est pas connecté.
  #Les valeurs sont donc initialisées pour cela
  me = false
  id_connexion= false



  #Envoi des messages récents au client
  for message in last_messages
    socket.emit('nwmsg',message)

  #Envoi des parametres du live
  socket.emit('new-drawings',livedraw_iframe)
  socket.emit('new-title',episode)
    
    
    
    
  # gestion de la connexion au live. Le client evoi un Hello au serveur
  # qui lui reponf Olleh avec un id qui permettra de au serveur de s'assurer
  # que le client est connu (notamment compté)
  socket.on 'Hello', ->
    #calcul de l'id
    id_connexion = md5(Date.now())
    liste_connex[id_connexion]=''
    
    #envoi de Olleh
    console.log('Hello recu. Envoi du Olleh')
    socket.emit('Olleh',id_connexion)
    
    #mise a jour du compteur et de la userlist pour tous les connectés
    io.sockets.emit('update_compteur',compte(liste_connex))
    console.log('Ouverture de la connexion '+id_connexion+'. '+compte(liste_connex)+' connexions ouvertes')
    for key, value of users
      console.log('Ajout du user '+value.mail)
      socket.emit('newuser',value)
    
    
    
    
    
  #Login : l'utilisateurs se connecte a la Chatroom
  socket.on 'login', (user) ->
    #Verification si le client est connu. dans le cas contraire, on le deconnecte
    verif_connexion(id_connexion_loc)
        
    #Verification de la validité de l'identification
    unless  validator.isEmail(user.mail)
      socket.emit('erreur',"Email invalide")
      return -1
    unless validator.isLength(user.username,3,30)
      socket.emit('erreur',"Le nom d'utilisateur doit être compris entre 3 et 30 lettres")
      return -1

    
    try

      # Verification de l'existance de l'utilisateur
      # Le cas échéant, on incremente un compteur
      for key, existing_user of users
        console.log 'Verif '+existing_user.mail+'/'+existing_user.username
        if (user.mail == existing_user.mail) && (user.mail!='')
          me = existing_user
          console.log '\tuser already exist!'
          me.cpt += 1
          console.log '\tcpt '+me.mail+':'+me.cpt

      #dans le cas contraire, on le créé dans la userlist
      unless me
        me = user
        #me.id = user.mail.replace('@','-').replace(/\./gi, "-")
        me.id = Date.now()
        me.cpt=1
        console.log 'cpt '+me.mail+':'+me.cpt
        me.avatar = 'https://gravatar.com/avatar/' + md5(user.mail) + '?s=40'
        users[me.id] = me
        #on informe tout le monde qu'un nouvel utilisateur s'est connecté
        io.sockets.emit('newuser',me)
        
      #on informe l'utilisateur qu'il est bien cnnecté
      socket.emit('logged')

  
        
        
#verif_connexion=()->
#    console.log("Verif si l'user "+me.name+" existe")
#    for key, existing_user of users
#      console.log(existing_user.name)
#      if (me.id == existing_user.id)
#        return true
#    console.log("Un utilisateur inconnu s'est connecté. son nom:"+me.name)
#    socket.emit('disconnect',"Utilisateur inconnu")
#    return false



  #Verification de la connection
  verif_connexion=(id_connexion_loc)->
    console.log("Verif si la connexion "+id_connexion_loc+" existe")
    for key, val of liste_connex
      console.log(key)
      if (key == id_connexion_loc)
        return true
    #Si ce n'est pas le cas, on le deconnecte.
    #Sa reaction sera normalement de se reconnecter proprement immediatement
    console.log("Une connexion inconnu a été repérée")
    socket.emit('disconnect',"Utilisateur inconnu")
    return false



 #Serie de fonctions gérant la deconnexion
  deconnexion=() ->
    #On supprime la connexion de la liste
    console.log('Suppression de la connexion '+id_connexion)
    delete liste_connex[id_connexion]
    #on met a jour le compteur des autres users
    io.sockets.emit('update_compteur',compte(liste_connex))
    console.log("Nombre d'utilisateurs : "+compte(liste_connex))
    #si le une connexion a la chatroom existe, on le delg
    unless me == false
      logout()
    

  #gestion de la deconnexion de la chatroom
  logout=() ->
    #on decremente le compteur de cnx du l'utilisateur
    me.cpt -= 1
    console.log 'cpt '+me.mail+':'+me.cpt
    unless(me.cpt > 0)
      #si le compteur arrive a 0, on le supprime de la userlist
      #et on en informe les autres clients
      delete users[me.id]
      io.sockets.emit('disuser',me)




  socket.on 'disconnect', ->
    #gestion de la coupure de connexion du client
    console.log 'Deconnexion de '+me.name
    if verif_connexion(id_connexion_loc)
      deconnexion()



  # gestion des messages
  socket.on 'nwmsg', (message) ->
    if verif_connexion(id_connexion_loc)
      message.user = me
      date = new Date()
      message.message = replaceURLWithHTMLLinks(validator.escape(message.message))
      message.h = date.getHours()
      message.m = date.getMinutes()
      all_messages.push message
      last_messages.push message
      last_messages.shift() if (last_messages.length > history)
      io.sockets.emit('nwmsg',message)

  
            

  #GESTION DE L'admin (qui n'envoi pas de HELLO)
            



  # Changement du titre
  socket.on 'change-title', (message) ->
    if message.password == admin_password
      livedraw_iframe='http://www.sharypic.com/events/ps'+(message.number)+'/widget'
      episode= "<span class='number'> Episode #"+(message.number)+" - </span> "+message.title
      io.sockets.emit('new-drawings',livedraw_iframe)
      io.sockets.emit('new-title',episode)
        
        
        
  # test

  # socket.on 'test', ->
  # 	console.log(users)




