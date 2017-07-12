FROM centos:7 AS build-env

LABEL  maintainer "katsumi kato <katzumi+github@gmail.com>"

RUN	true && \
# DNS add.
	echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
	yum update -y && \
	true

ENV	RBENV_ROOT /usr/local/rbenv

COPY	rbenv.sh /etc/profile.d/

ARG RUBY_VERSION
ENV RUBY_VERSION ${RUBY_VERSION:-2.4.1}

RUN	true && \
# build tools install
	yum install -y git gcc make bzip2 tar gcc-c++ openssl-devel readline-devel zlib-devel mysql-devel sqlite-devel && \
	true

RUN	true && \
# rbenv install
	git clone git://github.com/rbenv/rbenv.git ${RBENV_ROOT} && \
	cd ${RBENV_ROOT} && src/configure && make -C src && \
	mkdir -p ${RBENV_ROOT}/plugins && \
	git clone https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build && \
	cd ${RBENV_ROOT}/plugins/ruby-build && \
	./install.sh && \
	source /etc/profile.d/rbenv.sh && \
# ruby install
	rbenv install -l && \
	rbenv install ${RUBY_VERSION} && \
	rbenv rehash && \
	rbenv global ${RUBY_VERSION} && \
# gem update
	echo "gem: --no-document" > ~/.gemrc && \
	rbenv exec gem update --system && \
	true

ARG RAILS_VERSION
ENV RAILS_VERSION ${RAILS_VERSION:-5.1.2}

RUN	true && \
	source /etc/profile.d/rbenv.sh && \
# rails install
# RoR version check '>= 5.1'
#	yum install -y bc && \
#	echo "scale=1; ${RAILS_VERSION} >= 5.1" | bc && \
	rbenv exec gem install rails -v ${RAILS_VERSION} && \
# Bundler install
	rbenv exec gem install bundler && \
	rbenv exec gem install therubyracer && \
	rbenv exec gem install mysql2 && \
	rbenv rehash && \
	true

ENV	NDENV_ROOT /usr/local/ndenv

ARG NODE_VERSION
ENV NODE_VERSION ${NODE_VERSION:-v8.1.4}

COPY	ndenv.sh /etc/profile.d/

RUN	true && \
# nbenv install
	git clone https://github.com/riywo/ndenv.git ${NDENV_ROOT} && \
	mkdir -p ${NDENV_ROOT}/plugins && \
	git clone https://github.com/riywo/node-build.git ${NDENV_ROOT}/plugins/node-build && \
	source /etc/profile.d/ndenv.sh && \
# node.js install
	ndenv install -l && \
	ndenv install ${NODE_VERSION} && \
	ndenv rehash && \
	ndenv global ${NODE_VERSION} && \
	node --version && \
	true

RUN	true && \
	source /etc/profile.d/ndenv.sh && \
# yarn install
	npm install -g yarn && \
	export PATH=$PATH:`npm bin -g` && \
	yarn -version && \
	true

ENV	APP_ROOT /web/rails5_app

ARG GIT_REPOS

RUN	true && \
	source /etc/profile.d/rbenv.sh && \
	source /etc/profile.d/ndenv.sh && \
	mkdir -p ${APP_ROOT} && \
	cd ${APP_ROOT} && \
# git clone
	git clone ${GIT_REPOS} . && \
        sed -i "s/^# gem 'therubyracer'/gem 'therubyracer'/g" Gemfile && \
        sed -i "s/^gem 'sqlite3'/gem 'mysql2', '>= 0.3.18', '< 0.5'/g" Gemfile && \
        sed -i "s/^gem 'pg'/gem 'mysql2', '>= 0.3.18', '< 0.5'/g" Gemfile && \
	bundle update && \
	bundle install && \
	yarn install && \
# nginx connecting sockets
	echo "app_root = File.expand_path(\"../..\", __FILE__)" >> config/puma.rb && \
	echo "bind \"unix://#{app_root}/tmp/sockets/puma.sock\"" >> config/puma.rb && \
	true

FROM centos:7 AS rails_app

LABEL  maintainer "katsumi kato <katzumi+github@gmail.com>"

ENV	RBENV_ROOT /usr/local/rbenv
ENV	NDENV_ROOT /usr/local/ndenv
ENV	APP_ROOT /web/rails5_app
ENV	TZ Asia/Tokyo

COPY --from=build-env $RBENV_ROOT $RBENV_ROOT
COPY --from=build-env $NDENV_ROOT $NDENV_ROOT
COPY --from=build-env $APP_ROOT $APP_ROOT

COPY	rbenv.sh /etc/profile.d/
COPY	ndenv.sh /etc/profile.d/
COPY	config/database.yml $APP_ROOT/config/database.yml

RUN     true && \
# DNS add.
	echo "nameserver 8.8.8.8" > /etc/resolv.conf && \
        source /etc/profile.d/rbenv.sh && \
	source /etc/profile.d/ndenv.sh && \
	cd ${APP_ROOT} && \
# shared library install
	yum -y install mysql && \
	if grep 'sqlite3' Gemfile.lock > /dev/null ; then  yum -y install sqlite; fi && \
# current version copy
	mkdir -p ${APP_ROOT}/../current && \
	cp -R ${APP_ROOT}/* ${APP_ROOT}/../current/. && \
# clean
	yum clean all && \
        true

# Expose volumes to nginx
VOLUME [ "$APP_ROOT", "$APP_ROOT/public", "$APP_ROOT/tmp/sockets" ]

COPY	entrypoint.sh /

ENTRYPOINT	[ "/entrypoint.sh" ]

EXPOSE	3000
