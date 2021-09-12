![DGamer Logo](dgamer-logo.png)

This project builds a Docker image that replaces the web servers for Nintendo Wifi and DGamer:

- conntest.nintendowifi.net (HTTP/80)
- nas.nintendowifi.net (HTTPS/443)
- home.disney.go.com (HTTPS/443)

This image does not include a DNS server, it is recommended to use [this DNS server](https://github.com/samuelcolvin/dnserver) with the following command:
```
docker run --rm -p 53:53/udp -v $(pwd)/zones.txt:/zones/zones.txt samuelcolvin/dnserver
```

### Docker

Build:
```
docker build --rm --tag dgamer .
```

Run (production):
```
docker run -d --name dgamer \
	-p 80:80 \
	-p 443:443 \
	-v "$(pwd)/configs/apache/:/usr/local/apache/conf/" \
	-v "$(pwd)/sites/:/var/www" \
	dgamer
```

Run (for testing):
```
docker run --name dgamer \
	--rm -it \
	-p 80:80 \
	-p 443:443 \
	-v "$(pwd)/configs/apache/:/usr/local/apache/conf/" \
	-v "$(pwd)/sites/:/var/www" \
	dgamer
```

Start:
```
docker start dgamer
```

Stop:
```
docker stop dgamer
```

