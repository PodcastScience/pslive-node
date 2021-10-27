// Generated by CoffeeScript 2.6.1
(function() {
  var display_menu, hide_menu;

  $(document).ready(function() {
    var activate_wait_thread, adm_select_img, chatroom_info, connect_url, desactivate_wait_thread, display_loginform, email, envoi_modif_message, envoi_nouveau_message, helplist, highlightPseudo, id_connexion, images_en_attente, ircLike, is_admin, last_msg_id, last_msg_txt, msg_template, send_login, slider, socket, to_thumbnail, twitter_token, user_box_template, userid, userlist, username, waiting_image_template;
    // $(window).konami
    //     cheat: ->
    //       alert "C'est pas bien de diviser par zéro..."
    connect_url = "/chatroom";
    id_connexion = false;
    is_admin = false;
    username = "";
    userid = "";
    email = "";
    last_msg_id = false;
    last_msg_txt = "";
    userlist = [];
    images_en_attente = [];
    helplist = [
      {
        cmd: 'me',
        suffix: ' '
      },
      {
        cmd: 'nick',
        suffix: ' '
      },
      {
        cmd: 'bière',
        suffix: ' @'
      },
      {
        cmd: 'tournéegénérale',
        suffix: ' '
      }
    ];
    socket = io.connect(connect_url);
    msg_template = $('#message-box').html();
    $('#message-box li').remove();
    user_box_template = $('#user_box').html();
    $('#user_box').remove();
    waiting_image_template = $('#waiting-images-list').html();
    $('#waiting-images-list li').remove();
    $('#twitter_auth_link').on('click', function() {
      return socket.emit('twitter_auth');
    });
    $('#pause_slide_show').on('click', function() {
      return socket.emit('pause_slide_show');
    });
    activate_wait_thread = function() {
      $(".hook").unbind('click');
      $(".hook").on('click', desactivate_wait_thread);
      return $(".wait_thread").addClass('active');
    };
    desactivate_wait_thread = function() {
      $(".hook").unbind('click');
      $(".hook").on('click', activate_wait_thread);
      return $(".wait_thread").removeClass('active');
    };
    $(".hook").on('click', activate_wait_thread);
    twitter_token = null;
    to_thumbnail = function(url) {
      var l, tab;
      tab = url.split('.');
      l = tab.length;
      //tab[l-2]+='-150x150'
      return tab.join('.');
    };
    chatroom_info = function(message) {
      var flag_scrollauto;
      flag_scrollauto = $('#messages').prop('scrollHeight') <= ($('#main').prop('scrollTop') + $('#main').height());
      if (last_msg_id !== -1) {
        $('#messages').append('<li class="message_me message_info "><p ><i>* ' + message + '</i></p></li>');
        last_msg_id = -1;
      } else {
        $(".message_info:last").append('<p ><i>* ' + message + '</i></p>');
      }
      if (flag_scrollauto) {
        return $('#main').animate({
          scrollTop: $('#messages').prop('scrollHeight')
        }, 500);
      }
    };
    highlightPseudo = function(text) {
      var equiv, i, idx, j, len, len1, pattern, ref, u, userref, val;
      userref = '';
      equiv = [];
      ref = userlist.sort(function(a, b) {
        return b.name.length - a.name.length;
      });
      for (i = 0, len = ref.length; i < len; i++) {
        u = ref[i];
        idx = "i" + (Math.floor(90000000000 * Math.random()) + 10000000000);
        equiv.push({
          'idx': idx,
          'name': u.name
        });
        pattern = RegExp("@(" + u.name + ")", "ig");
        text = text.replace(pattern, "@" + idx);
      }
      for (j = 0, len1 = equiv.length; j < len1; j++) {
        val = equiv[j];
        pattern = RegExp("@(" + val.idx + ")", "ig");
        if (val.name !== username) {
          text = text.replace(pattern, "@" + val.name);
        } else {
          text = text.replace(pattern, "<span class='mypseudo'>@" + val.name + "</span>");
        }
      }
      return text;
    };
    ircLike = function(text, pseudo) {
      var stringMe, stringTab, valeurRetour;
      stringTab = text.split(" ");
      stringMe = text.split("/me");
      valeurRetour = "";
      if (stringTab.length >= 2) {
        if (stringTab[0].localeCompare("/me") === 0) {
          valeurRetour = "<i> ";
          valeurRetour = valeurRetour.concat(pseudo);
          valeurRetour = valeurRetour.concat(stringMe[1]);
          valeurRetour = valeurRetour.concat("</i>");
        } else {
          valeurRetour = text;
        }
      } else {
        valeurRetour = text;
      }
      return valeurRetour;
    };
    if (window.location.pathname !== '/admin') {
      //console.log('Envoi du Hello initial') 
      socket.emit('Hello', '');
      slider = $('#slider').lightSlider({
        gallery: true,
        minSlide: 1,
        maxSlide: 1,
        speed: 400,
        keyPress: false
      });
    }
    socket.on('Olleh', function(id) {
      console.log('Olleh recu *' + id + '*');
      id_connexion = id;
      console.log("username:", username);
      console.log("email:", email);
      console.log('twitter_token', twitter_token);
      if (twitter_token !== null) {
        return socket.emit('twitter_auth');
      } else {
        if (username !== "" && email !== "") {
          return send_login(true);
        } else {
          return console.log('Merci de vous authentifier');
        }
      }
    });
    socket.on('update_compteur', function(connected) {
      var str;
      str = "";
      if (connected.connecte === 0) {
        str += "<p><span class='connectes'>" + connected.connecte + "</span> auditeur connecté</p>";
      }
      if (connected.connecte === 1) {
        str += "<p><span class='connectes'>" + connected.connecte + "</span> auditeur connecté</p>";
      }
      if (connected.connecte > 1) {
        str += "<p><span class='connectes'>" + connected.connecte + "</span> auditeurs connectés</p>";
      }
      if (connected.cache === 1) {
        str += "<p>(plus <span class='caches'>" + connected.cache + "</span> qui se cache)</p>";
      }
      if (connected.cache > 1) {
        str += "<p>(plus <span class='caches'>" + connected.cache + "</span> qui se cachent)</p>";
      }
      return $('.nb-connected').html(str);
    });
    // log des users
    $('#loginform').submit(function(e) {
      e.preventDefault();
      username = $('#username').val();
      email = $('#mail').val();
      return send_login(false);
    });
    socket.on('twitter_auth_ok', function(token) {
      var reco;
      reco = twitter_token !== null;
      twitter_token = token;
      return socket.emit('twitter_login', twitter_token, id_connexion, reco);
    });
    socket.on('erreur', function(message) {
      //console.log('Erreur recu')
      return $('#wrong-mail').html(message).fadeIn();
    });
    // Gestion des erreurs
    socket.on("ERR_IMTOOBIG", function() {
      return chatroom_info("ERREUR : L'image est trop grande (>2Mo) et n'a pas pu être suffisament reduite.");
    });
    // gestion des utilisateurs
    socket.on('newuser', function(user, new_connection) {
      var id_to_find;
      console.log('ajout de ' + user.username);
      id_to_find = `\#${user.id}`;
      userlist.push({
        'name': user.username,
        'id': user.id,
        'avatar': user.avatar
      });
      if ($('#members-list').find(id_to_find).length === 0) {
        //html_to_append = "<img src=\"#{user.avatar}\" id=\"#{user.id}\">" 
        $('#members-list').append(Mustache.render(user_box_template, user));
        if (new_connection) {
          return chatroom_info(user.username + ' s\'est connecté(e)');
        }
      }
    });
    socket.on('logged', function(id, _is_admin, url) {
      console.log("logged", url);
      userid = id;
      is_admin = _is_admin;
      if (is_admin) {
        $('.admin_class').addClass('admin_class_active');
        $('.admin_class').removeClass('admin_class');
        $('#backend_link a').attr('href', url);
        helplist.push({
          cmd: 'kick',
          suffix: ' @'
        });
        //cache le menu, pas le bouton...
        hide_menu();
      }
      $('#login').fadeOut();
      $('#send-message').removeAttr('disabled');
      $('#send-message').css('opacity', 1);
      $('#message-form').fadeIn();
      $('#message-to-send').focus();
      return $('#message-to-send').atwho({
        at: "@",
        data: userlist,
        displayTpl: "<li><img class='avatar25' src=${avatar}/>${name}</li>",
        callbacks: {
          filter: function(query, data, searchKey) {
            var _results, i, item, len;
            // !!null #=> false; !!undefined #=> false; !!'' #=> false;
            _results = [];
            for (i = 0, len = userlist.length; i < len; i++) {
              item = userlist[i];
              if (~new String(item[searchKey]).toLowerCase().indexOf(query.toLowerCase())) {
                if (item[searchKey] !== username) {
                  _results.push(item);
                }
              }
            }
            return _results;
          }
        }
      }).atwho({
        at: "/",
        data: helplist,
        searchKey: 'cmd',
        displayTpl: '<li>${cmd}</li>',
        insertTpl: '/${cmd}${suffix}',
        suffix: ''
      }).on({
        'shown.atwho': function(e) {
          return $(this).data('autocompleting', true);
        },
        'hidden.atwho': function(e) {
          return $(this).data('autocompleting', false);
        }
      });
    });
    socket.on('openurl', function(url) {
      return window.open(url, 'Auth', 'menubar=no, scrollbars=no');
    });
    socket.on('twitter_logged', function(user) {
      email = user.email;
      if (username === '' || username === user.username) {
        return username = user.username;
      } else {
        return socket.emit('changename', username);
      }
    });
    socket.on('disuser', function(user) {
      var i, id_to_find, len, new_userlist, u;
      new_userlist = [];
      for (i = 0, len = userlist.length; i < len; i++) {
        u = userlist[i];
        if (u.id !== user.id) {
          new_userlist.push(u);
        }
      }
      userlist = new_userlist;
      id_to_find = `\#${user.id}`;
      return $('#members-list').find(id_to_find).fadeOut(300, function() {
        return $(this).remove();
      });
    });
    socket.on('changename', function(formername, user) {
      var i, id_to_find, len, u;
      console.log("recherche de l'id " + user.id);
      id_to_find = `\#${user.id}`;
      if (user.id === userid) {
        username = user.username;
        console.log("nouveau username local : ", username);
      }
      for (i = 0, len = userlist.length; i < len; i++) {
        u = userlist[i];
        if (u.id === user.id) {
          u.name = user.username;
        }
      }
      return $('#members-list').find(id_to_find).fadeOut(300, function() {
        $(this).remove();
        chatroom_info(formername + ' s\'appelle désormais ' + user.username);
        return $('#members-list').append(Mustache.render(user_box_template, user));
      });
    });
    socket.on('chatroom_info', function(text) {
      return chatroom_info(text);
    });
    socket.on('kick', function(_username, message) {
      //socket.emit('disconnect',id_connexion)
      chatroom_info(message);
      if (_username === username) {
        username = "";
        //id_connexion=""
        email = "";
        twitter_token = null;
        display_loginform({
          force: true
        });
        $('#send-message').attr('disabled', 'disabled');
        $('#send-message').css('opacity', 0.5);
        console.log("Il s'est fait jeté");
        $('#members-list li').remove();
        $('.nb-connected').html("");
        socket.emit('disconnect', id_connexion);
        socket = io.connect(connect_url);
        userlist = [];
        console.log("Envoi du Hello");
        return socket.emit('Hello', id_connexion);
      }
    });
    // envoi de message
    envoi_nouveau_message = function(e) {
      e.preventDefault();
      last_msg_txt = $('#message-to-send').val();
      socket.emit('nwmsg', {
        message: last_msg_txt,
        id_connexion: id_connexion
      });
      $('#message-to-send').val("");
      return $('#message-to-send').focus();
    };
    envoi_modif_message = function(e) {
      e.preventDefault();
      last_msg_txt = $('#message-to-send').val();
      socket.emit('editmsg', {
        message: last_msg_txt,
        id_connexion: id_connexion
      });
      $('#message-form').off('submit');
      $('#message-form').on('submit', envoi_nouveau_message);
      $('#message-to-send').addClass('newmsg');
      $('#message-to-send').removeClass('editmsg');
      $('#message-to-send').val("");
      return $('#message-to-send').focus();
    };
    $('#message-form').on('submit', envoi_nouveau_message);
    socket.on('editmsg', function(message) {
      var message_me;
      message.message = highlightPseudo(message.message);
      message_me = ircLike(message.message, message.user.username);
      if (message_me === message.message) {
        return $('#msg_' + message.id).html(message.message);
      } else {
        return $('#msg_' + message.id).html("<p>*" + message_me + "</p>");
      }
    });
    socket.on('nwmsg', function(message) {
      var d, decalage, flag_scrollauto, message_me;
      flag_scrollauto = $('#messages').prop('scrollHeight') <= ($('#main').prop('scrollTop') + $('#main').height() + 10);
      d = new Date();
      decalage = d.getTimezoneOffset() / 60;
      message.h = (parseInt(message.h) - decalage) % 24;
      message.message = highlightPseudo(message.message);
      message_me = ircLike(message.message, message.user.username);
      if (message_me === message.message) {
        console.log("nouveau message:", message.message);
        if (last_msg_id !== message.user.id) {
          $('#messages').append(Mustache.render(msg_template, message));
          last_msg_id = message.user.id;
        } else {
          $(".message:last").append('<p id="msg_' + message.id + '">' + message.message + '</p>');
        }
      } else {
        console.log("nouveau me:", message_me);
        if (last_msg_id !== -1) {
          $('#messages').append('<li class="message_me message_info "><p id="msg_' + message.id + '">*' + message_me + '</p></li>');
          last_msg_id = -1;
        } else {
          $(".message_info:last").append('<p id="msg_' + message.id + '">*' + message_me + '</p>');
        }
      }
      if (flag_scrollauto) {
        return $('#main').animate({
          scrollTop: $('#messages').prop('scrollHeight')
        }, 500);
      }
    });
    $('#admin-form').submit(function(e) {
      e.preventDefault();
      //maj du titre
      if ($('#episode-number').val() !== '' && $('#episode-title').val() !== '') {
        return socket.emit('change-title', {
          password: $('#admin-password').val(),
          number: $('#episode-number').val(),
          hashtag: $("#hashtag").val(),
          createEvent: $('#create-event:checked').val() === 'on',
          title: $('#episode-title').val()
        });
      } else {
        if ($('#episode-number').val()) {
          return alert("Titre de l'épisode non renseigné");
        } else {
          if ($('#episode-title').val()) {
            return alert("Numero de l'épisode non renseigné");
          }
        }
      }
    });
    socket.on('new-title', function(episode, num, title, hashtag) {
      //console.log("Nouveau Titre")
      console.log("num:", num);
      console.log("title:", title);
      console.log("hashtag:", hashtag);
      $('#title-episode').html(episode);
      $('#episode-number').val(num);
      $('#episode-title').val(title);
      return $('#hashtag').val(hashtag);
    });
    socket.on('AuthFailed', function() {
      return alert("Authentification Failed");
    });
    socket.on('disconnect', function() {
      console.log("evt disconnect recu *" + id_connexion + "*");
      if (id_connexion) {
        setTimeout(display_loginform, 15000);
        $('#send-message').attr('disabled', 'disabled');
        $('#send-message').css('opacity', 0.5);
        console.log("Il s'est fait jeté");
        $('#members-list li').remove();
        $('.nb-connected').html("");
        userlist = [];
        console.log("Envoi du Hello");
        return socket.emit('Hello', id_connexion);
      }
    });
    socket.on('del_imglist', function() {
      console.log("suppression des images");
      $('#slider').html('');
      return slider.refresh();
    });
    socket.on('remove_image', function(signature) {
      console.log("suppression de l'image ", signature);
      $('#slider_' + signature).remove();
      return slider.refresh();
    });
    socket.on('add_img', function(im) {
      var site;
      console.log("Ajout d'image : ", im);
      if (im.media_type === 'img' || im.media_type !== 'video') {
        $('#slider').prepend('<li class="slider_elt" data-thumb="' + im.url + '" id="slider_' + im.signature + '"> <img  class="img_slider" title="par ' + im.poster + '" src="' + im.url + '" alt="par ' + im.poster + '" onclick="openLightboxImage(\'' + im.url + '\')" > <div class="author"> <a class="linkTwitter" href="http://twitter.com/' + im.poster_user + '"  target="_blank"> <img class="twitterAvatar"  src="' + im.avatar + '"/> </a> <span class="tweet"> <a class="linkTwitter" href="http://twitter.com/' + im.poster_user + '"  target="_blank">@' + im.poster_user + '</a> : ' + im.tweet + '</span> <span class="admin_class"> <a  class="selection_image_' + im.signature + '"  >(mettre en avant)</a> </span> </div> </li>');
        slider.refresh();
        slider.goToSlide(0);
      }
      if (im.media_type === 'video') {
        site = im.url.split('/')[0];
        if (site === 'youtube.com') {
          $('#slider').prepend('<li class="slider_elt" data-thumb="http://img.youtube.com/vi/' + im.nom + '/1.jpg" id="slider_' + im.signature + '"> <img  class="img_slider"  title="par ' + im.poster + '" src="http://img.youtube.com/vi/' + im.nom + '/0.jpg" alt="par ' + im.poster + '"> <img  class="btn_play" src="images/play.png"  onclick="openLightboxYouTube(\'' + im.nom + '\')"> <div class="author"> <a class="linkTwitter" href="http://twitter.com/' + im.poster_user + '"  target="_blank"> <img class="twitterAvatar"  src="' + im.avatar + '"/> </a> <span class="tweet"> <a class="linkTwitter" href="http://twitter.com/' + im.poster_user + '"  target="_blank">@' + im.poster_user + '</a> : ' + im.tweet + '</span> <span class="admin_class"> <a  class="selection_image_' + im.signature + '"  >(mettre en avant)</a> </span> </div> </li>');
          slider.refresh();
          slider.goToSlide(0);
        }
        if (site === 'vimeo.com') {
          $.ajax({
            url: 'http://vimeo.com/api/v2/video/' + im.nom + '.json',
            dataType: 'JSON'
          }).done(function(data) {
            $('#slider').prepend('<li class="slider_elt" data-thumb="' + data[0].thumbnail_small + '" id="slider_' + im.signature + '"> <img  class="img_slider"  title="par ' + im.poster + '" src="' + data[0].thumbnail_large + '" alt="par ' + im.poster + '"> <img  class="btn_play" src="images/play.png"  onclick="openLightboxVimeo(\'' + im.nom + '\')"> <div class="author"> <a class="linkTwitter" href="http://twitter.com/' + im.poster_user + '"  target="_blank"> <img class="twitterAvatar"  src="' + im.avatar + '"/> </a> <span class="tweet"> <a class="linkTwitter" href="http://twitter.com/' + im.poster_user + '"  target="_blank">@' + im.poster_user + '</a> : ' + im.tweet + '</span> <span class="admin_class"> <a  class="selection_image_' + im.signature + '"  >(mettre en avant)</a> </span> </div> </li>');
            slider.refresh();
            return slider.goToSlide(0);
          });
        }
        if (site === 'vine.co') {
          $('#slider').prepend('<li class="slider_elt" data-thumb="' + im.url_thumbnail + '"  id="slider_' + im.signature + '"> <!--iframe class="vine-embed" src="https://vine.co/v/' + im.nom + '/embed/simple?related=0" width="100%" height="100%" frameborder="0"></iframe--> <img class="vine-embed" src="' + im.url_thumbnail + '" width="100%" height="100%" frameborder="0"/> <img class="btn_play" src="images/play.png"  onclick="openLightboxVine(\'' + im.nom + '\')"> <div class="author"> <a class="linkTwitter" href="http://twitter.com/' + im.poster_user + '"  target="_blank"> <img class="twitterAvatar"  src="' + im.avatar + '"/> </a> <span class="tweet"> <a class="linkTwitter" href="http://twitter.com/' + im.poster_user + '"  target="_blank">@' + im.poster_user + '</a> : ' + im.tweet + '</span> </div> </li>');
          console.log('vine', im);
          slider.refresh();
          slider.goToSlide(0);
        }
      }
      if (is_admin) {
        $('.admin_class').addClass('admin_class_active');
        $('.admin_class').removeClass('admin_class');
      }
      return $('.selection_image_' + im.signature).on('click', {
        'signature': im.signature
      }, adm_select_img);
    });
    adm_select_img = function(param) {
      console.log("affichage de " + param.data.signature + " chez tout le monde");
      return socket.emit("select_img", param.data.signature);
    };
    socket.on('select_img', function(signature) {
      console.log("recherche de l'image a afficher", signature);
      return $('.slider_elt').each(function(index, image) {
        //children renvoi un array, mettre en place map()
        console.log($(image).attr('src'));
        if ($(image).attr('id') === 'slider_' + signature) {
          return slider.goToSlide(index);
        }
      });
    });
    $('.rec').on('click', function() {
      return console.log("test");
    });
    //socket.emit "logout"
    $(window).on('beforeunload', function() {
      console.log("il s'est barré");
      if (socket.emit('triggered-beforeunload')) {
        return void 0;
      }
    });
    send_login = function(reco) {
      console.log("emission d'un login");
      return socket.emit('login', {
        username: username,
        mail: email,
        id_connexion: id_connexion
      }, reco);
    };
    display_loginform = function(param = {
        force: false
      }) {
      var msg;
      if (!id_connexion || param.force) {
        $('#login').fadeIn();
        $('#message-form').fadeOut();
        msg = "Damned! Vous avez été deconnecté !";
        return $('#wrong-mail').html(msg).fadeIn();
      }
    };
    $('#reinitChatroomForm').on('submit', function(e) {
      e.preventDefault();
      console.log("Reinitiailisation de la chatroom");
      return socket.emit('reinit_chatroom', $('#admin-password2').val());
    });
    $('#reinitChatroomButton').on('click', function(e) {
      console.log("Reinitiailisation de la chatroom");
      return socket.emit('reinit_chatroom', "");
    });
    socket.on('maj_waiting_images', function(data) {
      var i, im, len;
      images_en_attente = data;
      $('#waiting-images-list li').remove();
      for (i = 0, len = images_en_attente.length; i < len; i++) {
        im = images_en_attente[i];
        im.urlThumbnail = to_thumbnail(im.url);
        console.log("maj_waiting_images:", Mustache.render(waiting_image_template, im));
        $('#waiting-images-list').append(Mustache.render(waiting_image_template, im));
      }
      return $('.waiting-image').on('dblclick', function(e) {
        var sign;
        sign = $(e.target).data('sign');
        console.log('post de ', sign);
        return socket.emit('post-waiting-image', sign);
      });
    });
    socket.on('pause_slide_show', function(b) {
      if (b) {
        return $('#pause_slide_show').html('\u25B6 Play');
      } else {
        return $('#pause_slide_show').html('\u23f8 Pause');
      }
    });
    socket.on('del_msglist', function() {
      // Message ne marchent plus apres le vidage mais remarche si on redemarre le serveur 
      console.log("Vidage de la liste des messages");
      last_msg_id = "";
      return $('#messages li').remove();
    });
    socket.on("twitter_start", function() {
      console.log("Depart du scan de Twitter");
      if (window.location.pathname === '/admin') {
        return alert("Depart du scan de Twitter");
      }
    });
    socket.on("twitter_stop", function() {
      console.log("Arret du scan de Twitter");
      if (window.location.pathname === '/admin') {
        return alert("Arret du scan de Twitter");
      }
    });
    socket.on("errorTwitter", function(data) {
      if (window.location.pathname === '/admin') {
        if (data.data.code = 420) {
          return alert("Erreur de Twitter : HTTP 420/Keep calm. Merci de réessayer dans 2 minutes");
        } else {
          return alert("Erreur de Twitter : HTTP " + data.data.code);
        }
      }
    });
    socket.on("heartbeat_twitter", function() {
      var d, h, m, s;
      console.log('heartbeat_twitter recu');
      d = new Date();
      h = d.getHours();
      m = d.getMinutes();
      s = d.getSeconds();
      $("#lasttheartbeat").html("*" + h + ':' + m + ':' + s);
      $("#slider").addClass("twitter_heartbeat");
      return setTimeout(function() {
        return $("#slider").removeClass("twitter_heartbeat", 3000);
      });
    });
    return $('input#message-to-send').on('keydown', function(e) {
      var input;
      input = $('#message-to-send');
      if (e.which === 37) {
        console.log('test');
      }
      if (e.which === 38) {
        e.preventDefault();
        if (input.is('.newmsg') && !$('#message-to-send').data('autocompleting')) {
          $('#message-form').off('submit');
          $('#message-form').on('submit', envoi_modif_message);
          input.addClass('editmsg');
          input.removeClass('newmsg');
          input.val(last_msg_txt);
          input[0].selectionStart = last_msg_txt.length;
          input[0].selectionEnd = last_msg_txt.length;
        }
      }
      if (e.which === 40) {
        if (input.is('.editmsg') && !$('#message-to-send').data('autocompleting')) {
          e.preventDefault();
          $('#message-form').off('submit');
          $('#message-form').on('submit', envoi_nouveau_message);
          input.addClass('newmsg');
          input.removeClass('editmsg');
          return input.val("");
        }
      }
    });
  });

  display_menu = function() {
    $('.content').on('click', function() {
      return hide_menu();
    });
    $("#menu").addClass('menuShown');
    $("#menu").removeClass('menu_hidden');
    $("#menu_button").addClass('active');
    $('#menu_button').attr('onclick', '').unbind('click');
    return $("#menu_button").on('click', hide_menu);
  };

  hide_menu = function() {
    $("#menu").addClass('menu_hidden');
    $("#menu").removeClass('menuShown');
    $("#menu_button").removeClass('active');
    $('.content').unbind('click');
    $('#menu_button').attr('onclick', '').unbind('click');
    return $("#menu_button").on('click', display_menu);
  };

}).call(this);
