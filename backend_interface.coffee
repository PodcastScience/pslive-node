http = require 'http'
mime = require 'mime'
gm = require('gm').subClass({ imageMagick: true })

class Backend


	constructor: (params) ->
		@url = params.url 
		@port = params.port
		@id_emission = params.id_emission
		console.log "mise en place du backend",params


	http_request_callback = (res,cb) ->
		str=""
		res.on 'data',  (chunk) ->
			str += chunk
		res.on 'end',  () ->
			try 
				data_JSON = JSON.parse(str)
			catch e
				console.log  "JSON invalide",e
				console.log str
			cb data_JSON 
	


	get_default_emission: (cb) ->
		headers = {
			'Content-Type': 'application/json'
		}
		options = {
			host: @url,
			port: @port,
			path: '/episodes_default.json',
			method: 'get',
			headers: headers
		}
		req = http.request options, (res)=> 
			http_request_callback res, (data)=>
				try
					@id_emission=data.id 
					console.log "chargement de l'emission par defaut",@id_emission
					try 
						chatroom = JSON.parse(data.chatroom)
					catch e
						console.log  "Erreur du parsing de la chatroom",e
					cb(data.number,data.title,chatroom)
				catch e
					@id_emission = 0
					cb(0,"Bienvenue sur le balado qui fait aimer la science!",{})
		req.on 'error',(err)->console.log Error
		req.end()


	upload_image: (episode,nom,auteur,user,avatar,message,data,img_format,cb) ->
		console.log "upload_image/Entrée dans upload_image"
		console.log "upload_image/id_emission",@id_emission

		
		_upload = (episode,nom,auteur,user,avatar,message,databin64,url,port,id_emission)->
			try
				params = JSON.stringify({
					'name': nom, 
					'msg': message,
					'author': auteur,
					'user': user,
					'avatar': avatar,
					'image': databin64,
					'content_type': mime.lookup(nom),
					'id_episode': id_emission
				})
				console.log "upload_image/upload d'une image : ",params.name
				headers = {
					'Content-Type': 'application/json',
					'Content-Length':  Buffer.byteLength(params, 'utf-8')
				}
				options = {
					host: url,
					port: port,
					path: '/upload_api.json',
					method: 'post',
					form: params,
					headers: headers
				}
				console.log "upload_image/options",options
				req = http.request options, (res)-> 
					try
						http_request_callback res, (data)=>
							try
								cb data.url
							catch e
								console.log "upload_image/cb", e
					catch e
						console.log "upload_image/req:",e
					
				req.on 'error', (err)->console.log err
				req.write params  
				req.end()
			catch e
				console.log "upload_image/Erreur d'upload",e



		id_emission	= @id_emission
		url			= @url
		port 		= @port



		try
			console.log "upload_image/transformation du l'image en buffer"
			img_buf = new Buffer(data, 'binary')
			console.log "upload_image/verification de la taille de l'image"
			if img_buf.length > 1024*1024 
				console.log "upload_image/image trop grande."
				_gm=gm(img_buf,nom)
				console.log "upload_image/retaillage de l'image"
				_gm=_gm.resize null,600
				console.log  "upload_image/transformation du l'image retaillée en buffer (format " + img_format + ")"
				_gm=_gm.toBuffer img_format, (err, buffer)->
					if (err) 
						console.log "upload_image/erreur dans la generation du buffer"
						return handle(err)
					console.log "upload_image/upload de l'image retaillée"
					_upload(episode,nom,auteur,user,avatar,message,buffer.toString('base64'),url,port,id_emission)
			else
				console.log "upload_image/upload de l'image"
				_upload(episode,nom,auteur,user,avatar,message,img_buf.toString('base64'),url,port,id_emission)
		catch e
			console.log "upload_image/Erreur de retaillage",e
			#console.log databin64



	upload_video: (episode,nom,auteur,user,avatar,message,url,cb) ->
		console.log "upload_video/Entrée dans upload_video"
		try
			params = JSON.stringify({
				'name': nom, 
				'msg': message,
				'author': auteur,
				'user': user,
				'avatar': avatar,
				'url': url,
				'id_episode': @id_emission
			})
			console.log "upload_video/envoi d'une video : ",params.name
			headers = {
				'Content-Type': 'application/json',
				'Content-Length':  Buffer.byteLength(params, 'utf-8')
			}
			options = {
				host: @url,
				port: @port,
				path: '/add_video.json',
				method: 'post',
				form: params,
				headers: headers
			}
			req = http.request options, (res)-> 
				try
					http_request_callback res, (data)=>
						try
							cb data.url
						catch e
							console.log "upload_video/cb", e
						
						
				catch e
					console.log "upload_video/req:",e
				
			req.on 'error', (err)->console.log err
			req.write params  
			req.end()
		catch e
			console.log "upload_video/Erreur upload",e


	download_images: (cb) ->
		headers = {
			'Content-Type': 'application/json'
		}
		options = {
			host: @url,
			port: @port,
			path: '/episodes/' + @id_emission + '/images.json',
			method: 'get',
			headers: headers
		}
		console.log "upload_video/download des images : ", @id_emission
		req = http.request options, (res)-> 
			http_request_callback res, (data)->
				console.log "upload_video/",data
				meta_tmp=[]
				try
					data.map (image)->
						if image.media_type == 'img'
							img = {
								'nom' : image.name, 
								'url' : image.url,
								'poster' : image.author,
								'poster_user' : image.user,
								'avatar' : image.avatar,
								'tweet' : image.msg
								'media_type' : 'img'
							}
						if image.media_type == 'video'
							img = {
								'nom' : image.name, 
								'url' : image.url,
								'poster' : image.author,
								'poster_user' : image.user,
								'avatar' : image.avatar,
								'tweet' : image.msg
								'media_type' : 'video'
							}
						meta_tmp.push img
						console.log "upload_video/",img.url
				catch e
					console.log "upload_video/pas d'image"
				console.log "upload_video/",meta_tmp
				cb meta_tmp
		req.on 'error',(err)->console.log "upload_video/",err
		req.end()


	select_emission: (nomEvent,episode,cb) ->
		console.log "select_emission/entrée dans la fonction select_emission"
		params = JSON.stringify({
			number: nomEvent, 
			title: episode
		})
		console.log "select_emission/params*"+params+"*"
		console.log "select_emission/length",params.length
		headers = {
			'Content-Type': 'application/json'
			'Content-Length':  Buffer.byteLength(params, 'utf-8')
		}
		options = {
			host: @url,
			port: @port,
			path: '/episodes.json',
			method: 'post',
			form: params,
			headers: headers
		}
		req = http.request options, (res)=>
			http_request_callback res, (data)=>
				@id_emission=data.id	
				try 
					chatroom = JSON.parse(data.chatroom)
				catch e
					console.log  "select_emission/Erreur du parsing de la chatroom",e
				cb chatroom

		req.on('error', (err)->console.log 'select_emission/',err)
		req.write params 
		req.end()


	set_chatroom: (chatroom)->
		params = JSON.stringify({
			'chatroom': chatroom
		})
		headers = {
			'Content-Type': 'application/json',
			'Content-Length':  Buffer.byteLength(params, 'utf-8')
		}
		options = {
			host: @url,
			port: @port,
			path: '/episodes/' + @id_emission + '/chatroom',
			method: 'patch',
			form: params,
			headers: headers
		}
		req = http.request options, (res)-> 
		req.on('error',(err)->console.log "set_chatroom",err)
		req.write params 
		req.end()


module.exports = Backend