# Cloudfared DNS proxy docker

This is a docker image that runs cloudfared as dns-proxy. This ise useful to tunel DNS trafic through HTTPS using PiHole:

`https://docs.pi-hole.net/guides/dns/cloudflared/`

## Usage
The image is available in docker hub 'merlos/cloudfared' 

Run the container:
```sh
docker run  -p 5053:5053/udp --name cloudfared merlos/cloudfared 
```

Test the proxy:

```sh
dig @127.0.0.1 -p 5053 google.com
```

Which should return an answer similar to:

```
; <<>> DiG 9.10.6 <<>> @localhost -p 5053 google.com
; (2 servers found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 3217
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;google.com.			IN	A

;; ANSWER SECTION:
google.com.		131	IN	A	142.250.185.14

;; Query time: 389 msec
;; SERVER: ::1#5053(::1)
;; WHEN: Sun Nov 24 18:27:44 EAT 2024
;; MSG SIZE  rcvd: 65
```

Then in pi-hole

## Development 
### Build the image

The script builds an image called `cloudfared` for the architecture `amd64`, it also pushes to the dockerhub repo.

Edit the `REPO` variable in the script to use your own repo

```
./build.sh
```

### Other commands
Run the terminal
```
docker exec -ti cloudfared bash
```

