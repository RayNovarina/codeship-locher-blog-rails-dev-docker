// based on tutorial:
    Running a Rails Development Environment in Docker
    2015-07-14 by Marko Locher
    Last updated:Sunday, February 26, 2017
at: https://blog.codeship.com/running-rails-development-environment-docker/

// As of up to and including Step 2: Dockerizing a Rails Application
// Works locally for me!

with these changes:
Step two:
docker run -it demo "bundle exec rake test"
should not have quotes, i.e.
docker run -it demo bundle exec rake test

// To run shell in running web server container:
docker run -it demo bash

-------------------------------------------------------
Suppose we have a (very) simple new Rails application:
  $ gem install rails bundler
  $ rails new demo
  $ cd demo
  $ bundle install
  Using rake 12.0.0
  Using concurrent-ruby 1.0.5
     .....
  Using jquery-rails 4.2.2
  Using web-console 3.4.0
  Using rails 5.0.2
  Using sass-rails 5.0.6
  Bundle complete! 15 Gemfile dependencies, 62 gems now installed.
  Use `bundle show [gemname]` to see where a bundled gem is installed.

  $ bundle exec rake test
     Run options: --seed 37996
     # Running:
     Finished in 0.000482s, 0.0000 runs/s, 0.0000 assertions/s.
     0 runs, 0 assertions, 0 failures, 0 errors, 0 skips

  $ bundle exec rails server
     => Booting Puma
     => Rails 5.0.2 application starting in development on http://localhost:3000
     => Run `rails server -h` for more startup options
     Puma starting in single mode...
     * Version 3.7.1 (ruby 2.4.0-p0), codename: Snowy Sagebrush
     * Min threads: 5, max threads: 5
     * Environment: development
     * Listening on tcp://localhost:3000
     Use Ctrl-C to stop
     Started GET "/" for ::1 at 2017-03-19 23:17:17 -0700
     Processing by Rails::WelcomeController#index as HTML
        ....
     Completed 200 OK in 27ms (Views: 13.9ms | ActiveRecord: 0.0ms)

  $ docker run -it demo bash
   root@a86774c04918:/app# pwd
   /app
   root@a86774c04918:/app# ls
   Dockerfile  Gemfile  Gemfile.lock  README.md  Rakefile  app  bin  config  config.ru  db  lib  log  public  test  tmp  vendor
   root@a86774c04918:/app# exit

  ----------------------------------------------------
  Step 2: Dockerizing a Rails Application

   Now that we have Docker installed and running, it is time to get our application running on it. Docker applications are configured via a Dockerfile, which defines how the container is built.

   Many images are readily available, and you can search for a suitable base image at the Docker Hub. We’ll use the ruby:2.2 base image.

   FROM ruby:2.2
   MAINTAINER marko@codeship.com

   # Install apt based dependencies required to run Rails as
   # well as RubyGems. As the Ruby image itself is based on a
   # Debian image, we use apt-get to install those.
   RUN apt-get update && apt-get install -y \
    build-essential \
    nodejs

  # Configure the main working directory. This is the base
  # directory used in any further RUN, COPY, and ENTRYPOINT
  # commands.
  RUN mkdir -p /app
  WORKDIR /app

  # Copy the Gemfile as well as the Gemfile.lock and install
  # the RubyGems. This is a separate step so the dependencies
  # will be cached unless changes to one of those two files
  # are made.
  COPY Gemfile Gemfile.lock ./
  RUN gem install bundler && bundle install --jobs 20 --retry 5

  # Copy the main application.
  COPY . ./

  # Expose port 3000 to the Docker host, so we can access it
  # from the outside.
  EXPOSE 3000

  # The main command to run when the container starts. Also
  # tell the Rails dev server to bind to all interfaces by
  # default.
  CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

  After adding the above file as Dockerfile to your repository, we can now build
  the container and start running commands with it. We specify a tag via
  the -t option, so we can reference the container later on.

    docker build -t demo .
    docker run -it demo bundle exec rake test
    docker run -itP demo

  Here are some explanations for the commands above:
  docker run runs tasks in a Docker container. This is most commonly used for
  one-off tasks but is also very helpful in development.
  The -P option causes all ports defined in the Dockerfile to be exposed to
  unprivileged ports on the host and thus be accessible from the outside.
  If we don’t specify a command to run on the command line, the command defined
  by the CMD setting will be run instead.

