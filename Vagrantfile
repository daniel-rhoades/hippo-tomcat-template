VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.define "main"

    config.vm.box = "ubuntu/trusty64"

    config.vm.network :forwarded_port, guest: 8080, host: 8080
    config.vm.network :forwarded_port, guest: 8081, host: 8081

    config.vm.provision "shell", inline: "mkdir -p /tmp/hippo-distributions/cms"
    config.vm.provision "shell", inline: "sudo chown vagrant.vagrant /tmp/hippo-distributions/cms"
    config.vm.provision "shell", inline: "wget -nc https://github.com/daniel-rhoades/hippo-gogreen/releases/download/v0.1/gogreen-0.1.0-SNAPSHOT-cms-distribution.tar.gz -q -O /tmp/hippo-distributions/cms/gogreen-0.1.0-SNAPSHOT-cms-distribution.tar.gz"

    config.vm.provision "shell", inline: "mkdir -p /tmp/hippo-distributions/site"
    config.vm.provision "shell", inline: "sudo chown vagrant.vagrant /tmp/hippo-distributions/site"
    config.vm.provision "shell", inline: "wget -nc https://github.com/daniel-rhoades/hippo-gogreen/releases/download/v0.1/gogreen-0.1.0-SNAPSHOT-site-distribution.tar.gz -q -O /tmp/hippo-distributions/site/gogreen-0.1.0-SNAPSHOT-site-distribution.tar.gz"

    config.vm.provider "virtualbox" do |v|
        v.memory = 4096
        v.cpus = 2
    end

    config.vm.provision "docker" do |d|
        d.run "gogreen-mysql", image: "mysql:latest", args: "--volume /vagrant/tests/database-init-scripts:/docker-entrypoint-initdb.d:ro -e MYSQL_ROOT_PASSWORD=password -d"
    end

    config.vm.provision "docker" do |d|
        d.build_image "/vagrant/", args: "-t danielrhoades/hippo-tomcat-template"
        d.run "gogreen-hippo-cms", image: "danielrhoades/hippo-tomcat-template", args: "-p 8080:8080 --volume /tmp/hippo-distributions/cms:/opt/cms/distributions:ro --link gogreen-mysql:mysql -e HIPPO_CONTENTSTORE_USERNAME=\"gogreen\" -e HIPPO_CONTENTSTORE_PASSWORD=\"password\" -e HIPPO_CONTENTSTORE_URL=\"jdbc:mysql://\\$MYSQL_PORT_3306_TCP_ADDR:\\$MYSQL_PORT_3306_TCP_PORT/gogreen?characterEncoding=utf8\""
    end

    # Prevents race condition for cms/site components populating the initial content store
    config.vm.provision "shell", inline: "sleep 60"

    config.vm.provision "docker" do |d|
        d.run "gogreen-hippo-site", image: "danielrhoades/hippo-tomcat-template", args: "-p 8081:8080 --volume /tmp/hippo-distributions/site:/opt/cms/distributions:ro --link gogreen-mysql:mysql -e HIPPO_CONTENTSTORE_USERNAME=\"gogreen\" -e HIPPO_CONTENTSTORE_PASSWORD=\"password\" -e HIPPO_CONTENTSTORE_URL=\"jdbc:mysql://\\$MYSQL_PORT_3306_TCP_ADDR:\\$MYSQL_PORT_3306_TCP_PORT/gogreen?characterEncoding=utf8\""
    end
end