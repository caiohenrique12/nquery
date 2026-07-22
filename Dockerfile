FROM ruby:3.3-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential git libsqlite3-dev curl chromium chromium-driver && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile nquery.gemspec ./
COPY lib/nquery/version.rb lib/nquery/
RUN bundle install

COPY server/Gemfile server/
WORKDIR /app/server
RUN bundle install

WORKDIR /app
COPY . .

ENV CHROME_BIN=/usr/bin/chromium
ENV CHROMEDRIVER_PATH=/usr/bin/chromedriver
EXPOSE 3000