We now have our Rails application running inside a Docker container, but how do
 we actually access it from our computer? We will use docker ps, a handy tool
 to list running Docker processes as well as additional information about them.

  $ docker ps
  CONTAINER ID        IMAGE               COMMAND                CREATED             STATUS              PORTS                     NAMES
  eb018d2ca6e2        demo           "bundle exec 'rails    10 seconds ago      Up 9 seconds        0.0.0.0:32769->3000/tcp   pensive_ritchie

  We can see the container ID, the image it is based on, which command it is
  running, and the mapping of any exposed ports. With this information at hand,
  we can now open the app in our browser http://localhost:32769.

----------------------------------------------------

  $ git init

   Initialized empty Git repository in
   /Users/raynovarina/Sites/AtomProjects/Docker/Dockerizing-Rails/codeship/demo/.git/

   $ git remote add origin https://github.com/RayNovarina/codeship-locher-blog-rails-dev-docker.git
   $ git status
    On branch master

   $ git add .
   $ git commit -m "Tutorial works up to and including step two. Runs rails app in container."
   $ git push origin master
        .....
    remote: Resolving deltas: 100% (2/2), done.
    To https://github.com/RayNovarina/codeship-locher-blog-rails-dev-docker.git
    * [new branch]      master -> master

Without any further configuration, this provides us with a Rails application,
using SQLite as a database. And if we want to, we can run our tests and start
the development server to take a look in our browser.

  $ bundle exec rake test
  $ bundle exec rails server

We can now access the default start page at
  localhost:3000.
It’s not a very useful app, but it’ll do for our purpose.

---------------------------------------
Step 3: Docker Volumes

Docker supports what it calls volumes. These are mount points which let you
access data from either the native host or another container. In our case, we
can mount our application folder into the container and don’t need to build a
new image for each change. Simply specify the local folder as well as where to
mount it in the Docker container when calling docker run, and you’re good to go!

  $ docker run -itP -v $(pwd):/app demo
  => Booting Puma
  => Rails 5.0.2 application starting in development on http://0.0.0.0:3000
  => Run `rails server -h` for more startup options
  Puma starting in single mode...
  * Version 3.7.1 (ruby 2.2.6-p396), codename: Snowy Sagebrush
  * Min threads: 5, max threads: 5
  * Environment: development
  * Listening on tcp://0.0.0.0:3000
  Use Ctrl-C to stop
  Started GET "/" for 172.17.0.1 at 2017-03-20 06:37:44 +0000

On another window:
  $ docker run -it demo bash
  root@a86774c04918:/app# pwd
  /app
  root@a86774c04918:/app# ls
  Dockerfile  Gemfile  Gemfile.lock  README.md  Rakefile  app  bin  config  config.ru  db  lib  log  public  test  tmp  vendor
  root@a86774c04918:/app# exit
  exit

--------------------------------------------
Step 4: Improvements

Dockerfile Best Practices lists some ways to improve performance and create easy to use Dockerfiles. One of those tips is using a .dockerignore file.

