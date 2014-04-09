$(document).ready ->

  # $(window).konami
  #     cheat: ->
  #       alert "C'est pas bien de diviser par zéro..."

  connect_url = "/"
  id_connexion= false
  username=""
  email=""
  last_msg_id = false

  socket = io.connect(connect_url)
  msg_template = $('#message-box').html()
  $('#message-box li').remove()

  user_box_template = $('#user_box').html()
  $('#user_box').remove()

  unless window.location.pathname=='/admin'
    #console.log('Envoi du Hello initial') 
    socket.emit('Hello','')
    
  socket.on 'Olleh', (id) ->
    console.log('Olleh recu')
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
  $('#loginform').submit( (e) ->
    e.preventDefault()
    username = $('#username').val()
    email = $('#mail').val()
    send_login()
    )

  socket.on 'erreur', (message) ->
    #console.log('Erreur recu')
    $('#wrong-mail').html(message).fadeIn()


    

  # gestion des utilisateurs
  socket.on 'newuser', (user) ->
    id_to_find = "\##{user.id}"
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
  $('#message-form').submit (e) ->
    e.preventDefault()
    socket.emit 'nwmsg', {
      message: $('#message-to-send').val(),
      id_connexion: id_connexion
    }
    $('#message-to-send').val("")
    $('#message-to-send').focus()

  socket.on 'nwmsg', (message) ->
    flag_scrollauto=$('#messages').prop('scrollHeight')<=($('#main').prop('scrollTop')+$('#main').height())
    d=new Date();
    decalage=d.getTimezoneOffset()/60
    message.h=parseInt(message.h)-decalage;
    if last_msg_id != message.user.id
      $('#messages').append(Mustache.render(msg_template,message))
      last_msg_id = message.user.id
    else
      $(".message:last").append('<p>'+message.message+'</p>')
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


  socket.on 'new-drawings', (livedraw_iframe) ->
    $('#live-draw-frame').html(livedraw_iframe)


  socket.on 'new-title', (episode) ->
    #console.log("Nouveau Titre")
    $('#title-episode').html(episode)


    
    
  socket.on 'disconnect',() ->
    #console.log("evt disconnect recu")
    if id_connexion
      setTimeout(display_loginform,15000)
      $('#send-message').attr('disabled', 'disabled')
      $('#send-message').css('opacity',0.5)
      console.log("Il s'est fait jeté")
      $('#members-list li').remove()
      $('.nb-connected').html("")
      socket.emit('Hello',id_connexion)



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
