# Requirements
- ucspi-tcp
- stunnel
- openssl certificate

# Available endpoints

### Wildcard
- `/info/{}` - returns request info in format: `ip={}, method={}, endpoint={}, body={}`. Any endpoint past `/info/` is accepted and returned

### GET
- `/` - returns a simple text message with credits

### POST
- `/echo/` - returns the body of the request
- `/user/` - initial request to create a user, returns a token, requires a body with `username`, `tagline` and `region`
- `/user/verify` - request to create a user, returns `userId`, requires a body with `token` and `password`

# User creation
- Send a POST request to `/user/` with a body containing `username`, `tagline` and `region`
- The server will return a `token` and `iconId`
- Change the icon of the account to the one provided in the response
- Send a POST request to `/user/verify` with the `token` received in the first request and `password`


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
- `LOBBYN_RIOT_CONTINENT` - Routing value to use for the Riot API, available options are: `americas`, `asia`, `europe`
- `USER_CREATION_TIMEOUT` - How long token is valid for user creation

# Known issues