# For Heroku deploy, replaces our local dev version?
FROM heroku/ruby

################################################################################
# Previous version:
#
#FROM ruby:2.2
#MAINTAINER marko@codeship.com
#
## Install apt based dependencies required to run Rails as
## well as RubyGems. As the Ruby image itself is based on a
## Debian image, we use apt-get to install those.
#RUN apt-get update && apt-get install -y \
#  build-essential \
#  nodejs
#
## Configure the main working directory. This is the base
## directory used in any further RUN, COPY, and ENTRYPOINT
## commands.
#RUN mkdir -p /app
#WORKDIR /app
#
## Copy the Gemfile as well as the Gemfile.lock and install
## the RubyGems. This is a separate step so the dependencies
## will be cached unless changes to one of those two files
## are made.
#COPY Gemfile Gemfile.lock ./
#RUN gem install bundler && bundle install --jobs 20 --retry 5
#
## Copy the main application.
#COPY . ./
#
## Expose port 3000 to the Docker host, so we can access it
## from the outside.
#EXPOSE 3000
#
## Configure an entry point, so we don't need to specify
## "bundle exec" for each of our commands. You can now run commands without
## specifying "bundle exec" on the console. If you need to, you can override the
## entrypoint as well.
##     docker run -it demo "rake test"
##     docker run -it --entrypoint="" demo "ls -la"
##ENTRYPOINT ["bundle", "exec"]
#
## The main command to run when the container starts. Also
## tell the Rails dev server to bind to all interfaces by
## default.
#CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
