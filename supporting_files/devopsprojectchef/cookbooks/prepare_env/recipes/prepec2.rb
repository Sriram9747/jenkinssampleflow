#
# Cookbook:: prepare_env
# Recipe:: prepec2
#
# Copyright:: 2019, The Authors, All Rights Reserved.

# include_recipe "nodejs::nodejs_from_package"
# include_recipe "nodejs::npm"

apt_update 'update apt' do
    frequency 86400
    action :periodic
end

docker_service 'default' do
    action [:create, :start]
end

execute 'enable docker permission' do
    command 'chmod 777 /var/run/docker.sock'
    # elevated true
end

docker_image 'awsacdev/ubuntu_tomcat' do
    tag '1.0'
    action :pull
end

docker_container 'tomcatweb' do
    repo 'awsacdev/ubuntu_tomcat'
    tag '1.0'
    port '80:8094'
    # volumes ['/path/:/pathincontainer']
    action :run
end



directory '/warfile' do
    action :create
end

# cookbook_file '/warfile/Devops_maven_1-1.0.0.war' do
#     source 'Devops_maven_1-1.0.0.war'
# end

remote_directory '/warfile' do
    source 'warfile'
end

execute 'copy war file to docker' do
    command 'docker container cp /warfile/. tomcatweb:/servers/tomcat8/webapps'
end