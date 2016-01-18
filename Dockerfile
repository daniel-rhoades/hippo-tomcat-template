#
# Builds a Docker image with Tomcat installed and configured ready to accept a Hippo (tested on 10.0) distribution
#
# The actual Hippo distribution (e.g. the tar.gz built from maven) is passed in during the container's start-up through
# a volume mount: $USER_HOME/distributions
#
# When running this Docker image you will need to specify the following environment variables:
#
# - Database username : HIPPO_CONTENTSTORE_USERNAME
# - Database password: HIPPO_CONTENTSTORE_PASSWORD
# - Database connection URL: HIPPO_CONTENTSTORE_URL
#
# These can be passed in as environment variables at runtime, or preferably as a shell script in the volume mount:
# $USER_HOME/environment
#

FROM williamyeh/ansible:ubuntu14.04-onbuild

RUN ansible-playbook-wrapper

EXPOSE 8080

ENV USER_HOME /opt/cms
ENV CATALINA_BASE /opt/cms/tomcat
ENV PATH $CATALINA_BASE/bin:$USER_HOME/bin:$PATH
WORKDIR $USER_HOME

VOLUME ["$USER_HOME/environment", "$USER_HOME/distributions"]

USER cms
ENTRYPOINT ["entrypoint.sh"]
CMD ["catalina.sh", "run"]