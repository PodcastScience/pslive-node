
require('coffee-script')
express = require('express')
routes = require('./routes')
user = require('./routes/user')
http = require('http')
https = require('https')
path = require('path')
md5 = require('MD5')
mu = require('mu2')
validator = require('validator')
AWS = require('aws-sdk')
Twitter = require('./twitter');
#AWS.config.loadFromPath('./configAWS.json');
AWS.config.update({region: 'eu-west-1'});
s3 = new AWS.S3()
fs = require('fs')
mime = require('mime')
app = express()












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








#router
app.get('/', routes.index)
app.get('/admin', routes.admin)
app.get('/users', user.list)
app.get '/image', (req, res) ->
  #console.log images
  console.log "Affichage de l'image "+req.query.nom
  try
    res.end images[req.query.nom] ,'binary'
app.get '/messages', (req, res) ->
  res.send all_messages.map((message) -> "<b>#{message.user.username}:</b> #{message.message}").join("<br/>")
app.get '/timestamp', (req, res) ->
  res.send all_messages.map((message) -> 
    "<b>#{message.user.username}</b> [#{(message.h+2)%24}:#{message.m}:#{message.s}]: <span id='[#{(message.h+2)%24}:#{message.m}:#{message.s}]'>#{message.message}</span>"
  ).join("<br/>")
app.get '/questions', (req, res) ->
  res.send all_messages.filter( (msg,idx) -> 
    if typeof(msg)!='undefined' && typeof(msg.message)!='undefined'
      msg.message.indexOf("@ps")>-1 || msg.message.indexOf("@PS")>-1
    else
      false
  ).map((message) -> 
    "<b>#{message.user.username}</b><a href='/timestamp#[#{(message.h+2)%24}:#{message.m}:#{message.s}]'>[#{(message.h+2)%24}:#{message.m}:#{message.s}]</a>: #{message.message}"
  ).join("<br/>");

httpServer = http.createServer(app).listen(app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))
)





#socket.io configuration
io = require('socket.io').listen(httpServer)
io.configure ->
  io.set("transports", ['websocket','flashsocket','htmlfile','xhr-polling','jsonp-polling'])
  #io.set("polling duration", 100)
  #io.set('close timeout', 200)
  io.set('heartbeat timeout', 200)
  # io.set('log colors',false)
  io.set('log level',0)







#Initialisation des variables
users = new Object()

auth_twitter = {
    consumer_key:         process.env.PSLIVE_TWITTER_CONSUMERKEY,
    consumer_secret:      process.env.PSLIVE_TWITTER_CONSUMERSECRET,
    access_token_key:     process.env.PSLIVE_TWITTER_TOKENKEY,
    access_token_secret:  process.env.PSLIVE_TWITTER_TOKENSECRET
}
console.log auth_twitter
twitter = new Twitter(auth_twitter)

last_messages   = []
all_messages    = []
liste_images    = []
images          = []
history         = 10
nomEvent        = ''
admin_password  = process.env.PSLIVE_ADMIN_PASSWORD
episode         = 'Bienvenue sur le balado qui fait aimer la science!'
bucketName      = process.env.PSLIVE_S3_BUCKET




###############################
####  functions ###############
###############################

#simple
replaceURLWithHTMLLinks = (text) -> 
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
  return text.replace(exp,"<a href='$1' target='_blank'>$1</a>")

replaceSalaud = (text) ->
  exp=/salaud/ig
  retval=text.replace(exp,"salop\*")
  if (text!=retval)
    retval=retval+"<br><span style='font-weight:lighter;font-size:x-small;'>*Correction apportée selon la volonté du DictaTupe.</span>"
  return retval



#fonction pour compter (.length ne marche pas.... a voir)
compte = (tab)->
  cpt=0
  for key,elt of tab
    cpt=cpt+1
  return cpt      
  
pad2 = (val) ->
  if (val<10)
    return  '0'+val
  else
    return val
  
