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
     Rays-MacBook-Pro:demo raynovarina$ bundle exec rake test
     Run options: --seed 37996


     # Running:



     Finished in 0.000482s, 0.0000 runs/s, 0.0000 assertions/s.

     0 runs, 0 assertions, 0 failures, 0 errors, 0 skips
     Rays-MacBook-Pro:demo raynovarina$ bundle exec rails server
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
       Parameters: {"internal"=>true}
       Rendering /Users/raynovarina/.rvm/gems/ruby-2.4.0/gems/railties-5.0.2/lib/rails/templates/rails/welcome/index.html.erb
       Rendered /Users/raynovarina/.rvm/gems/ruby-2.4.0/gems/railties-5.0.2/lib/rails/templates/rails/welcome/index.html.erb (6.9ms)
     Completed 200 OK in 27ms (Views: 13.9ms | ActiveRecord: 0.0ms)

     $ docker run -it demo bash
   root@a86774c04918:/app# pwd
   /app
   root@a86774c04918:/app# ls
   Dockerfile  Gemfile  Gemfile.lock  README.md  Rakefile  app  bin  config  config.ru  db  lib  log  public  test  tmp  vendor
   root@a86774c04918:/app# exit

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

After adding the above file as Dockerfile to your repository, we can now build the container and start running commands with it. We specify a tag via the -t option, so we can reference the container later on.
docker build -t demo .
docker run -it demo bundle exec rake test
docker run -itP demo
Here are some explanations for the commands above:
docker run runs tasks in a Docker container. This is most commonly used for one-off tasks but is also very helpful in development.
The -P option causes all ports defined in the Dockerfile to be exposed to unprivileged ports on the host and thus be accessible from the outside.
If we don’t specify a command to run on the command line, the command defined by the CMD setting will be run instead.

We now have our Rails application running inside a Docker container, but how do we actually access it from our computer? We will use docker ps, a handy tool to list running Docker processes as well as additional information about them.
$ docker ps
CONTAINER ID        IMAGE               COMMAND                CREATED             STATUS              PORTS                     NAMES
eb018d2ca6e2        demo           "bundle exec 'rails    10 seconds ago      Up 9 seconds        0.0.0.0:32769->3000/tcp   pensive_ritchie

We can see the container ID, the image it is based on, which command it is running, and the mapping of any exposed ports. With this information at hand, we can now open the app in our browser http://localhost:32769.


   $ git init

   Initialized empty Git repository in /Users/raynovarina/Sites/AtomProjects/Docker/Dockerizing-Rails/codeship/demo/.git/
   Rays-MacBook-Pro:demo raynovarina$ git remote add origin https://github.com/RayNovarina/codeship-locher-blog-rails-dev-docker.git
   Rays-MacBook-Pro:demo raynovarina$ git status
   On branch master

   $ git add .
   Rays-MacBook-Pro:demo raynovarina$ git commit -m "Tutorial works up to and including step two. Runs rails app in container."
   [master (root-commit) 8ed8b34] Tutorial works up to and including step two. Runs rails app in container.

    76 files changed, 1155 insertions(+)

    create mode 100644 tmp/.keep
   create mode 100644 vendor/assets/javascripts/.keep
   create mode 100644 vendor/assets/stylesheets/.keep
  Rays-MacBook-Pro:demo raynovarina$ git push origin master
  Counting objects: 86, done.
  Delta compression using up to 8 threads.
  Compressing objects: 100% (71/71), done.
  Writing objects: 100% (86/86), 20.74 KiB | 0 bytes/s, done.
  Total 86 (delta 2), reused 0 (delta 0)
  remote: Resolving deltas: 100% (2/2), done.
  To https://github.com/RayNovarina/codeship-locher-blog-rails-dev-docker.git
   * [new branch]      master -> master





Without any further configuration, this provides us with a Rails application, using SQLite as a database. And if we want to, we can run our tests and start the development server to take a look in our browser.

  $ bundle exec rake test
  $ bundle exec rails server

We can now access the default start page at
  localhost:3000.
It’s not a very useful app, but it’ll do for our purpose.

---------------------------------------
Step 3: Docker Volumes

Docker supports what it calls volumes. These are mount points which let you access data from either the native host or another container. In our case, we can mount our application folder into the container and don’t need to build a new image for each change.
Simply specify the local folder as well as where to mount it in the Docker container when calling docker run, and you’re good to go!

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
Adding PostgreSQL

We could now create a new Dockerfile for running PostgreSQL, but luckily we don’t need to. There is a readily available PostgreSQL Docker image available on the Docker Hub, so let’s just use that instead.
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
  ports:
    - "5432"
We defined a new container called postgres, based on the PostgreSQL 9.4 image (there are images for previous versions available as well), configured the port on the new image, and told our app container to define a link to the database.

But how do we access the database from within our Rails application? Fortunately for us, Docker Compose exposes environment variables for linked containers, so let’s take a look at those.
# build new container images first
docker-compose build
docker-compose run -it app env
This will print a bunch of environment variables, including these two:
...
POSTGRES_PORT_5432_TCP_ADDR=172.17.0.35
POSTGRES_PORT_5432_TCP_PORT=5432
...

We can now use those in our database.yml to access the database server.
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5
  timeout: 5000
  username: postgres
  # please see the update below about using hostnames to
  # access linked services via docker-compose
  host: <%= ENV['POSTGRES_PORT_5432_TCP_ADDR'] %>
  port: <%= ENV['POSTGRES_PORT_5432_TCP_PORT'] %>

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
We also need to change our Gemfile and remove the sqlite3 gem and add pg instead.
# Use PostgreSQL as the database for Active Record.
gem 'pg'

Having made those changes, let’s rebuild our containers and configure the database.
docker-compose build
docker-compose up
docker-compose run app rake db:create
docker-compose run app rake db:migrate
Update, Compose now recommends to use the hostnames instead of environment variables to access linked services. The database.yml mentioned above should now look like the following snippet, further changes are not required.

default: &default
  adapter: postgresql
  encoding: unicode
  pool: 5
  timeout: 5000
  username: postgres
  host: postgres
  port: 5432
...
