# Note: I removed the original version of the caddy setup, in favor of what used to be caddy2. The original Caddy is still in caddy-orig.

This is a collection of docker-compose files for my home lab. There will be a video added for each service over time. I will be using Hostinger for all hosting. Visit [Hostinger](https://hostinger.com/mattw) for more information. If you sign up for anything there, use coupon code `mattw` for 10% off.

## Services

- n8n
- searxng
- perplexica
- firecrawl
- karakeep
- openwebui
- qdrant
- budibase
- postgres
- caddy
- watchtower

## Goals

I want to have a home lab that is self-hosted and runs on docker. I want to be able to access all of the services from the internet. But I don't want to let anyone access them...just me. n8n will be publicly accessible, but require authentication. The main thing that allows for this is Tailscale, which has a free plan that will let us do all we need.

## Video

This first section is covered in a video on my channel, sponsored by [Hostinger](https://hostinger.com/mattw). 

[![Zero to MCP](http://img.youtube.com/vi/OmWJPJ1CR7M/0.jpg)](http://www.youtube.com/watch?v=OmWJPJ1CR7M "Zero to MCP")

## Hostinger

If you want to follow along with everything I am doing, you can sign up for a Hostinger account at [Hostinger](https://hostinger.com/mattw) and use the coupon code `mattw` for 10% off. Select the KVM2 plan. You can choose any template you like, but I am going to start with just the Docker install. Once it is setup, either use the web terminal interface or ssh into the root user. You should see a `ssh root@ipaddress` command. Copy that and run it on your local machine. Enter the password you specified when you created the account. 

Run `git clone https://github.com/technovangelist/homelab.git` to clone this repo. cd into the homelab directory and run `./prep.sh` to prepare the system. Optionally review prep.sh first to see what it does.

After running the script, you will need to log out. Before logging back in, let's edit your ssh config file to make it easier to connect. Think of the name you would like to use to connect. I use hstgr throughout the videos, so I will use that. If you don't have a config file, create one at `~/.ssh/config`. You want at least this entry:

```
Host hstgr
    HostName ipaddress
    User theusernameyoucreated
    IdentityFile ~/.ssh/thekeyyoucreatedintheinstall
```

Save that. Then you can run `ssh hstgr` to connect to your server. 

SSH into the server as the user root and we need to do a few things.

The first step is to clone this repo to your home directory: `git clone https://github.com/technovangelist/homelab.git`.

Next, we need to prepare the system for our user. Run the `prep.sh` script: `./prep.sh`. This does a lot to prep the server, like secure SSH and more. You can see the details in the video or read the script. 

## Tailscale

Then you need to get a Tailscale account and add you home machine to your tailnet. You can do this by downloading the Tailscale app from the [Tailscale website](https://tailscale.com/).

After its installed, you need a key to add your docker containers to the tailnet. I found the easiest way to do it is to add the key to a docker secret.

1.  Create a folder called `~/.config` on the home directory for the user you are logged in as. 
2.  Create a file called `tsauthkey` in the `~/.config` folder.
3.  Go to the tailscale admin page, click on Settings. On the left go to Keys. Click the button `Generate auth key...`.
4.  Enable `Reusable`. Click `Generate key`.
5.  Add the key to the `tsauthkey` file.
6.  Make the file only readable by the user: `chmod 600 ~/.config/tsauthkey`

## DNS

You will need to add a CNAME record to your DNS for the domain you want to use. I am using Cloudflare, but you can use any DNS provider. The record should point to your server's public IP address.




## n8n

1. Navigate into the n8n directory: `cd homelab/n8n`
2. Copy the example.env file to .env: `cp example.env .env`
3. Edit the .env file.

   a. `N8N_HOST` should be the hostname of your server.
   b.  `WEBHOOK_URL` should be the URL of your server. In my case they are the same.
   c. `GENERIC_TIMEZONE` should be your timezone.

4.  Start the n8n container: `docker compose up -d`

## Caddy

When I setup Caddy in the first video, I used a simpler method. You may want to review this then skip on to caddy2 later on. 

Edit the caddyfile/Caddyfile and replace n.mydomain.com with your chosen domain name. 

Then start up the server with `docker compose up -d`

## Watchtower

This will update all the containers to the latest version every day at 4am

1. Navigate into the watchtower directory: `cd homelab/watchtower`
2. Edit the .env file and change the `TZ` to where ever you are. 
3. Start the watchtower container: `docker compose up -d`

