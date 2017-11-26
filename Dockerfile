FROM ruby:alpine

RUN apk --no-cache add build-base ruby-dev tzdata

RUN mkdir /app
ADD . /app/ 
WORKDIR /app/

ENV APP_ENV=production
ENV REDIS_URL="redis://redis"

EXPOSE 9292
RUN /usr/local/bin/bundle install
CMD ["/usr/local/bin/bundle", "exec", "rackup", "-o", "0.0.0.0"]
