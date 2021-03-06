{ config, pkgs, lib, ... }:

{

    swapDevices = [ { device = "/var/swapfile"; size = 8192; } ];
    
    systemd.services.sysstat = import /root/nixos_rep/pkgs/sysstat.nix pkgs;
    
    
    systemd.timers.vvv = {
    wantedBy = [ "timers.target"];
    
    description = "my timer";
      timerConfig = {
        OnCalendar="*-*-* *:*:00";      
      };
    };
    
  networking.firewall.allowedTCPPorts = [ 80 3000 4000 2000 22 25 8080 5432 ];
        
  services = {
  
  opensmtpd = { 
    enable = true;
    serverConfiguration = 
    ''
    listen on eth0
    
    table secrets db:/root/mail/secrets.db
    accept for any relay via tls+auth://metricswarning@smtp.googlemail.com:587 auth <secrets>
        
    #listen on eth0
    #accept from local for any relay via smtp://localhost
    #accept for any relay via smtp://localhost
    
    #accept from local for any relay via smtp://127.0.0.1:25
    #accept from 34.252.218.127 for any relay    
    '';
  };
  
  postgresql = {
    enable = true;
    port = 5432;
    enableTCPIP = true;
    dataDir = "/var/db/postgresql";
    authentication = ''
    host all all 34.252.230.228/32 md5
    host all all 46.216.216.118/32 md5
    local all all trust
    '';
    extraConfig = ''
    statement_timeout = 555000
    '';
  };
  
      nginx = {
      enable = true;
      httpConfig =
      ''
       server {
        root /www/;
        listen 80 default;
        access_log /var/log/access.log;
        error_log /var/log/error.log;
        }
      '';
      };
  
  
   
   #database.host = "127.0.0.1:5432";
   #database.name = "grafana";
   #database.password = "Post-1";
   #database.user = "grafana";
   #database.type = "postgresql";
   #database.path = "/var/lib/grafana/data/grafana.db";
   
   
   grafana = {
  enable = true;
   addr = "0.0.0.0";
   port = 3000;
   security = {
     adminUser = "admin";
     adminPassword = "admin";
     };
    };   
    
      graphite = {
      web.enable = true;
      carbon = {
        enableCache = true;
        };
        };
        
       
 
  collectd.enable = true;
  collectd.extraConfig =
      ''
      LoadPlugin memory
      LoadPlugin uptime
      LoadPlugin users
      LoadPlugin cpu
      LoadPlugin vmem
      <Plugin vmem>
      Verbose false
      </Plugin>      
      LoadPlugin write_graphite
      <Plugin write_graphite>
      <Node "Graphite">
      Host "127.0.0.1"
      Port "2003"
      Protocol "tcp"
      LogSendErrors true
      Prefix "collectd."
      Postfix "collectd."
      StoreRates true
      AlwaysAppendDS true
      EscapeCharacter "-"
      </Node>
      </Plugin>      
      '';
  
        logrotate = {
        enable = true;
        config = ''
        /var/log/restart-backends.log {
            missingok
            daily
            rotate 10
            compress
        }  
        '';
        };

  cron = {
         enable = true;
         systemCronJobs = [
           "*/10 * * * * root /root/shut.sh"
           ];
      }; 
 };

  environment.systemPackages = with pkgs; [ telnet git s3cmd mc vim htop logrotate python wget ];
}
