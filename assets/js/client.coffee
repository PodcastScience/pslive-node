jQuery = $(document).ready 

jQuery ->
  connect_url = "http://protected-cove-4063.herokuapp.com/"
 # connect_url = "http://localhost:3000"
  last_msg_id = false

  socket = io.connect(connect_url)
  msg_template = $('#message-box').html()
  $('#message-box').remove();

  user_box_template = $('#user_box').html()
  $('#user_box').remove();

#  socket.emit('test')


  # log des users
  $('#loginform').submit( (e) -> 
  	e.preventDefault()
  	socket.emit('login', {
  		username: $('#username').val(),
  		mail: $('#mail').val()
  		})
  	)


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
      $('#messages').animate({scrollTop: $('#messages').prop('scrollHeight')},5000)
      last_msg_id = message.user.id
    else  
      $("#messages div:last").append('<p>'+message.message+'</p>')



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

 