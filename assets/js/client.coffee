$(document).ready ->

  $(window).konami
      cheat: ->
        alert "C'est pas bien de diviser par zéro..."

  connect_url = "http://podcastscience.herokuapp.com"
#  connect_url = "http://localhost:3000"
  last_msg_id = false

  socket = io.connect(connect_url)
  msg_template = $('#message-box').html()
  $('#message-box').remove();

  user_box_template = $('#user_box').html()
  $('#user_box').remove();

#  socket.emit('test')
  


  socket.on 'update_compteur', (connected) ->
    $('#nb-connected').html(connected+' utilisateurs connectés!')


  # log des users
  $('#loginform').submit( (e) -> 
  	e.preventDefault()
  	socket.emit('login', {
  		username: $('#username').val(),
  		mail: $('#mail').val()
  		})
  	)

  socket.on 'error', (message) ->
    $('#wrong-mail').html(message).fadeIn()


  # gestion des utilisateurs
  socket.on 'newuser', (user) ->
    html_to_append = "<img src=\"#{user.avatar}\" id=\"#{user.id}\">" 
    $('#members-list').append(Mustache.render(user_box_template,user))

  socket.on 'logged', ->
    $('#login').fadeOut()
    $('#message-form').fadeIn()
    $('#message-to-send').focus()

  socket.on 'disuser', (user) ->
    id_to_find = "\##{user.id}"
    $('#members-list').find(id_to_find).fadeOut()


  # envoi de message
  $('#message-form').submit (e) ->
    e.preventDefault()
    socket.emit 'nwmsg', {
      message: $('#message-to-send').val()
    }
    $('#message-to-send').val("")
    $('#message-to-send').focus()

  socket.on 'nwmsg', (message) ->
    if last_msg_id != message.user.id
      $('#messages').append(Mustache.render(msg_template,message))
      last_msg_id = message.user.id
    else  
      $("#messages div:last").append('<p style="font-size:small;">'+message.message+'</p>')

    $('#main').animate({scrollTop: $('#messages').prop('scrollHeight')},500)


  # envoi d'un iframe
  $('#iframe-form').submit( (e) -> 
    e.preventDefault()
    socket.emit('new-iframe', {
      password: $('#iframe-password').val(),
      iframe: $('#iframe-value').val()
      })
    )

  socket.on 'new-drawings', (livedraw_iframe) ->
    $('#live-draw-frame').html(livedraw_iframe)

  socket.on 'disconnect', ->
    $('#login').fadeIn()
    $('#message-form').fadeOut()  
    $('#wrong-mail').html("Damned! Vous avez été deconnecté!").fadeIn()

  $(window).on 'beforeunload', ->
    console.log("il s'est barré")
    undefined if socket.emit 'triggered-beforeunload'




