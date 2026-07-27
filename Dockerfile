FROM ruby:3.3
WORKDIR /app
COPY Gemfile ./
RUN bundle install
COPY . .
EXPOSE 4567
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:4567"]
