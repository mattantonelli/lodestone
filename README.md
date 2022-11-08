# Lodestone News

Unofficial webhook service and REST API for the [Final Fantasy XIV Lodestone](https://na.finalfantasyxiv.com/lodestone/) written in Ruby on Rails. You can find the original Sinatra implementation [here](https://github.com/mattantonelli/lodestone-sinatra).

## API

All of this application's data is made available through a RESTful JSON API. See the [documentation](https://lodestonenews.com/docs) for details.

## Dependencies
* Ruby (3.1.0)
* Rails (6.1.4)
* MariaDB / MySQL

## Installation
#### Clone and initialize the repository
```
git clone https://github.com/mattantonelli/lodestone
cd lodestone
bundle install
```

#### Set up the database
Create the MySQL databases `lodestone_development` as well as a database user with access to them

#### Create the necessary 3rd party applications
1. Create a new [Discord app](https://discord.com/developers/applications/) for user authentication. Take note of the **client ID** and **secret**.
    1. Set the redirect URI on the OAuth2 page of your app: `http://localhost:3000/webhook/save`
2. Configure the credentials file to match the format below using your data.
```
rm config/credentials.yml.enc
bin/rails credentials:edit
```
```yml
mysql:
  development:
    username: username
    password: password
  production:
    username: username
    password: password
discord:
  development:
    client_id: 123456789
    client_secret: abc123
  production:
    client_id: 234567890
    client_secret: def456
```

#### Load the database
```
bundle exec bin/rake db:migrate
```

### Prime the news cache
```
bin/rake news:cache[na,,10]
bin/rake news:cache[eu,,10]
bin/rake news:cache[de,,10]
bin/rake news:cache[fr,,10]
bin/rake news:cache[jp,,10]
bin/rake news:reset_cache
```

#### Schedule jobs
Run `whenever` to schedule the application's cronjobs.

```
bundle exec whenever -s 'environment=INSERT_ENV_HERE' --update-crontab
```

#### Start the server
```
bin/rails server
```

---

FINAL FANTASY is a registered trademark of Square Enix Holdings Co., Ltd.

FINAL FANTASY XIV © SQUARE ENIX CO., LTD.
