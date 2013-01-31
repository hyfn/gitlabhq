class Settings < Settingslogic
  source "#{Rails.root}/config/gitlab.yml"

  class << self
    def gitlab_on_non_standard_port?
      ![443, 80].include?(gitlab.port.to_i)
    end

    private

    def build_gitolite_ssh_path_prefix
      if gitolite.ssh_port != 22
        "ssh://#{gitolite.ssh_user}@#{gitolite.ssh_host}:#{gitolite.ssh_port}/"
      else
        "#{gitolite.ssh_user}@#{gitolite.ssh_host}:"
      end
    end

    def build_gitlab_url
      if gitlab_on_non_standard_port?
        custom_port = ":#{gitlab.port}"
      else
        custom_port = nil
      end
      [ gitlab.protocol,
        "://",
        gitlab.host,
        custom_port,
        gitlab.relative_url_root
      ].join('')
    end
    
    def ssh_port
      git_host['port'] || 22
    end

    def ssh_user
      git_host['git_user'] || 'git'
    end

    def ssh_host
      git_host['host'] || web_host || 'localhost'
    end

    def ssh_path
      if ssh_port != 22
        "ssh://#{ssh_user}@#{ssh_host}:#{ssh_port}/"
      else
        "#{ssh_user}@#{ssh_host}:"
      end
    end

    def git_base_path
      git_host['base_path'] || '/home/git/repositories/'
    end

    def git_hooks_path
      git_host['hooks_path'] || '/home/git/share/gitolite/hooks/'
    end

    def git_upload_pack
      if git_host['upload_pack'] != false
        true
      else
        false
      end
    end

    def git_receive_pack
      if git_host['receive_pack'] != false
        true
      else
        false
      end
    end

    def git_bin_path
      git['path'] || '/usr/bin/git'
    end

    def git_max_size
      git['git_max_size'] || 5242880 # 5.megabytes
    end

    def git_timeout
      git['git_timeout'] || 10
    end

    def gitolite_admin_uri
      git_host['admin_uri'] || 'git@localhost:gitolite-admin'
    end

    def gitolite_admin_key
      git_host['gitolite_admin_key'] || 'gitlab'
    end

    def default_projects_limit
      app['default_projects_limit'] || 10
    end

    def backup_path
      t = app['backup_path'] || "backups/"
      t = /^\//.match(t) ? t : Rails.root .join(t)
      t
    end

    def backup_keep_time
      app['backup_keep_time'] || 0
    end

    def ldap_enabled?
      ldap && ldap['enabled']
    rescue Settingslogic::MissingSetting
      false
    end

    def omniauth_enabled?
      omniauth && omniauth['enabled']
    rescue Settingslogic::MissingSetting
      false
    end

    def omniauth_providers
      (omniauth_enabled? && omniauth['providers']) || []
    end
    
    def google_apps_enabled?
      google_apps && google_apps['enabled']
    rescue Settingslogic::MissingSetting
      false
    end

    def disable_gravatar?
      app['disable_gravatar'] || false
    end
  end
end


# Default settings
Settings['ldap'] ||= Settingslogic.new({})
Settings.ldap['enabled'] = false if Settings.ldap['enabled'].nil?

Settings['omniauth'] ||= Settingslogic.new({})
Settings.omniauth['enabled']      = false if Settings.omniauth['enabled'].nil?
Settings.omniauth['providers']  ||= []

Settings['gitlab'] ||= Settingslogic.new({})
Settings.gitlab['default_projects_limit'] ||=  10
Settings.gitlab['host']       ||= 'localhost'
Settings.gitlab['https']        = false if Settings.gitlab['https'].nil?
Settings.gitlab['port']       ||= Settings.gitlab.https ? 443 : 80
Settings.gitlab['relative_url_root'] ||= ''
Settings.gitlab['protocol']   ||= Settings.gitlab.https ? "https" : "http"
Settings.gitlab['email_from'] ||= "gitlab@#{Settings.gitlab.host}"
Settings.gitlab['support_email']  ||= Settings.gitlab.email_from
Settings.gitlab['url']        ||= Settings.send(:build_gitlab_url)
Settings.gitlab['user']       ||= 'gitlab'
Settings.gitlab['signup_enabled'] ||= false

Settings['gravatar'] ||= Settingslogic.new({})
Settings.gravatar['enabled']      = true if Settings.gravatar['enabled'].nil?
Settings.gravatar['plain_url']  ||= 'http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'
Settings.gravatar['ssl_url']    ||= 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=mm'

Settings['gitolite'] ||= Settingslogic.new({})
Settings.gitolite['admin_key']    ||= 'gitlab'
Settings.gitolite['admin_uri']    ||= 'git@localhost:gitolite-admin'
Settings.gitolite['config_file']  ||= 'gitolite.conf'
Settings.gitolite['hooks_path']   ||= '/home/git/share/gitolite/hooks/'
Settings.gitolite['receive_pack']   = true if Settings.gitolite['receive_pack'].nil?
Settings.gitolite['upload_pack']    = true if Settings.gitolite['upload_pack'].nil?
Settings.gitolite['repos_path']   ||= '/home/git/repositories/'
Settings.gitolite['ssh_host']     ||= (Settings.gitlab.host || 'localhost')
Settings.gitolite['ssh_port']     ||= 22
Settings.gitolite['ssh_user']     ||= 'git'
Settings.gitolite['owner_group']  ||= Settings.gitolite.ssh_user
Settings.gitolite['ssh_path_prefix'] ||= Settings.send(:build_gitolite_ssh_path_prefix)

Settings['backup'] ||= Settingslogic.new({})
Settings.backup['keep_time']  ||= 0
Settings.backup['path']         = File.expand_path(Settings.backup['path'] || "tmp/backups/", Rails.root)

Settings['git'] ||= Settingslogic.new({})
Settings.git['max_size']  ||= 5242880 # 5.megabytes
Settings.git['bin_path']  ||= '/usr/bin/git'
Settings.git['timeout']   ||= 10

Settings['satellites'] ||= Settingslogic.new({})
Settings.satellites['path'] = File.expand_path(Settings.satellites['path'] || "tmp/repo_satellites/", Rails.root)
