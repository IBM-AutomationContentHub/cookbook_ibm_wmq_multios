#
# Cookbook Name:: wmq
# Recipe:: service
#
# Copyright IBM Corp. 2016, 2017
#
# <> Create the MQ service and enables it on RHEL 7

# <> Create the MQ service file
template "/etc/systemd/system/#{node['wmq']['service_name']}.service" do
  source 'mq.service.erb'
  cookbook 'wmq' # specified to avoid FC033 warning: https://github.com/acrmp/foodcritic/issues/449
  owner 'root'
  group 'root'
  mode 0644
end

# <> Create the MQ service script
template "#{node['wmq']['os_users']['mqm']['home']}/mq-service.sh" do
  source 'mq-service.sh.erb'
  cookbook 'wmq' # specified to avoid FC033 warning: https://github.com/acrmp/foodcritic/issues/449
  owner 'root'
  group 'root'
  mode 0755
  variables(
    :queue_managers => node['wmq']['global_mq_service'] == 'false' ? node['wmq']['qmgr'].values.map { |qmgrs| qmgrs['name'] }.join(" ") : "*"
  )
end

# <> Enable and start the httpd service
Chef::Log.info("Running the reload-daemon command on systemd enabled linux systems")
case node['platform_family']
when 'rhel', 'debian'
  if node['platform_version'].start_with?("7.", "16.")
    execute 'daemon-reload' do
      command "/bin/systemctl daemon-reload"
      action :run
      user 'root'
      group 'root'
      only_if { File.exist?("/etc/systemd/system/#{node['wmq']['service_name']}.service") }
    end
  end
end

# <> Enable the MQ service
service node['wmq']['service_name'] do
  action [:enable]
end