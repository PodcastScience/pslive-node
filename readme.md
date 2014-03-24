# Page de Chat de podcastscience


## Installation sur heroku


* cloner le dépot 
* 
* mettre les variables d'environnement (pour la page admin) : 

```````
heroku config:add PSLIVE_ADMIN_PASSWORD="Mon Super Password"
heroku config:add PSLIVE_SHARYPIC_APIKEY="Mon APIKEY Sharypic"

```````


* pusher le dépot : 

```````
git push heroku master

```````



## Bugs identifiés  

[X] scroll auto désactivable et désactivé quand on a scrollé
[ ] bug sur le nombre de personnes en live