.dockerignore
Similar to a .gitignore file, .dockerignore lets us specify which files are excluded and not transferred to the container during the build. This is a great way to speed up the build times, by excluding files not needed in the container (e.g., the .git subdirectory). Let’s add the following .dockerignore file to our project
.git*
db/*.sqlite3
db/*.sqlite3-journal
log/*
tmp/*
Dockerfile
README.rdoc

-------------------------------------------------------------------
Entrypoint

NOTE: i skipped this, prefer to be explicit with "bundle exec"
Because most of the commands we run on the Rails container will be prepended by bundle exec, we can define an [ENTRYPOINT] for all our commands. Simply change the Dockerfile like this:
# Configure an entry point, so we don't need to specify
# "bundle exec" for each of our commands.
ENTRYPOINT ["bundle", "exec"]

# The main command to run when the container starts. Also
# tell the Rails dev server to bind to all interfaces by
# default.
CMD ["rails", "server", "-b", "0.0.0.0"]
You can now run commands without specifying bundle exec on the console. If you need to, you can override the entrypoint as well.
docker run -it demo "rake test"
docker run -it --entrypoint="" demo "ls -la"

-----------------------------------------------------

Locales

NOTE: i skipped this.
If you’re not happy with the default locale in your Docker container, you can switch to another one quite easily. Install the required package, regenerate the locales, and configure the environment variables.
...

# Install apt based dependencies required to run Rails as
# well as RubyGems. As the Ruby image itself is based on a
# Debian image, we use apt-get to install those.
RUN apt-get update && apt-get install -y \
  build-essential \
  locales \
  nodejs

# Use en_US.UTF-8 as our locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

...

-------------------------------------------------------

Basic Compose Configuration

To get Docker Compose installed, please follow the installation instructions on
their website. Once this is done, let’s duplicate our configuration to work with
Compose. Add a docker-compose.yml file to your repository and include the
following configuration:

  app:
    build: .
    command: rails server -p 3000 -b '0.0.0.0'
    volumes:
      - .:/app
    ports:
      - "3000:3000"

Even for a single container environment this has some (smaller) improvements
over using docker directly. We can specify the VOLUME definition directly in the
configuration file; we don’t need to specify it on the command line. We can also
define the port on the Docker host our application will be available at and
don’t need to look it up.

(first reset tutorial and delete docker containers, images:
  - Delete every Docker containers
  # Must be run first because images are attached to containers
  $ docker rm -f $(docker ps -a -q)

  - Delete every Docker image
  $ docker rmi -f $(docker images -q)
)

With the configuration above, running your development environment is as simple as running two commands:

  $ docker-compose build

  Building app
  Step 1/10 : FROM ruby:2.2
    2.2: Pulling from library/ruby
    693502eb7dfb: Pull complete
      .....
  Installing jquery-rails 4.2.2
  Bundle complete! 15 Gemfile dependencies, 62 gems now installed.
      .....
  Removing intermediate container ce9853ccc7fb
  Step 10/10 : CMD bundle exec rails server -b 0.0.0.0
    ---> Running in 02d1821650cc
    ---> a9556fec667b
  Removing intermediate container 02d1821650cc
  Successfully built a9556fec667b

  $ docker images

    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    demo_app            latest              a9556fec667b        12 minutes ago      853 MB
    ruby                2.2                 2f84973823b8        2 days ago          726 MB

  $ docker-compose up

    Creating demo_app_1
    Attaching to demo_app_1
    app_1  | => Booting Puma
    app_1  | => Rails 5.0.2 application starting in development on http://0.0.0.0:3000
    app_1  | => Run `rails server -h` for more startup options
    app_1  | Puma starting in single mode...
    app_1  | * Version 3.7.1 (ruby 2.2.6-p396), codename: Snowy Sagebrush
    app_1  | * Min threads: 5, max threads: 5
    app_1  | * Environment: development
    app_1  | * Listening on tcp://0.0.0.0:3000
    app_1  | Use Ctrl-C to stop

  $ docker ps

    CONTAINER ID        IMAGE        COMMAND                   PORTS                     NAMES
    699d94c6e929        demo_app     "rails server -p 3..."    0.0.0.0:3000->3000/tcp    demo_app_1

  Access app via local browser:

    http://localhost:3000/

  Results in Rails "yay" screen.

---------------------------------------------------
Step 5: Moving your Development Environment to PostgreSQL

While SQLite might be fine for a simple app, you wouldn’t use it in production.
So let’s move our development environment over to PostgreSQL instead.
We could add the database to our container, but there’s a better way to do this.
Use Docker Compose to provision the database in a separate container and link
those two together.

Adding PostgreSQL

We could now create a new Dockerfile for running PostgreSQL, but luckily we
don’t need to. There is a readily available PostgreSQL Docker image available on
the Docker Hub, so let’s just use that instead.

Change docker-compose.yml to:

  app:
    build: .
    command: rails server -p 3000 -b '0.0.0.0'
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    links:
      - postgres
  postgres:
    image: postgres:9.4
    # persist the database between containers by storing it in a volume
    volumes:
      - demo-postgres:/var/lib/postgresql/data
    ports:
      - "5432"

We defined a new container called postgres, based on the PostgreSQL 9.4 image
(there are images for previous versions available as well), configured the port
on the new image, and told our app container to define a link to the database.
Update, Compose now recommends to use the hostnames instead of environment
variables to access linked services.

PostgreSQL data persistence:
In docker-compose.yml, the lines

  postgres:
    volumes:
      - demo-postgres:/var/lib/postgresql/data

Persist the database between containers by storing it in a volume per:
https://www.andreagrandi.it/2015/02/21/how-to-create-a-docker-image-for-postgresql-and-persist-data/
Otherwise, "docker-compose down" will stop the container and the database will
be lost and upon "docker-compose up" and a access to localhost:3000 will result
in Rails error:
  Fail: app_development database not found.
Another workaround is to:

  $ docker-compose down
  Stopping demo_app_1 ... done
  Stopping demo_postgres_1 ... done
  Removing demo_app_1 ... done
  Removing demo_postgres_1 ... done

  On another window:
  $ docker-compose up

  Back to first window:
  $ docker-compose run -e "RAILS_ENV=development" app rake db:create db:migrate
  Created database 'app_development'
  Created database 'app_test'


``ruby
Replace rails config/database.yml with:

default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5
  timeout: 5000
  username: postgres
  host: postgres
  port: 5432

development:
  <<: *default
  database: app_development

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run
# "rake". Do not set this db to the same as development or
# production.
test:
  <<: *default
  database: app_test

``

We also need to change our Gemfile and remove the sqlite3 gem and add pg instead.
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use PostgreSQL as the database for Active Record.
gem 'pg'

Having made those changes, let’s rebuild our containers and configure the database.

  $ docker-compose build
    postgres uses an image, skipping
    Building app
    Step 1/10 : FROM ruby:2.2
      ---> 2f84973823b8
    Removing intermediate container 5057b1604531
        .....
      ---> Running in 5123fa8f46fe
      ---> e65c6a2858c8
    Removing intermediate container 5123fa8f46fe
    Successfully built e65c6a2858c8

  $ docker-compose up
    Pulling postgres (postgres:9.4)...
    9.4: Pulling from library/postgres
    693502eb7dfb: Already exists
       ....
    Creating demo_app_1
    Attaching to demo_postgres_1, demo_app_1
    postgres_1  | The files belonging to this database system will be owned by user "postgres".
        ........
    postgres_1  | syncing data to disk ... ok
    postgres_1  |
    postgres_1  | Success. You can now start the database server using:
    postgres_1  |
    postgres_1  |     postgres -D /var/lib/postgresql/data
    postgres_1  | or
    postgres_1  |     pg_ctl -D /var/lib/postgresql/data -l logfile start
    postgres_1  |
    postgres_1  | ****************************************************
    postgres_1  | WARNING: No password has been set for the database.
    postgres_1  |          This will allow anyone with access to the
    postgres_1  |          Postgres port to access your database. In

    postgres_1  |          Docker's default configuration, this is
    postgres_1  |          effectively any other container on the same
    postgres_1  |          system.
    postgres_1  |
    postgres_1  |          Use "-e POSTGRES_PASSWORD=password" to set
    postgres_1  |          it in "docker run".
    postgres_1  | ****************************************************
    postgres_1  | waiting for server to start....LOG:  database system was shut down at 2017-03-20 22:10:40 UTC
    postgres_1  | LOG:  MultiXact member wraparound protections are now enabled
    postgres_1  | LOG:  autovacuum launcher started
    postgres_1  | LOG:  database system is ready to accept connections
    postgres_1  |  done
    postgres_1  | server started
    postgres_1  | ALTER ROLE
    postgres_1  |
    postgres_1  |
    postgres_1  | /usr/local/bin/docker-entrypoint.sh: ignoring /docker-entrypoint-initdb.d/*
    postgres_1  |
        .........
    app_1       | => Booting Puma
    app_1       | => Rails 5.0.2 application starting in development on http://0.0.0.0:3000
    app_1       | => Run `rails server -h` for more startup options
    app_1       | Puma starting in single mode...
    app_1       | * Version 3.7.1 (ruby 2.2.6-p396), codename: Snowy Sagebrush
    app_1       | * Min threads: 5, max threads: 5
    app_1       | * Environment: development
    app_1       | * Listening on tcp://0.0.0.0:3000
    app_1       | Use Ctrl-C to stop
    app_1       | Started GET "/" for 172.17.0.1 at 2017-03-20 22:11:43 +0000
    app_1       | Cannot render console from 172.17.0.1! Allowed networks: 127.0.0.1, ::1, 127.0.0.0/127.255.255.255


  $ docker-compose run app bundle exec rake db:create
    Created database 'app_development'
    Created database 'app_test'

  $ docker-compose run app bundle exec rake db:migrate

  or

  $ docker-compose run -e "RAILS_ENV=development" app bundle exec rake db:create db:migrate

  $ docker images
    REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
    demo_app            latest              e65c6a2858c8        2 minutes ago       861 MB
    <none>              <none>              d7417dce7ad0        16 minutes ago      853 MB
    ruby                2.2                 2f84973823b8        2 days ago          726 MB
    postgres            9.4                 d8afe9d2b0b4        2 weeks ago         263 MB

  $ docker ps
    CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS
    NAMES
    8f210443b011        postgres:9.4        "docker-entrypoint..."   30 seconds ago      Up 29 seconds       0.0.0.0:32771->5432/tcp
    demo_postgres_1

    Access app via local browser:

      http://localhost:3000/

    Results in Rails "yay" screen.


================================================================================

Testing Your Rails Application with Docker
2015-07-22 by Marko Locher at:
https://blog.codeship.com/testing-rails-application-docker/

  Running your basic test suite is done quite easily. With the configuration
  from my last post, you can simply run the following commands to spin up the
  environment, create and seed the database, and run your test suite.

    $ docker-compose up
    $ docker-compose run -e "RAILS_ENV=test" app bundle exec rake db:create db:migrate
    $ docker-compose run -e "RAILS_ENV=test" app bundle exec rake test

================================================================================

Deploying Your Docker Rails App
2015-10-27 by Leigh Halliday at:
https://blog.codeship.com/deploying-docker-rails-app/

In this article, we’ll talk about how to deploy our Docker container quickly and
simply to Heroku.

Simple Rails Docker on Heroku

Most Rails developers are familiar with Heroku and have probably at one time or
another deployed an app to it, even if it was just a personal blog or something
you were playing around with. I’ve used Heroku both for personal projects and
also for larger client projects with lots of success. Heroku isn’t just for
Rails apps… you can deploy PHP apps, NodeJS apps, Elixir apps, and as of earlier
this year you can even deploy Docker containers.

--------------------------------------------------------------------------------
Getting set up

The first thing you’ll need to do is install the container-registry plugin by
running:

  $ heroku plugins:install heroku-container-registry

Log in to the Heroku container registry:
  $ heroku container:login

--------------------------------------------------------------------------------

Once you’ve set up a normal Rails app (either new or existing), you’ll need to
add an additional file to the root called app.json.

{
  "name": "Codeship Dockerizing Rails app",
  "description": "A base Rails5/Postgres/Puma Dockerized app for Heroku deployment",
  "image": "heroku/ruby",
  "addons": [
    "heroku-postgresql"
  ]
}

--------------------------------------------------------------------------------

Heroku has a number of different images you can use for each of the different
languages they support. Next we’ll create a file called Procfile which Heroku
uses to help start our app.

  web: bundle exec puma -C config/puma.rb

--------------------------------------------------------------------------------

The next step is to generate a new Dockerfile.

The Dockerfile is extremely small, only pulling from the heroku/ruby image:

  FROM heroku/ruby

------------------------------------------------------
NOTE: per heroku github repository for the heroku/ruby image at:
  https://github.com/heroku/docker-ruby
  Latest commit 86199e7  on Aug 19, 2015

Readme:
-------

  Heroku Ruby Docker Image

  This image is for use with Heroku Docker CLI.

  Usage

  Your project must contain the following files:

  Gemfile and Gemfile.lock
  Ruby 2.2.3
  assets:precompile rake task
  Procfile (see the Heroku Dev Center for details)

  Then create an app.json file in the root directory of your application with at least these contents:
  {
    "name": "Your App's Name",
    "description": "An example app.json for heroku-docker",
    "image": "heroku/ruby"
  }

  Install the heroku-docker toolbelt plugin:

    $ heroku plugins:install heroku-docker

  Initialize your app:

    $ heroku docker:init
    Wrote Dockerfile
    Wrote docker-compose.yml

  And run it with Docker Compose:

    $ docker-compose up web

  The first time you run this command, Bundler will download all dependencies
  into the container, precompile your assets (using the assets:precompile rake
  task), build your application, and then run it. Subsequent runs will use
  cached dependencies (unless yourGemfileorGemfile.lock has changed).

  You'll be able to access your application at http://<docker-ip>:8080,
  where <docker-ip> is either the value of running boot2docker ip if you are on
  Mac or Windows. If you're running it natively, you'll need to use docker
  inspect to find the IPAddress key.


Dockerfile:
-----------

  FROM heroku/cedar:14
  MAINTAINER Terence Lee <terence@heroku.com>

  RUN mkdir -p /app/user
  WORKDIR /app/user

  ENV GEM_PATH /app/heroku/ruby/bundle/ruby/2.2.0
  ENV GEM_HOME /app/heroku/ruby/bundle/ruby/2.2.0
  RUN mkdir -p /app/heroku/ruby/bundle/ruby/2.2.0

  # Install Ruby
  RUN mkdir -p /app/heroku/ruby/ruby-2.2.3
  RUN curl -s --retry 3 -L https://heroku-buildpack-ruby.s3.amazonaws.com/cedar-14/ruby-2.2.3.tgz |
      tar xz -C/app/heroku/ruby/ruby-2.2.3
  ENV PATH /app/heroku/ruby/ruby-2.2.3/bin:$PATH

  # Install Node
  RUN curl -s --retry 3 -L http://s3pository.heroku.com/node/v0.12.7/node-v0.12.7-linux-x64.tar.gz |
      tar xz -C /app/heroku/ruby/
  RUN mv /app/heroku/ruby/node-v0.12.7-linux-x64 /app/heroku/ruby/node-0.12.7
  ENV PATH /app/heroku/ruby/node-0.12.7/bin:$PATH

  # Install Bundler
  RUN gem install bundler -v 1.9.10 --no-ri --no-rdoc
  ENV PATH /app/user/bin:/app/heroku/ruby/bundle/ruby/2.2.0/bin:$PATH
  ENV BUNDLE_APP_CONFIG /app/heroku/ruby/.bundle/config

  # Run bundler to cache dependencies
  ONBUILD COPY ["Gemfile", "Gemfile.lock", "/app/user/"]
  ONBUILD RUN bundle install --path /app/heroku/ruby/bundle --jobs 4
  ONBUILD ADD . /app/user

  # How to conditionally `rake assets:precompile`?
  ONBUILD ENV RAILS_ENV production
  ONBUILD ENV SECRET_KEY_BASE $(openssl rand -base64 32)
  ONBUILD RUN bundle exec rake assets:precompile

  # export env vars during run time
  RUN mkdir -p /app/.profile.d/
  RUN echo "cd /app/user/" > /app/.profile.d/home.sh
  ONBUILD RUN echo "export PATH=\"$PATH\" GEM_PATH=\"$GEM_PATH\" GEM_HOME=\"$GEM_HOME\" RAILS_ENV=\"\${RAILS_ENV:-$RAILS_ENV}\" SECRET_KEY_BASE=\"\${SECRET_KEY_BASE:-$SECRET_KEY_BASE}\" BUNDLE_APP_CONFIG=\"$BUNDLE_APP_CONFIG\"" > /app/.profile.d/ruby.sh

  COPY ./init.sh /usr/bin/init.sh
  RUN chmod +x /usr/bin/init.sh

  ENTRYPOINT ["/usr/bin/init.sh"]

init.sh
-------
  ```ruby
    #!/bin/bash

    for SCRIPT in /app/.profile.d/*;
      do source $SCRIPT;
    done

    exec "$@"
  ```
--------------------------------------------------------------------------------

The docker-compose.yml file is a little more involved and sets up two linked
images (one for Ruby/Rails and one for Postgres):

web:
  build: .
  command: 'bash -c ''bundle exec puma -C config/puma.rb'''
  working_dir: /app/user
  environment:
    PORT: 8080
    DATABASE_URL: 'postgres://postgres:@herokuPostgresql:5432/postgres'
  ports:
    - '8080:8080'
  links:
    - herokuPostgresql
shell:
  build: .
  command: bash
  working_dir: /app/user
  environment:
    PORT: 8080
    DATABASE_URL: 'postgres://postgres:@herokuPostgresql:5432/postgres'
  ports:
    - '8080:8080'
  links:
    - herokuPostgresql
  volumes:
    - '.:/app/user'
herokuPostgresql:
  image: postgres

One great benefit of Heroku Docker is that not only can you deploy Docker
containers to Heroku, but you can also use this to run a “Heroku-like”
environment locally for development.
Not only can you deploy @Docker containers to @Heroku, you can run a
Heroku-like env locally.

--------------------------------------------------------------------------------

You’ll notice that there is an environment variable called DATABASE_URL in the
new above docker-compose.yml file. We can modify our database.yml file to use
this ENV variable to connect to the database.

default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5
  timeout: 5000
  username: postgres
  host: <%= ENV['DATABASE_URL'] %>

--------------------------------------------------------------------------------

  We’ll be using the Puma web server for this Rails application, and we need to
  set up a config file located in config/puma.rb. Please make sure that you have
  puma in your Gemfile as well!

  port ENV['PORT'] || 3000
  environment ENV['RACK_ENV'] || 'development'

  ------------------------------------------------------------------------------

  Up and running locally

  To run this app locally in the Docker container you can use the following
  command, which at this point is straight-up Docker and Docker Compose
  (rather than something specific to Heroku):

    $ docker-compose up web

      Step 1/1 : RUN echo "export PATH=\"$PATH\" GEM_PATH=\"$GEM_PATH\" GEM_HOME=\"$GEM_HOME\"  RAILS_ENV=\"\${RAILS_ENV:-$RAILS_ENV}\" SECRET_KEY_BASE=\"\${SECRET_KEY_BASE:-$SECRET_KEY_BASE}\" BUNDLE_APP_CONFIG=\"$BUNDLE_APP_CONFIG\"" > /app/.profile.d/ruby.sh
        ---> Running in 0f457fbba0cf
        ---> 0e9ec171694b
      Successfully built 0e9ec171694b
      WARNING: Image for service web was built because it did not already exist. To rebuild this image you must use `docker-compose build` or `docker-compose up --build`.
      Creating demo_herokuPostgresql_1
      Creating demo_web_1
      Attaching to demo_web_1
      web_1               | Puma starting in single mode...
      web_1               | * Version 3.7.1 (ruby 2.2.3-p173), codename: Snowy Sagebrush
      web_1               | * Min threads: 0, max threads: 16
      web_1               | * Environment: development
      web_1               | * Listening on tcp://0.0.0.0:8080
      web_1               | Use Ctrl-C to stop

  ------------------------------------------------------------------------------
    $ docker images

      REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
      demo_web            latest              0e9ec171694b        29 minutes ago      1.45 GB
      postgres            latest              e8060950e00d        About an hour ago   266 MB
      demo_app            latest              19560a5025ba        11 hours ago        861 MB
      heroku/ruby         latest              3f1738df02d5        19 months ago       1.39 GB

    Note: Pulling herokuPostgresql is image (postgres:latest)
  ------------------------------
    $ docker ps

      CONTAINER ID        IMAGE               COMMAND                  PORTS                     NAMES
      387afa7a81e3        demo_web            "/usr/bin/init.sh ..."   0.0.0.0:8080->8080/tcp    demo_web_1
      25b41db2b5a7        postgres            "docker-entrypoint..."   5432/tcp                  demo_herokuPostgresql_1

  -------------------------------------------------

  This command will open the app in the browser:
  #with the correct IP address:
  #open "http://$(docker-machine ip default):8080"
      localhost:8080

  If all worked well you should be able to see your app running within the
  Heroku/Ruby Docker container.

  my result (good, as expected):

    {"message":"Hello world!"}
--------------------------------------------------------------------------------

  Deploying to Heroku

  To deploy to Heroku we’ll first need to make sure we have created an app on
  Heroku. Take note of the name they gave to your app in the output.

    $ heroku create codeship-demo-94037
      Creating ⬢ codeship-demo-94037... done
      https://codeship-demo-94037.herokuapp.com/ | https://git.heroku.com/codeship-demo-94037.git

    $ git remote -v
      heroku  https://git.heroku.com/secret-anchorage-84269.git (fetch)
      heroku  https://git.heroku.com/secret-anchorage-84269.git (push)

  After that we can deploy it using the following command. Keep in mind that you
  should use your app name on Heroku, not mine:

    $ heroku docker:release --app warm-fortress-1700

  Once it is done deploying (which will take a few minutes the first time as it
    uploads the somewhat large image slug to Heroku), you can open it in the
    browser using the command

      $ heroku open.