#------------------------------------
#Fonction pour la gestion des images
get_image = (url,cb) ->
  nom=url.slice url.lastIndexOf('/')+1
  console.log "chargement images en RAM : ",url
  http.get url, (response)->
      data=''
      response.setEncoding('binary')
      console.log "reception d'une reponse"
      response.on 'data',
        (chunk)->data+=chunk
        console.log "data"
      response.on 'end',()->
        images[nom]=data
        console.log "Fin du chargement de "+nom+":"+images[nom].length
        cb nom
  return nom

#------------------------------------




maj_S3episode = () ->
  console.log("maj_S3episode : MAJ de l'episode")
  options = {
    Bucket: bucketName,
    Key: 'episodePodcastScience.JSON',
    Body: JSON.stringify({
      'titre':episode,
      'nomEvent':nomEvent
    })
  }
  console.log options
  s3.client.putObject options,(res) ->  console.log('Erreur S3 : '+res) if res != null




maj_S3images_list = () ->
  console.log "maj_S3images_list : MAJ de la liste des images" ,liste_images
  s3.client.putObject({
    Bucket: bucketName,
    Key: 'imagePodcastScience'+nomEvent+'.JSON',
    Body: JSON.stringify(liste_images)
  },(res) ->  console.log('Erreur S3 : '+res) if res != null)




get_S3images_list = (func) ->
  console.log "chargement images"
  try
    s3.client.getObject
      Bucket: bucketName
      Key: 'imagePodcastScience'+nomEvent+'.JSON'
      , (error,res) ->
        console.log "reponse recu"
        if(!error)
          console.log "chargement images ok"
          try
            func JSON.parse(res.Body)
          catch e
            console.log "Echec de la lecture de la liste des images : "+typeof(func),e
        else
          console.log "Erreur chargement images",error
  catch e
    console.log "Erreur",e
  

store_S3images = (nom,data) ->
  console.log("store_S3images : stockage d'une image")
  databin = new Buffer(data, 'binary')
  options = {
    Bucket: bucketName,
    Key: 'images/'+nomEvent+'_'+nom,
    Body: databin,
    ContentType: mime.lookup nom
  }
  s3.client.putObject options ,(res) ->  
    console.log('Erreur S3 : '+res) if res != null


load_S3images = (nom,cb) ->
  console.log("load_S3images : chargement d'une image")
  options = {
    Bucket: bucketName,
    Key: 'images/'+nomEvent+'_'+nom
  }
  s3.client.getObject options ,(error,res) ->
      console.log "reponse recu"
      if(!error)
        images[nom]=res.Body
        cb() 
      else
        console.log "Erreur chargement image "+nomEvent+'_'+nom,error



#########################################
### Fin des fonctions ###################
#########################################






## Chargement de la chatroom dans Amazon S3
s3.client.getObject
  Bucket: bucketName
  Key: 'episodePodcastScience.JSON'
  , (error,res) ->
    if(!error)
      console.log "chargement episode ok"
      try
        jsonData=JSON.parse(res.Body)
        nomEvent=jsonData.nomEvent
        episode=jsonData.titre
        get_S3images_list (val)->
          liste_images=val
          for im in liste_images
            load_S3images im.nom, ()->
        twitter.stream {track: '#'+nomEvent} 
      catch e
        console.log "erreur",e
      
    else
      console.log "erreur chargement episode"
  








#Chargement de l'historique des messages
liste_connex    = []
s3.client.getObject({
  Bucket: bucketName,
  Key: 'messagesPodcastScience.JSON'
}, (error,res) ->
  if(!error)
    all_messages=JSON.parse(res.Body)
    for msg in all_messages
      #console.log("chargement derniers messages:"+msg.message)
      last_messages.push msg
      last_messages.shift() if (last_messages.length > history)
  #console.log(JSON.stringify(all_messages))
)
console.log('Init de la liste des connexions: '+compte(liste_connex)+' connexion(s)')










