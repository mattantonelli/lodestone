# Lodestone

Unofficial webhook service and REST API for the [Final Fantasy XIV Lodestone](https://na.finalfantasyxiv.com/lodestone/).

## Requirements
* Ruby ~> 2.4.1
* [Redis](https://redis.io/)

## Installation
1. `git clone https://github.com/mattantonelli/lodestone-api`
2. `bundle install`
3. [Create a Discord app](https://discord.com/developers/applications/me)
4. Add the following redirects in the Discord app's OAuth2 settings. Update the host/port appropriately.
    * http://localhost:9292/authorize
    * http://na.localhost:9292/authorize
    * http://eu.localhost:9292/authorize
    * http://fr.localhost:9292/authorize
    * http://de.localhost:9292/authorize
    * http://jp.localhost:9292/authorize
3. `cp config/webhook.yml.example config/webhook.yml`
    * Set these values appropriately based on the Discord app you created earlier
3. `cp config/hosts.yml.example config/hosts.yml`
    * Set these values appropriately. They should be the same as your redirects minus the `/authorize`.
4. `bundle exec rackup`

## Usage

See the [documentation](http://na.lodestonenews.com/docs) for API information.

## Screenshots

##### Webhook example

![Screenshot](https://i.imgur.com/mkQJMSx.png)

## Installation and usage with Docker

1. Run an instance of redis:alpine named redis for data storage. Don't forget to create a persistant data storage like /opt/redis/.
    *  docker run --rm --name redis -v /opt/redis/:/data/ redis:alpine
2. Get the lodestone webhook source
    * `git clone https://github.com/mattantonelli/lodestone-api`
3. Build the docker image
    * `docker build -t lodestone:latest .`
4. Run the image. Adjust the client port (8080) to your needs
    * `docker run --rm --name lodestone --link redis -p 127.0.0.1:8080:9292 lodestone:latest`

---

FINAL FANTASY is a registered trademark of Square Enix Holdings Co., Ltd.

FINAL FANTASY XIV © SQUARE ENIX CO., LTD.
