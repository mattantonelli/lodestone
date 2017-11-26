# Lodestone

Unofficial webhook service and REST API for the [Final Fantasy XIV Lodestone](https://na.finalfantasyxiv.com/lodestone/).

http://lodestone.raelys.com/

## Requirements
* Ruby ~> 2.4.1
* [Redis](https://redis.io/)

## Installation
1. `git clone https://github.com/mattantonelli/lodestone-api`
2. `bundle install`
3. `cp config/webhook.yml.example config/webhook.yml`
    * [Create an app](https://discordapp.com/developers/applications/me) and set these values appropriately
4. `bundle exec rackup`

## Usage

See the [wiki](https://github.com/mattantonelli/lodestone-api/wiki) for endpoint information.

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
