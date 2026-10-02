# Per-state bases: DNS and TLS runbook

BizBuz pins each install to a base named after the state on the user's first
card — `ca.8as.world`, `ny.8as.world`, and so on, fifty of them, plus
`prod.8as.world` as the fallback for no state / an invalid state / DC and the
territories. See `bizbuz/app/src-tauri/src/lib.rs`, the "Which base this
install talks to" block.

This is how to make those hostnames resolve and serve HTTPS. Nothing here is
done yet — as of 2026-09-16 every one of them is NXDOMAIN and the only cert is
single-SAN `dev.8as.world`.

## The finding that shapes all of this

**Squarespace has no DNS API.** Their developer portal documents Commerce
(Orders, Products, Inventory, Transactions) and Webhooks. A "Reseller API" for
provisioning sites and domains is listed as *Coming soon* and covers
provisioning, not DNS records. There is no endpoint that creates an A record.
The only supported path is the dashboard, one record at a time.

`8as.world` is currently on `nsc1`–`nsc4.squarespacedns.com`.

So there are two ways out, and they are not equivalent.

## Option A — one wildcard record, stay on Squarespace

Squarespace supports wildcard records (an asterisk in the Name/Host field). In
the dashboard: **Domains → 8as.world → DNS → DNS Settings → Custom Records**:

```
Type: A    Host: *    Data: 64.225.124.41
```

One record by hand, covers all fifty states plus `prod` plus anything added
later. This is the whole job as far as *resolution* goes.

**But it does not solve TLS, and TLS is the blocker.** A request to
`ca.8as.world` against a cert that only covers `dev.8as.world` fails the
handshake before HTTP — the app errors outright rather than degrading. You need
a `*.8as.world` cert, and **Let's Encrypt only issues wildcards via the DNS-01
challenge**, which means writing an `_acme-challenge.8as.world` TXT record on
every renewal. With no API that is a manual dashboard edit roughly every 60–90
days, forever, and the whole fleet goes dark if one is missed.

Viable only as a stopgap, or if you get certs some other way.

