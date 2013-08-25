

require('coffee-script')
express = require('express')
routes = require('./routes')
user = require('./routes/user')
http = require('http')
path = require('path')


app = express()


#all environments
app.use require('connect-assets')()
app.set('port', process.env.PORT || 3000)
app.set('views', __dirname + '/views');
app.set('view engine', 'jade');
app.use(express.favicon());
app.use(express.logger('dev'));
app.use(express.bodyParser());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));

#development only
if ('development' == app.get('env'))
  app.use(express.errorHandler());


app.get('/', routes.index);
app.get('/admin', routes.admin);
app.get('/users', user.list);


httpServer = http.createServer(app).listen(app.get('port'), ->
  console.log('Express server listening on port ' + app.get('port'))
)

io = require('socket.io').listen(httpServer)