$(document).ready ->

  # $(window).konami
  #     cheat: ->
  #       alert "C'est pas bien de diviser par zéro..."

  connect_url = "/"
  id_connexion= false
  username=""
  email=""
  last_msg_id = false
  last_msg_txt = ""  
  userlist = []
  socket = io.connect(connect_url)
  msg_template = $('#message-box').html()
  $('#message-box li').remove()
  user_box_template = $('#user_box').html()
  $('#user_box').remove()




  highlightPseudo= (text) ->
    userref=''
    equiv=[]
    userlist.sort((a,b)-> b.length-a.length)
    for u in userlist 
      idx="i"+(Math.floor((90000000000)*Math.random())+10000000000);
      equiv.push { 'idx' : idx , 'name' : u }
      pattern=RegExp("@("+u+")","ig")
      text=text.replace(pattern,"@"+idx)
    for val in equiv 
      pattern=RegExp("@("+val.idx+")","ig")
      unless val.name==username
        text=text.replace(pattern,"@"+val.name)
      else
        text=text.replace(pattern,"<span class='mypseudo'>@"+val.name+"</span>")
    return text

  ircLike= (text,pseudo) -> 
    stringTab = text.split(" ")
    stringMe = text.split("/me")     
    valeurRetour =""
    if stringTab.length >= 2
      if stringTab[0].localeCompare("/me")==0
        valeurRetour = "<i> "
        valeurRetour = valeurRetour.concat(pseudo) 
        valeurRetour = valeurRetour.concat(stringMe[1])
        valeurRetour = valeurRetour.concat("</i>")
      else
        valeurRetour=text
    else
      valeurRetour=text
    return valeurRetour

  unless window.location.pathname=='/admin'
    #console.log('Envoi du Hello initial') 
    socket.emit('Hello','')

    slider=$('#slider').lightSlider({
      gallery:true,
      minSlide:1,
      maxSlide:1,
      speed:400,
      keyPress:false
    })  

    
  socket.on 'Olleh', (id) ->
    console.log('Olleh recu *'+id+'*')
    id_connexion=id
    if( username != "" && email != "")
      send_login()

  socket.on 'update_compteur', (connected) ->
    str=""
    if (connected.connecte==0)
      str+="<span class='connectes'>"+connected.connecte+"</span> auditeur connecté"
    if (connected.connecte==1)
      str+="<span class='connectes'>"+connected.connecte+"</span> auditeur connecté"
    if (connected.connecte>1)
      str+="<span class='connectes'>"+connected.connecte+"</span> auditeurs connectés"
    if (connected.cache==1)
        str+="<br>(plus <span class='caches'>"+connected.cache+"</span> qui se cache)"
    if (connected.cache>1)
        str+="<br>(plus <span class='caches'>"+connected.cache+"</span> qui se cachent)"
    $('.nb-connected').html(str)

  # log des users
  $('#loginform').submit (e) ->
    e.preventDefault()
    username = $('#username').val()
    email = $('#mail').val()
    send_login()
    

  socket.on 'erreur', (message) ->
    #console.log('Erreur recu')
    $('#wrong-mail').html(message).fadeIn()


    

  # gestion des utilisateurs
  socket.on 'newuser', (user) ->
    id_to_find = "\##{user.id}"
    userlist.push(user.username)
    if($('#members-list').find(id_to_find).length == 0)
      #html_to_append = "<img src=\"#{user.avatar}\" id=\"#{user.id}\">" 
      $('#members-list').append(Mustache.render(user_box_template,user))

  socket.on 'logged', ->
    $('#login').fadeOut()
    $('#send-message').removeAttr('disabled')
    $('#send-message').css('opacity',1)
    $('#message-form').fadeIn()
    $('#message-to-send').focus()

  socket.on 'disuser', (user) ->
    id_to_find = "\##{user.id}"
    $('#members-list').find(id_to_find).fadeOut()


  # envoi de message
  envoi_nouveau_message = (e) ->
    e.preventDefault()
    last_msg_txt = $('#message-to-send').val()
    socket.emit 'nwmsg', {
      message: last_msg_txt,
      id_connexion: id_connexion
    }
    $('#message-to-send').val("")
    $('#message-to-send').focus()
    
  envoi_modif_message = (e) ->
    e.preventDefault()
    last_msg_txt = $('#message-to-send').val()
    socket.emit 'editmsg', {
      message: last_msg_txt,
      id_connexion: id_connexion
    }
    $('#message-form').off 'submit'
    $('#message-form').on 'submit',  envoi_nouveau_message
    $('#message-to-send').addClass('newmsg')
    $('#message-to-send').removeClass('editmsg')
    $('#message-to-send').val("")
    $('#message-to-send').focus()
    
  $('#message-form').on 'submit',  envoi_nouveau_message
    

  socket.on 'editmsg', (message) ->
    message.message=highlightPseudo message.message
    message_me=ircLike message.message, message.user.username
    if message_me==message.message
      $('#msg_'+message.id).html( message.message)
    else
      $('#msg_'+message.id).html(message_me)
    
  socket.on 'nwmsg', (message) -> 
    flag_scrollauto=$('#messages').prop('scrollHeight')<=($('#main').prop('scrollTop')+$('#main').height())
    d=new Date();
    decalage=d.getTimezoneOffset()/60
    message.h=(parseInt(message.h)-decalage)%24;
    message.message=highlightPseudo message.message
    message_me=ircLike message.message, message.user.username
    if message_me==message.message
      if last_msg_id != message.user.id
        $('#messages').append(Mustache.render(msg_template,message))
        last_msg_id = message.user.id
      else
        $(".message:last").append('<p id="msg_'+message.id+'">'+message.message+'</p>')
    else
      if last_msg_id != -1
        $('#messages').append('<li class="message_me"><p id="msg_'+message.id+'">*'+message_me+'</p></li>')
        last_msg_id=-1;
      else
        $(".message_me:last").append('<p id="msg_'+message.id+'">*'+message_me+'</p>')
    if flag_scrollauto
      $('#main').animate({scrollTop: $('#messages').prop('scrollHeight')},500)


  $('#admin-form').submit( (e) ->
    e.preventDefault()
    #maj du titre
    if $('#episode-number').val()!='' && $('#episode-title').val()!=''
      socket.emit('change-title', {
        password: $('#admin-password').val(),
        number: $('#episode-number').val(),
        createEvent: $('#create-event:checked').val()=='on',
        title: $('#episode-title').val()
        })
    else
      if $('#episode-number').val()
        alert "Titre de l'épisode non renseigné"
      else
        if $('#episode-title').val()
          alert "Numero de l'épisode non renseigné"
    )



  socket.on 'new-title', (episode) ->
    #console.log("Nouveau Titre")
    $('#title-episode').html(episode)


    
    
  socket.on 'AuthFailed',() ->
    alert "Authentification Failed"


  socket.on 'disconnect',() ->
    console.log("evt disconnect recu *"+id_connexion+"*")
    if id_connexion
      setTimeout(display_loginform,15000)
      $('#send-message').attr('disabled', 'disabled')
      $('#send-message').css('opacity',0.5)
      console.log("Il s'est fait jeté")
      $('#members-list li').remove()
      $('.nb-connected').html("")
      
      socket.emit('Hello',id_connexion)


    
  socket.on 'del_imglist',() ->
    console.log "suppression des images"
    $('#slider').html('')
    slider.refresh()


  socket.on 'add_img',(im) ->
    console.log("Ajout d'image : ",im)
    if(im.media_type=='img' || im.media_type!='video')
      $('#slider').prepend('
          <li class="slider_elt" data-thumb="'+im.url+'">
            <img  class="img_slider" title="par '+im.poster+'" src="'+im.url+'" alt="par '+im.poster+'" onclick="openLightboxImage(\''+im.url+'\')" >
            <div class="author">
              <a class="linkTwitter" href="http://twitter.com/'+im.poster_user+'"  target="_blank">
                <img class="twitterAvatar"  src="'+im.avatar+'"/>
              </a>
              <span class="tweet">
                <a class="linkTwitter" href="http://twitter.com/'+im.poster_user+'"  target="_blank">@'+im.poster_user+'</a> : '+im.tweet+'
              </span>
            </div>
          </li>
        ')
      slider.refresh()
      slider.goToSlide(0)
    if(im.media_type=='video')
      site = im.url.split('/')[0]
      if(site=='youtube.com')
        $('#slider').prepend('
          <li class="slider_elt" data-thumb="http://img.youtube.com/vi/'+im.nom+'/1.jpg">
            <img  class="img_slider"  title="par '+im.poster+'" src="http://img.youtube.com/vi/'+im.nom+'/0.jpg" alt="par '+im.poster+'">
            <img  class="btn_play" src="images/play.png"  onclick="openLightboxYouTube(\''+im.nom+'\')">
            <div class="author">
              <a class="linkTwitter" href="http://twitter.com/'+im.poster_user+'"  target="_blank">
                <img class="twitterAvatar"  src="'+im.avatar+'"/>
              </a>
              <span class="tweet">
                <a class="linkTwitter" href="http://twitter.com/'+im.poster_user+'"  target="_blank">@'+im.poster_user+'</a> : '+im.tweet+'
              </span>
            </div>
          </li>
        ')
        slider.refresh()
        slider.goToSlide(0)
      if(site=='vimeo.com')
        $.ajax({
          url: 'http://vimeo.com/api/v2/video/'+im.nom+'.json'
          dataType: 'JSON'
        }).done((data)->
          $('#slider').prepend('
            <li class="slider_elt" data-thumb="'+data[0].thumbnail_small+'">
              <img  class="img_slider"  title="par '+im.poster+'" src="'+data[0].thumbnail_large+'" alt="par '+im.poster+'">
              <img  class="btn_play" src="images/play.png"  onclick="openLightboxVimeo(\''+im.nom+'\')">
              <div class="author">
                <a class="linkTwitter" href="http://twitter.com/'+im.poster_user+'"  target="_blank">
                  <img class="twitterAvatar"  src="'+im.avatar+'"/>
                </a>
                <span class="tweet">
                  <a class="linkTwitter" href="http://twitter.com/'+im.poster_user+'"  target="_blank">@'+im.poster_user+'</a> : '+im.tweet+'
                </span>
              </div>
            </li>
          ')
          slider.refresh()
          slider.goToSlide(0)
        )
      if(site=='vine.co')   
        $('#slider').prepend('
          <li class="slider_elt" data-thumb="'+im.url_thumbnail+'">
              <!--iframe class="vine-embed" src="https://vine.co/v/'+im.nom+'/embed/simple?related=0" width="100%" height="100%" frameborder="0"></iframe-->
              <img class="vine-embed" src="'+im.url_thumbnail+'" width="100%" height="100%" frameborder="0"/>
              <img class="btn_play" src="images/play.png"  onclick="openLightboxVine(\''+im.nom+'\')">
              <div class="author">
                <a class="linkTwitter" href="http://twitter.com/'+im.poster_user+'"  target="_blank">
                  <img class="twitterAvatar"  src="'+im.avatar+'"/>
                </a>
                <span class="tweet">
                  <a class="linkTwitter" href="http://twitter.com/'+im.poster_user+'"  target="_blank">@'+im.poster_user+'</a> : '+im.tweet+'
                </span>
              </div>
          </li>
        ')
        console.log 'vine',im
        slider.refresh()
        slider.goToSlide(0)
       
     # $('#slider').prepend('<li class="slider_elt" data-thumb="'+im.url+'">
#<iframe id="player" type="text/html" width="640" height="390"
 # src="http://www.youtube.com/embed/'+im.nom+'?enablejsapi=1&origin=http://live.podcastscience.fm"
  #frameborder="0"></iframe>
   #     </li>')


  $('.rec').on 'dblclick', ->
    console.log 'Demande de Refresh'
    socket.emit 'refreshSP' 

  $(window).on 'beforeunload', ->
    console.log("il s'est barré")
    undefined if socket.emit 'triggered-beforeunload'

  send_login = () ->
    socket.emit('login', {
      username: username,
      mail: email,
      id_connexion: id_connexion
      })

  display_loginform = () ->
    if(!id_connexion)
      $('#login').fadeIn()
      $('#message-form').fadeOut()
      msg = "Damned! Vous avez été deconnecté !"
      $('#wrong-mail').html(msg).fadeIn()

  $('#reinitChatroomForm').on 'submit',  (e) ->
      e.preventDefault()
      console.log("Reinitiailisation de la chatroom")
      socket.emit('reinit_chatroom',$('#admin-password2').val())
            
  socket.on 'del_msglist', () ->
    # Message ne marchent plus apres le vidage mais remarche si on redemarre le serveur 
    console.log("Vidage de la liste des messages")
    last_msg_id=""
    $('#messages li').remove()

  socket.on "twitter_start" , () ->
    console.log "Depart du scan de Twitter"
    if window.location.pathname=='/admin'
        alert "Depart du scan de Twitter"

  socket.on "twitter_stop" , () ->
    console.log "Arret du scan de Twitter"
    if window.location.pathname=='/admin'
        alert "Arret du scan de Twitter"



  socket.on "errorTwitter" , (data) ->
    if window.location.pathname=='/admin'
      if data.data.code=420
        alert "Erreur de Twitter : HTTP 420/Keep calm. Merci de réessayer dans 2 minutes"
      else
        alert "Erreur de Twitter : HTTP "+data.data.code
    
  socket.on "heartbeat_twitter" , () ->
    console.log 'heartbeat_twitter recu'
    d=  new Date()
    h = d.getHours()
    m = d.getMinutes()
    s = d.getSeconds()
    $("#lasttheartbeat").html( "*"+h+':'+m+':'+s)
    $("#slider").   addClass "twitter_heartbeat"
    setTimeout ()-> $("#slider").removeClass "twitter_heartbeat",3000


  $('input#message-to-send').on 'keydown', (e)->
    input = $('#message-to-send')

    if e.which == 37
      console.log 'test'
    if e.which == 38 
      e.preventDefault()
      if input.is('.newmsg')
        $('#message-form').off 'submit'
        $('#message-form').on 'submit',  envoi_modif_message
        input.addClass('editmsg')
        input.removeClass('newmsg')
        input.val(last_msg_txt)
        input[0].selectionStart = last_msg_txt.length
        input[0].selectionEnd = last_msg_txt.length
    if e.which == 40 && input.is('.editmsg')
      e.preventDefault()
      $('#message-form').off 'submit'
      $('#message-form').on 'submit',  envoi_nouveau_message
      input.addClass('newmsg')
      input.removeClass('editmsg')
      input.val("")

