# Page de Chat de podcastscience


## Installation sur heroku


* cloner le dépot 
* 
* mettre les variables d'environnement (pour la page admin) : 

```````
heroku config:add PSLIVE_ADMIN_PASSWORD="psm3HERdvd"
heroku config:add PSLIVE_URL="http://podsource.herokuapp.com/"

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



$ heroku login

Email: 6clicks@gmail.com
Password: psm3HERdvd
Could not find an existing public key.
Would you like to generate one? [Yn] 
Generating new SSH public key.
Uploading ssh public key /Users/adam/.ssh/id_rsa.pub