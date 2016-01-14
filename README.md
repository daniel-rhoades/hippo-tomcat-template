# Docker - Hippo on Tomcat Template

Configurable [Docker](http://docker.io) image to run a Hippo CMS distribution.  The Docker image is just the result of applying a number configurations as part of an Ansible playbook.

The image should comply (mostly) with the [recommended setup](http://www.onehippo.org/library/enterprise/installation-and-configuration/linux-installation-manual.html) outlined in Hippo's documentation.

You can also find a pre-built version of this image on Docker Hub under [danielrhoades/hippo-tomcat-template](https://hub.docker.com/r/danielrhoades/hippo-tomcat-template/), where it can simply be obtained by running `$ docker pull danielrhoades/hippo-tomcat-template`

The Hippo distribution along with environment specific configuration (e.g. database connection details) are passed to the container during start-up, see the quick start guide below for more information.

## Prerequisites

* Hippo is a Java-based CMS, Hippo project are built using Maven.  So if you need to build a Hippo project make sure you have an environment setup with Java and Maven, check out Hippo's documentation on [getting started](http://www.onehippo.org/trails/getting-started/prerequisites.html) for more information;
* Setup Docker on your target machine (could easily be your localhost), the Docker website has an [installation guide](https://docs.docker.com/engine/installation/).

## Quick start

1. Build a Hippo project;
2. Setup a Hippo Content Repository;
3. Create a environment properties file to store the Content Repository database connection information;
4. Start a Docker container using the `danielrhoades/hippo-tomcat-template` image with appropriate parameters.

### Build a Hippo project

The Hippo documentation has a [tutorial](http://www.onehippo.org/trails/demo-tutorials-and-download.html) if you don't yet have your own project.

If you can't be bothered or just want a quick demo, then [download](http://onehippo.com/en/go_green) Hippo's demo project:

* Extract it;
* Build it (mvn clean verify);
* Package it (mvn -Pdist).

Then in the target folder you'll have a file like `gogreen-0.1.0-SNAPSHOT-distribution.tar.gz` which is the Hippo distribution;

### Setup a Hippo Content Repository

Check out Hippo documentation to find out more about the [architecture](http://www.onehippo.org/library/architecture/hippo-cms-architecture.html).

Again, if you can't be bothered or just want a quick demo, then install a MySQL Docker image.  See the [offical MySQL Docker Hub reference](https://hub.docker.com/_/mysql/), it takes only a couple of minutes to get a MySQL instance up and running.  Although, all you need to do is create a database, for example:
                                                                                               
```
$ docker pull mysql
$ docker run --name gogreen-mysql -e MYSQL_ROOT_PASSWORD=<my-secret-pw> -d mysql:latest
$ docker exec -it gogreen-mysql bash
```

Obviously, just replace the placeholder `<my-secret-pw>` with a password of your choice.

That will have a MySQL instance running in the background and have given you a bash shell to access it, you can then run:

```
$ mysql -p
...
mysql> create database gogreen;
...
mysql> grant all on gogreen.* to 'gogreen'@'%' identified by '<my-other-secret-pw>';
...
mysql> flush privileges;
...
```

Obviously, just replace the placeholder `<my-other-secret-pw>` with a password of your choice.

### Create an environment setup script

When running the hippo-tomcat-template Docker image you will need to specify the database connection properties.  These can be given either as environment properties passed to the container or specified in an environments script.

If you are using another Docker container to run your database (like the previous MySQL example) then it gets a bit easier, because if you link the containers (see next section) then Docker will inject the database IP address and port into the Hippo container for you using the variables:

* MYSQL_PORT_3306_TCP_ADDR
* MYSQL_PORT_3306_TCP_PORT

Environment properties:

* Database username : `HIPPO_CONTENTSTORE_USERNAME="gogreen"`
* Database password: `HIPPO_CONTENTSTORE_PASSWORD="<my-other-secret-pw>"`
* Database connection URL: `HIPPO_CONTENTSTORE_URL="jdbc:mysql://\$MYSQL_PORT_3306_TCP_ADDR:\$MYSQL_PORT_3306_TCP_PORT/gogreen?characterEncoding=utf8"`

Notice we had to escape the `$` on the `MYSQL_PORT_3306_TCP_` variables, this is because we want the variable to be resolved inside the container, not the host.

Alternatively, here is an environments script example, 'my-database-properties.sh', the name of script isn't important but it must be executable (e.g. `$ chmod +x my-database-properties.sh`)

```
echo export HIPPO_CONTENTSTORE_USERNAME="gogreen"
echo export HIPPO_CONTENTSTORE_PASSWORD="<my-other-secret-pw>"
echo export HIPPO_CONTENTSTORE_URL="jdbc:mysql://$MYSQL_PORT_3306_TCP_ADDR:$MYSQL_PORT_3306_TCP_PORT/gogreen?characterEncoding=utf8"
```

If you followed the previous MySQL setup, then `HIPPO_CONTENTSTORE_USERNAME` and `HIPPO_CONTENTSTORE_PASSWORD` should match those you specified during the MySQL `grant` operation.  Again, the URL assumes your Content Store is in a local MySQL Docker container.

### Start the hippo-tomcat-template container

Before running the run command below, copy your Hippo distribution in a directory (e.g. `/tmp/hippo-distributions`) and your environment configuration (if using) to a different directory (e.g. `/tmp/hippo-environment`)

```
$ docker run \
    --publish 8080:8080 \
    --volume /tmp/hippo-distributions:/opt/cms/distributions \
    --volume /tmp/hippo-environment:/opt/cms/environment \
    --link gogreen-mysql:mysql \
    danielrhoades/hippo-tomcat-template
```

All `tar.gz` archives found in the `/opt/cms/distributions` mount will be extracted into Tomcat base (CATALINA_BASE) within `webapps` and `shared` directories, e.g. it will run `$ tar zxf <distribution>.tar.gz webapps shared`.

Any environment scripts will be sourced (through `$ eval "(<script>)"`) when `conf/setenv.sh` runs during Tomcat startup.  Alternatively, if you just want to specify environment variables instead of an environment script then run:

```
$ docker run \
    --publish 8080:8080 \
    --volume /tmp/hippo-distributions:/opt/cms/distributions \
    --volume /tmp/hippo-environment:/opt/cms/environment \
    -e HIPPO_CONTENTSTORE_USERNAME="gogreen" \
    -e HIPPO_CONTENTSTORE_PASSWORD="<my-other-secret-pw>" \
    -e HIPPO_CONTENTSTORE_URL="jdbc:mysql://$MYSQL_PORT_3306_TCP_ADDR:$MYSQL_PORT_3306_TCP_PORT/gogreen?characterEncoding=utf8" \
    --link gogreen-mysql:mysql \
    danielrhoades/hippo-tomcat-template
```

You can also pass the environment variables in via `$ docker run --env-file`.

That's it, you can now just browse to the site through your Docker machine's IP, e.g. `http://<my-docker-machine-ip>:8080/cms` for the CMS or `http://<my-docker-machine-ip>:8080/site` for the HST component.  The default username/password for Hippo is admin/admin.

## Troubleshooting

If you run into any issues accessing the site, ensure the Hippo repository has been configured with the virtual host name of your Docker machine, see Hippo's guide to [Configuring Virtual Hosts in an Environment](http://www.onehippo.org/library/enterprise/installation-and-configuration/configure-virtual-hosts-in-an-environment.html)

## Structure of this project

If you are interested in the details.  This project is made up of the following key components:
 
* Dockerfile which starts the build of the Docker image
* Ansible playbook which configures the image to do the things it needs

Although the Ansible playbook in the project is used to configure a Docker image, it knows nothing about Docker itself and could easily be reused to configure any system.

The Ansible playbook (ansible/hippo-tomcat.yml) will configure a machine with:

* Oracle JDK 1.8.x (using the [williamyeh.oracle-java](https://github.com/William-Yeh/ansible-oracle-java) role)
* Tomcat 8.0.x (using the [daniel-rhoades/tomcat-role](https://github.com/daniel-rhoades/tomcat-role) role)
* Configure Tomcat for use with the [Hippo CMS](http://onehippo.org) (using the daniel-rhoades/hippo-tomcat role)

A Dockerfile is used to execute the playbook, by doing this the end result is a Docker image configured as above.
 
To build your own Docker image, check-out this project from GitHub, install Docker, "cd" into the directory and run the following command:

* `$ docker build -t danielrhoades/hippo-tomcat-template .`

## Separate out CMS and HST

By default the Hippo distribution combines both the CMS (Content Authoring) and the HST (Content Delivery) component in the same distribution.  Best practice is to separate out the two components for reasons of security and scalability.

A Hippo maven project can easily be modified to add an additional build profile to achieve this separation, follow the [Separate HST Deployment Model guide](http://www.onehippo.org/library/enterprise/installation-and-configuration/separate-hst-deployment-model.html) to modify your own project.

When it comes to running the `danielrhoades/hippo-tomcat-template` Docker image, the process is exactly the same, you just copy the required distribution to the particular Docker container you need by placing it in the mount (e.g. `--volume /tmp/hippo-distributions:/opt/cms/distributions`).  If you are running them on the same host, just remember to start the Docker containers on different ports, for example:

```
$ cp gogreen-0.1.0-SNAPSHOT-distribution-cms.tar.gz /tmp/hippo-distributions/cms
$ docker run \
    --publish 8080:8080 \
    --volume /tmp/hippo-distributions/cms:/opt/cms/distributions \
    --volume /tmp/hippo-environment:/opt/cms/environment \
    --link gogreen-mysql:mysql \
    danielrhoades/hippo-tomcat-template
    
$ cp gogreen-0.1.0-SNAPSHOT-distribution-site.tar.gz /tmp/hippo-distributions/site
$ docker run \
    --publish 8080:8080 \
    --volume /tmp/hippo-distributions/site:/opt/cms/distributions \
    --volume /tmp/hippo-environment:/opt/cms/environment \
    --link gogreen-mysql:mysql \
    danielrhoades/hippo-tomcat-template
```

In both example cases they use the same environments file and link to the same MySQL Docker container.