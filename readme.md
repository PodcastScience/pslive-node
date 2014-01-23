# Page de Chat de podcastscience


## Installation sur heroku


* cloner le dépot 
* 
* mettre les variables d'environnement (pour la page admin) : 

```````
heroku config:add PSLIVE_ADMIN_PASSWORD="Mon Super Password"

```````

* Modifier config.coffee dans assets.js avec la bonne url heroku



* pusher le dépot : 

```````
git push heroku master

```````



## Bugs identifiés  

[ ] scroll auto désactivable et désactivé quand on a scrollé
[ ] bug sur le nombre de personnes en live