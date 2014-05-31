# Page de Chat de podcastscience


## Installation sur heroku


* cloner le dépot 
* 
* mettre les variables d'environnement (pour la page admin) : 

```````
heroku config:add PSLIVE_ADMIN_PASSWORD="Mon Super Password"
heroku config:add AWS_ACCESS_KEY_ID="Mon Access Key AWS"
heroku config:add AWS_SECRET_ACCESS_KEY="Mon Secret Access Key AWS"
heroku config:add PSLIVE_TWITTER_CONSUMERKEY="..."   
heroku config:add PSLIVE_TWITTER_CONSUMERSECRET="..."
heroku config:add PSLIVE_TWITTER_TOKENKEY="..."      
heroku config:add PSLIVE_TWITTER_TOKENSECRET="..."   


```````


* pusher le dépot : 

```````
git push heroku master

```````



## Bugs identifiés  

[X] scroll auto désactivable et désactivé quand on a scrollé
[X] bug sur le nombre de personnes en live