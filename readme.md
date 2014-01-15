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
[x] Robin apparait 10 fois, a priori il se deconnecte souvent et donc ça buggue  
[ ] @Azertoff n'arrive pas à venir sur le chat  
[x] les " et les & ne passent pas  
[x] certains liens ne passent pas (en fait on voit le code html)  

## Améliorations
[ ] Bouton en cours de live pour changer l'allure
[ ]