io.sockets.on 'connection', (socket) ->
  console.log "Nouvelle connexion... ("+io.sockets.clients().length+" sockets)"



  #connexion a la page de live. L'utilisateur n'est pas connecté.
  #Les valeurs sont donc initialisées pour cela
  me = false
  id_connexion= false
  cpt_message=0
  id_last_message=""

  envoieInitialChatroom = () ->
    console.log("envoi de l'historique")
    #Envoi des messages récents au client
    for message in last_messages
      socket.emit('nwmsg',message)
    for im in liste_images
      console.log im
      socket.emit('add_img',im) 
    console.log episode
    socket.emit('new-title',episode)
    
    
    
    
  # gestion de la connexion au live. Le client evoi un Hello au serveur
  # qui lui reponf Olleh avec un id qui permettra de au serveur de s'assurer
  # que le client est connu (notamment compté)
  socket.on 'Hello', (id_demande) ->
    #calcul de l'id
    if(id_demande=='')
      console.log("generation de l'id")
      id_connexion = md5(Date.now())
    else
      id_connexion = id_demande
    liste_connex[id_connexion]=''
    
    #envoi de Olleh
    console.log('Hello recu. Envoi du Olleh : '+id_connexion)
    socket.emit('Olleh',id_connexion)
    if(id_demande=='')
      envoieInitialChatroom()
    #mise a jour du compteur et de la userlist pour tous les connectés
    io.sockets.emit('update_compteur',{
      connecte:compte(users),
      cache:compte(liste_connex)-compte(users)
    })
    console.log('Ouverture de la connexion '+id_connexion+'. '+compte(liste_connex)+' connexions ouvertes')
    for key, value of users
      console.log('Ajout du user '+value.mail)
      socket.emit('newuser',value)
    
    
    
    
    
  #Login : l'utilisateurs se connecte a la Chatroom
  socket.on 'login', (user) ->
    #Verification si le client est connu. dans le cas contraire, on le deconnecte
    verif_connexion(user.id_connexion)
        
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
        #console.log 'Verif '+existing_user.mail+'/'+existing_user.username
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
        
        io.sockets.emit('update_compteur',{
          connecte:compte(users),
          cache:compte(liste_connex)-compte(users)
        })
      #on informe l'utilisateur qu'il est bien cnnecté
      socket.emit('logged')

  
        
      


  #Verification de la connection
  verif_connexion=(id_connexion_loc)->
    console.log("Verif si la connexion "+id_connexion_loc+" existe")
    for key, val of liste_connex
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
    io.sockets.emit('update_compteur',{
      connecte:compte(users),
      cache:compte(liste_connex)-compte(users)
    })
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
      io.sockets.emit('update_compteur',{
        connecte:compte(users),
        cache:compte(liste_connex)-compte(users)
      })



  socket.on 'disconnect', ->
    #gestion de la coupure de connexion du client
    console.log 'Deconnexion de '+me.name
    if verif_connexion(id_connexion)
      deconnexion()



  # gestion des messages
  socket.on 'nwmsg', (message) ->
    if verif_connexion(message.id_connexion)
      cpt_message+=1
      message.user = me
      date = new Date()
      message.message = replaceURLWithHTMLLinks(validator.escape(message.message))
      message.message = replaceSalaud(message.message)
      id_last_message = md5(Date.now()+cpt_message+message.user.mail)
      message.id = id_last_message
      message.h = pad2(date.getHours())
      message.m = pad2(date.getMinutes())
      message.s = pad2(date.getSeconds()) 
    #  if(me.mail=="scienceabilly@gmail.com" )
    #    me.username=me.username+' (Bande de Batards !)'
      all_messages.push message
      last_messages.push message
      last_messages.shift() if (last_messages.length > history)
      io.sockets.emit('nwmsg',message)
      s3.client.putObject({
        Bucket: bucketName,
        Key: 'messagesPodcastScience.JSON',
        Body: JSON.stringify(all_messages)
      },(res) ->  console.log('Erreur S3 : '+res) if res != null)   
   
    
  socket.on 'editmsg', (message) -> 
    console.log("demande de modif de message : "+message.message)
    if verif_connexion(message.id_connexion)
      message.message = replaceURLWithHTMLLinks(validator.escape(message.message))
      message.message = replaceSalaud(message.message)
      message.id = id_last_message
      io.sockets.emit('editmsg',message)
      twitter.destroy()
      for key,elt of all_messages
        elt.message = message.message if elt.id == id_last_message
      for key,elt of last_messages
        elt.message = message.message if elt.id == id_last_message
      s3.client.putObject({
        Bucket: bucketName,
        Key: 'messagesPodcastScience.JSON',
        Body: JSON.stringify(all_messages)
      },(res) ->  console.log('Erreur S3 : '+res) if res != null)   
    
  #GESTION DE L'admin (qui n'envoi pas de HELLO)
            


  # Changement du titre et chargement de l'iframe
  socket.on 'change-title', (message) ->
    nomEvent= 'ps' +message.number
    if message.password == admin_password   
      episode= "<span class='number'> Episode #"+(message.number)+" - </span> "+message.title
      maj_S3episode()
      try
        twitter.destroy()
      try
        twitter.stream {track: '#'+nomEvent} 
      catch e
        console.log "erreur Twitter",e
      io.sockets.emit('new-title',episode)
      #maj_S3episode()
        
 



  # Reitinialisation de la chatroom
                
  socket.on 'reinit_chatroom', (password) ->
    if password == admin_password
      console.log("Reinitiailisation de la chatroom")
      episode='Bienvenue sur le balado qui fait aimer la science!'
      last_messages = []  
      all_messages = []
      liste_images = []
      images =[]
      try
        s3.client.putObject({
          Bucket: bucketName,
          Key: 'imagePodcastScience'+nomEvent+'.JSON',
          Body: JSON.stringify(liste_images)
        },(res) ->  console.log('Erreur S3 : '+res) if res != null)
        nomEvent=""
        s3.client.putObject({
          Bucket: bucketName,
          Key: 'episodePodcastScience.JSON',
          Body: JSON.stringify({
            'titre':episode,
            'nomEvent':''
          }),  
        },(res) ->  console.log('Erreur S3 : '+res) if res != null)
        s3.client.putObject({
          Bucket: bucketName,
          Key: 'messagesPodcastScience.JSON',
          Body: JSON.stringify(all_messages)
        },(res) ->  console.log('Erreur S3 : '+res) if res != null)
      catch e 
        console.log "erreur S3"+e
      io.sockets.emit('del_msglist')
      io.sockets.emit('del_imglist')
      get_S3images_list (val)->
        liste_images=val
        for im in liste_images
          load_S3images im.nom , (param_img)->io.sockets.emit 'add_img',im
      io.sockets.emit('new-title',episode)

  




twitter.on 'data', (data) -> 
  console.log "reception : ",data
  try
    url         = data.entities.media[0].media_url
    poster      = data.user.name
    poster_user = data.user.screen_name
    avatar      = data.user.profile_image_url
    tweet       = data.text
  catch e
  return 0 if (url==null) || (typeof(url) == 'undefined')
  nom=get_image url, (nom)-> 
    param_img={
      'nom' : nom, 
      'poster':poster,
      'poster_user':poster_user,
      'avatar':avatar,
      'tweet':replaceURLWithHTMLLinks tweet
    }
    liste_images.push param_img 
    io.sockets.emit 'add_img',param_img
    store_S3images nom, images[nom]
    maj_S3images_list()
  console.log 'media:'+ nom
  



twitter.on 'error', (data) -> 
  io.sockets.emit "errorTwitter",data


twitter.on 'heartbeat', (data) -> 
  console.log  "Twitter stream is alive"
  io.sockets.emit 'heartbeat_twitter'

twitter.on 'close', (data) -> 
  console.log  "Twitter stream is closed :",data
  twitter = new Twitter(auth_twitter) 


