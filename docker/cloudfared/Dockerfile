# Debian slim
FROM debian:stable-slim

# Get the architecture
RUN dpkg --print-architecture

# Install Cloudflared
RUN apt-get update && apt-get install -y wget procps dnsutils net-tools && apt-get clean
RUN wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
RUN mv -f ./cloudflared-linux-amd64 /usr/local/bin/cloudflared
RUN chmod +x /usr/local/bin/cloudflared

## ADD cloudfared user
RUN useradd -m cloudflared

# change permissions
RUN chown cloudflared:cloudflared /usr/local/bin/cloudflared

# change user
USER cloudflared

# Expose port 5053 udp
EXPOSE 5053/udp

# Run Cloudflared
CMD ["/usr/local/bin/cloudflared", "proxy-dns", "--address","0.0.0.0", "--port", "5053", "--upstream", "https://1.1.1.1/dns-query", "--upstream", "https://1.0.0.1/dns-query"]
