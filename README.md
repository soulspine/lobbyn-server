# Requirements
- ucspi-tcp
- stunnel
- openssl certificate
- argon2

# Endpoint list

### `{}` [`/info/{}`](#info) - returns request info
### `GET` [`/`](#empty-details) - simple text message with credits
### `GET` `/login/` - info about argon2 hash parameters
### `GET` `/user/settings/` - user's settings, requires a valid `LOBBYN-Token` header
### `POST` `/user/` - initial request to create a user, returns a token, requires a body with `username`, `tagline` and `region`
### `POST` `/user/verify` - request to create a user, returns `userId`, requires a body with `token` and `password`
### `POST` `/login/` - initial request to log in, returns a `token` and `salt`, requires a body with `userId` or `puuid`
### `POST` `/login/verify` - request to log in, returns an access `token`, requires a body with initial `token` and `hash`
### `POST` `/tournament/` - request to create a tournament, requires a valid `LOBBYN-Token` header. [See all fields](#tournament-creation)
### `PATCH` `/user/setting` - request to change user's settings, requires a valid `LOBBYN-Token` header and a json object body containing values to change, only valid keys are accepted, rest are ignored

# Endpoint details
## `/info/{}`
**Returns request info**

Required fields: `None` \
Optional fields: `None`

#### Examples
`>curl -k https://DOMAIN_PLACEHOLDER/info -d "HELLO"`
```json
{
   "ip": "192.168.1.44",
   "method": "POST",
   "endpoint": "/info/",
   "body": "HELLO"
}
```
\
`>curl -k https://DOMAIN_PLACEHOLDER/info/2/3/4 -X METHOD -d "{\"foo\":\"bar\"}"`
```json
{
   "ip": "192.168.1.44",
   "method": "METHOD",
   "endpoint": "/info/2/3/4/",
   "body": {
      "foo": "bar"
   }
}
```

<h2 id="empty-details" style="font-size:20vw">/</h2>
## `/` {#empty-details}
**Simple text message with credits**

Required fields: `None` \
Optional fields: `None`

# `/login/`


- `/` - returns a simple text message with credits
- `/login/` - returns info about argon2 hash parameters
- `/user/settings/` - returns user's settings, requires a valid `LOBBYN-Token` header

### POST
- `/user/` - initial request to create a user, returns a token, requires a body with `username`, `tagline` and `region`
- `/user/verify` - request to create a user, returns `userId`, requires a body with `token` and `password`
- `/login/` - initial request to log in, returns a `token` and `salt`, requires a body with `userId` or `puuid`
- `/login/verify` - request to log in, returns an access `token`, requires a body with initial `token` and `hash`
- `/tournament/` - request to create a tournament, requires a valid `LOBBYN-Token` header. [See all fields](#tournament-creation) 

### PATCH
- `/user/setting` - request to change user's settings, requires a valid `LOBBYN-Token` header and a json object body containing values to change, only valid keys are accepted, rest are ignored

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

# Tournament creation
To create a tournament, you need to be logged in and send a POST request to `/tournament/`. Available fields are:

### Required:
- `name` - Name of the tournament
- `teamSize` - number between 1 and 5
- `gameMode` - one of the following: `CLASSIC`, `ARAM`
- `format` - one of the following: `ROUND_ROBIN`, `SINGLE_ELIMINATION`, `DOUBLE_ELIMINATION`
- `region` - one of the following: `br1` `eun1` `euw1` `jp1` `kr` `la1` `la2` `me1` `na1` `oc1` `ph2` `ru` `sg2` `th2` `tr1` `tw2` `vn2`
- `visibility` - one of the following: `PUBLIC`, `PRIVATE`
- `joinPolicy` - one of the following: `OPEN`, `INVITE-ONLY`

### Optional:
- `description` - Description of the tournament

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
- `BODY_READ_TIMEOUT` - Timeout for reading the body of the request, it is needed to avoid program just hanging on reading the body with invalid `Content-Length` header
- `USER_CREATION_TIMEOUT` - How long token is valid for user creation in seconds
- `LOGIN_REQUEST_TIMEOUT` - How long token is valid for login request seconds
- `ACCESS_SESSION_TIMEOUT` - How long token is valid for login session in seconds, this is refreshed on every successful request
- `CLEANUP_INTERVAL` - How often to check for expired tokens in seconds

# Known issues
- Body is not read properly when using polish characters (i assume the same for all non-ascii characters)
- README is a mess, I will fix it at some point