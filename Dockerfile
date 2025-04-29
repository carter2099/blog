FROM ruby:3.4.3

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENV PORT=3099
EXPOSE $PORT

RUN RAILS_ENV=production bundle exec rails assets:precompile

# Start the Rails server
CMD ["bash", "-c", "RAILS_ENV=production bundle exec rails db:migrate && bundle exec rails server -p $PORT -b 0.0.0.0"]