Known wrinkle: a [Squarespace forum
report](https://forum.squarespace.com/topic/303677-cannot-add-wildcard-subdomain-to-domain/)
says *nested* wildcards (`*.sub.domain.tld`) are rejected. A top-level
`*.8as.world` is the simple case and should be accepted — confirm in the UI
before relying on it.

## Option B — move DNS hosting to DigitalOcean, keep the registration ← recommended

The domain stays registered at Squarespace. Only the nameservers change, which
is one manual step, and everything after it is scriptable — including cert
renewal, which is the part that actually matters.

This is also what the rest of this directory already assumes:
`05-configure-dns.sh` says outright *"your domain registrar must delegate DNS
to DigitalOcean nameservers."*

### 1. Local tooling

None of `doctl`, `certbot`, or `aws` is installed on the Mac as of this
writing.

```bash
brew install doctl
doctl auth init          # paste a DO API token with read+write scope
```

### 2. Create the zone and the wildcard record

```bash
DROPLET_IP=64.225.124.41   # dev.8as.world today; confirm before running

doctl compute domain create 8as.world --ip-address "$DROPLET_IP"

# The wildcard covers every state plus prod plus anything future.
doctl compute domain records create 8as.world \
  --record-type A --record-name '*' --record-data "$DROPLET_IP" --record-ttl 3600

# Keep dev explicit — existing installs are pinned to it and must not move.
doctl compute domain records create 8as.world \
  --record-type A --record-name 'dev' --record-data "$DROPLET_IP" --record-ttl 3600
```

`doctl compute domain create` adds its own NS records and an @ A record
automatically.

### 3. Repoint the nameservers at Squarespace

Dashboard → **Domains → 8as.world → Nameservers → Use custom nameservers**:

```
ns1.digitalocean.com
ns2.digitalocean.com
ns3.digitalocean.com
```

This is the only manual step, and the only irreversible-feeling one. Anything
currently served off Squarespace DNS for this domain stops resolving the moment
delegation moves, so recreate those records in DO **first** (step 2) — the
wildcard alone will not cover an MX or TXT record that something depends on.
Capture what exists before you switch:

```bash
for t in A AAAA CNAME MX TXT NS; do echo "== $t =="; dig +short "$t" 8as.world; done
```

Propagation is usually minutes, but the registrar's TTL can hold it for up to
48h. Confirm with:

```bash
dig +short NS 8as.world          # expect ns1-3.digitalocean.com
dig +short ca.8as.world          # expect the droplet IP
dig +short zz.8as.world          # wildcard: also the droplet IP
```

### 4. Wildcard certificate

**`06-configure-ssl.sh` will not do this.** It runs `certbot --nginx`, an
HTTP-01 challenge for a single name; HTTP-01 cannot issue wildcards. Use the
DNS-01 plugin instead, on the droplet:

```bash
apt-get install -y certbot python3-certbot-dns-digitalocean

install -d -m 700 ~/.secrets
cat > ~/.secrets/do.ini <<'EOF'
dns_digitalocean_token = <DO_API_TOKEN>
EOF
chmod 600 ~/.secrets/do.ini

certbot certonly \
  --dns-digitalocean \
  --dns-digitalocean-credentials ~/.secrets/do.ini \
  --dns-digitalocean-propagation-seconds 60 \
  -d '8as.world' -d '*.8as.world' \
  --agree-tos -m <you@example.com> --no-eff-email
```

`*.8as.world` does **not** cover the apex, which is why both names are listed.
It also does not cover a second label — `a.b.8as.world` needs its own cert.

Renewal is then unattended; `certbot renew` reuses the stored credentials.
Verify the timer is live:

```bash
systemctl list-timers | grep certbot
certbot renew --dry-run
```

### 5. Point nginx at the wildcard cert

In the `dev.8as.world.nginx.conf` server block, swap the cert paths:

```nginx
ssl_certificate     /etc/letsencrypt/live/8as.world/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/8as.world/privkey.pem;
```

`server_name` also has to stop being just `dev.8as.world`, or every other
hostname falls through to whatever the default server is:

```nginx
server_name 8as.world *.8as.world;
```

Then:

```bash
nginx -t && systemctl reload nginx
```

### 6. Verify end to end

```bash
for h in dev ca ny prod; do
  printf '%-6s cert=%s  bdo=%s\n' "$h" \
    "$(echo | openssl s_client -connect $h.8as.world:443 -servername $h.8as.world 2>/dev/null | openssl x509 -noout -checkhost $h.8as.world 2>&1 | tail -1)" \
    "$(curl -s -o /dev/null -w '%{http_code}' https://$h.8as.world/bdo/)"
done
```

A working host returns the service's own 404 (`Cannot GET /`) from `/bdo/`.
nginx's JSON catch-all means no route; a 502 means nothing is listening.

## Fifty explicit records instead of a wildcard

If you'd rather have one record per state — clearer in the DO dashboard, and it
lets a state point somewhere other than the shared droplet later:

```bash
DROPLET_IP=64.225.124.41
for s in al ak az ar ca co ct de fl ga hi id il in ia ks ky la me md \
         ma mi mn ms mo mt ne nv nh nj nm ny nc nd oh ok or pa ri sc \
         sd tn tx ut vt va wa wv wi wy prod; do
  doctl compute domain records create 8as.world \
    --record-type A --record-name "$s" --record-data "$DROPLET_IP" --record-ttl 3600
done
```

The wildcard cert is still required either way — fifty A records do not imply
fifty certs, and issuing fifty individual certs would hit Let's Encrypt's rate
limit of 50 certificates per registered domain per week exactly.

## Rollback

Set the nameservers back to `nsc1`–`nsc4.squarespacedns.com` in the Squarespace
dashboard. The DO zone can stay; it is inert once delegation moves away.

## Open questions when this gets picked up

- **Is every state one droplet, or fifty?** Everything above points all fifty
  at `64.225.124.41`, which means one allyabase serving every state — fine for
  launch, but then the per-state split is naming only, not isolation. Fifty
  droplets means fifty A records with different IPs (use the loop above, not
  the wildcard) and fifty allyabase deploys.
- **DC and the territories** currently fall through to `prod.8as.world`. A DC
  user is silently demoted with no indication. Adding a 51st host is a
  one-line change to `STATE_CODES` in bizbuz.
- **linkitylink is untouched** — it still has hardcoded `dev.8as.world`
  constants and would need the same per-state treatment to follow.

Sources: [Squarespace developer portal](https://developers.squarespace.com/),
[Edit your domain's DNS records](https://support.squarespace.com/hc/en-us/articles/360002101888-Edit-your-domain-s-DNS-records),
[DNS records for web hosting](https://support.squarespace.com/hc/en-us/articles/31119879125645-DNS-records-for-web-hosting)
