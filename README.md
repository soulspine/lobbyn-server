# Requirements
- ucspi-tcp
- stunnel
- openssl certificate
- argon2

# Available endpoints

### Wildcard
- `/info/{}` - returns request info in format: `ip={}, method={}, endpoint={}, body={}`. Any endpoint past `/info/` is accepted and returned

### GET
- `/` - returns a simple text message with credits
- `/login/` - returns info about argon2 hash parameters

### POST
- `/user/` - initial request to create a user, returns a token, requires a body with `username`, `tagline` and `region`
- `/user/verify` - request to create a user, returns `userId`, requires a body with `token` and `password`
- `/login/` - initial request to log in, returns a `token` and `salt`, requires a body with `userId` or `puuid`
- `/login/verify` - request to log in, returns an access `token`, requires a body with initial `token` and `hash`

### PATH
- `/user/setting` - request to change user's settings, requires a valid `LOBBYN-Token` header and a body values to change, only valid keys are accepted, rest are ignored

# User creation
- Send a POST request to `/user/` with a body containing `username`, `tagline` and `region`
- The server will return a `token` and `iconId`
- Change the icon of the account to the one provided in the response
- Send a POST request to `/user/verify` with the `token` received in the first request and `password`

# Login
- Send a POST request to `/user/login` with a body containing either `userId` or `puuid`
- The server will return a `token` and `salt`
- Generate a hash of the password with the salt provided
- Send a POST request to `/user/login/verify` with the `token` received in the first request and the `hash` of the password

If the login is successful, the server will return a new access `token` used for verification in future requests. Access token has to be included in `LOBBYN-Token` header.

# Exit codes:
- 0: Success
- 1: Config file not found
- 2: Config file not valid
- 3: No SSL certificate found

# Config fields
- `HTTP_PORT` - Port to run the server on natively
- `HTTPS_PORT` - Port to run the server on with stunnel proxy
- `RIOT_API_KEY` - Key to acces Riot API, generated [here](https://developer.riotgames.com/)
- `RIOT_CONTINENT` - Routing value to use for the Riot API, available options are: `americas`, `asia`, `europe`
- `TOKEN_LENGTH` - Length of generated tokens
- `BODY_READ_TIMEOUT` - Timeout for reading the body of the request, it is needed to avoid
- `USER_CREATION_TIMEOUT` - How long token is valid for user creation in seconds
- `LOGIN_REQUEST_TIMEOUT` - How long token is valid for login request seconds
- `ACCESS_SESSION_TIMEOUT` - How long token is valid for login session in seconds, this is refreshed on every successful request
- `CLEANUP_INTERVAL` - How often to check for expired tokens in seconds

# Known issues