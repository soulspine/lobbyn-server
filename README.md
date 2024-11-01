# Requirements
- ucspi-tcp
- stunnel
- openssl certificate

# Available endpoints

### Wildcard
- `/info/{}` - returns request info in format: `ip={}, method={}, endpoint={}, body={}`. Any endpoint past `/info/` is accepted and returned

### GET
- `/` - returns a simple text message with credits
- `/user/` - returns user info from Riot API, requires body of the request to be in format: `{"username": "<u>", "tagline": "<t>", "region": "<r>"}`

### POST
- `/echo/` - returns the body of the request

# Exit codes:
- 0: Success
- 1: Config file not found
- 2: Config file not valid
- 3: No SSL certificate found

# Config fields
- `RIOT_API_KEY` - Key to acces Riot API, generated [here](https://developer.riotgames.com/)
- `HTTP_PORT` - Port to run the server on natively
- `HTTPS_PORT` - Port to run the server on with stunnel proxy
- `BODY_READ_TIMEOUT` - Timeout for reading the body of the request, it is needed to avoid 

# Known issues