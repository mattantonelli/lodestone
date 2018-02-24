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
4. `cp config/rack_attack.rb.example config/rack_attack.rb`
    * If you would like to enable rate limiting, configure this file appropriately.
    More details [here](https://github.com/kickstarter/rack-attack).
5. `bundle exec rackup`

## Usage

See the [wiki](https://github.com/mattantonelli/lodestone-api/wiki) for endpoint information.

## Screenshots

##### Webhook example

![Screenshot](https://i.imgur.com/mkQJMSx.png)

---

FINAL FANTASY is a registered trademark of Square Enix Holdings Co., Ltd.

FINAL FANTASY XIV © SQUARE ENIX CO., LTD.
