Ruby on Rails Docker Image
==============================

 This image is for developing with [Ruby on Rails ](http://rubyonrails.org/) application

REQUIREMENTS
--------------------
- `docker`
- `docker-compose`
- [docker-sync](http://docker-sync.io/)


USAGE
--------------------

### Production

Use for basic.

```
$ docker-compose up
```

And access to `http://${DockerHost-IP}`

### Development

Developing Ruby on Rails application.

```
$ docker-sync-stack start
```

And add directory of `./rails5_app/` to IDE project

* Install dependent tools (macOS)
```
$ sudo gem install docker-sync
$ brew install fswatch
$ brew install unison
```
