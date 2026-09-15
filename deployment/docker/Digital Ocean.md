# Setup instructions for Digital Ocean

1. Create the ubuntu droplet of you choice

2. open the droplet console, or ssh to it

3. add git credentials

4. Run the following commands: 

```
     sudo apt update
      sudo apt install apt-transport-https ca-certificates curl software-properties-common
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      sudo apt update
      apt-cache policy docker-ce
      sudo apt install docker-ce
     sudo systemctl status docker
     git clone git@github.com:freyja-love-and-magic/allyabase.git
     cd allyabase/deployment/docker
     ./build_and_run.sh
     apt install nginx
     vi /etc/nginx/sites-available/default // copy placeholder nginx file here 
    sudo apt install certbot python3-certbot-nginx
    sudo certbot --nginx -d livetest.continuebee.allyabase.com -d livetest.julia.allyabase.com -d livetest.pref.allyabase.com -d livetest.bdo.allyabase.com -d livetest.joan.allyabase.com -d livetest.addie.allyabase.com -d livetest.fount.allyabase.com
```
