# Page de Chat de podcastscience


## Installation sur heroku


* cloner le dépot 
* 
* mettre les variables d'environnement (pour la page admin) : 

```````
heroku config:add PSLIVE_ADMIN_PASSWORD="Mon password"
heroku config:add PSLIVE_URL="http://monapp.herokuapp.com/"

```````

* pusher le dépot : 

```````
git push heroku master

```````



## Bugs identifiés
[ ] Robin apparait 10 fois, a priori il se deconnecte souvent et donc ça buggue
[ ] @Azertoff n'arrive pas à venir sur le chat
[ ] les " et les & ne passent pas
[ ] certains liens ne passent pas (en fait on voit le code html)


