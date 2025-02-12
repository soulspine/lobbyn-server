# Lobbyn Example Bash Restful API Server
This repository is a working REST API written entirely in bash with code being broken up into modules that are imported into `request.sh` by custom `import` function. Allows for basic logging and handling multiple sessions at the same time. Currently implemented endpoints allow for user creation based on Riot (League of Legends) Accounts, login process based on expiring access tokens and dummy tournament creation. It is more of a proof of concept than a fully working program.

I would say creating an API in bash is a good learning experience but I would not recommend using it over any other professional implementation for real use scenarios. There is just too many hoops to jump through to make it barely work and then, after a few weeks, you have a very poorly secured version of what you could get in seconds by setting it up with Flask or Spring Boot.

# Why bash and how I came to conclusion what parameters to use for all the stuff
Bash because it was a project for my university course. I came to the conclusion what parameters to use by quick research and opinions of user on forums like StackOverflow. For example, I chose argon2 to store password because it was widely known as the best at it and hash parameters have been chosen by me after trial and error and tweaking them to both be "secure" (so brute force attacks would not be as easy) and it would not take too long to generate on user's end so it would not be very inconvenient. When choosing SSL certificate parameters, I used defaults just to have a self-signed certificate that would work for the purpose of stunnel.

# Requirements
- [ucspi-tcp](https://cr.yp.to/ucspi-tcp.html)
- [stunnel](https://www.stunnel.org/)
- openssl certificate in SSL/ (`SSLgen.sh` can be used to generate one)
- argon2
- [jq](https://jqlang.org/)

# Endpoints

## `~ANY~` `/info/{}` - returns request info and echoes the body

does not require any field or specific body, it is just a diagnostic endpoint

```
> curl -k https://LOBBYN.DOMAIN/info/123 -d "HELLO"
```
```json
{
   "ip": "192.168.1.44",
   "method": "POST",
   "endpoint": "/info/123",
   "body": "HELLO"
}
```

## `GET` `/` - simple text message with credits

## `POST` `/user/` - initial request to create a user
It requires user to change the icon of the account to the one provided in the response before sending the verification request.
### requires
a json object body with fields:
   - `username` - name of the Riot Account
   - `tagline` - tagline of the Riot Account
   - `region` it has to be one of the following: `br1` `eun1` `euw1` `jp1` `kr` `la1` `la2` `me1` `na1` `oc1` `ph2` `ru` `sg2` `th2` `tr1` `tw2` `vn2`

### returns
a json object with field:
   - `iconId` - icon id that has to be set on the Riot Account
   - `token` that has to be passed to the `/user/verify` endpoint
   - `validUntil` - timestamp when the token expires

## `POST` `/user/verify` - finalizing request to create a user
It verifies if the account icon was changed to the correct one. If it was not, user will not be created.
### requires
a json object body with fields:
   - `token` received from the `/user/` endpoint
   - `password` - password for the account, it will be stored as an argon2 hash with salt being the unique `userId` that this endpoint returns (read more about logging in [here](#login))

### returns
a json object with field:
   - `userId` - unique ID assigned to this account

## `GET` `/login/` - info about argon2 parameters used to generate password hashes

## `POST` `/login/` - initial request to log in
### requires
a json object body with only one field: either `userId` or `puuid`

### returns
a json object with fields:
   - `token` - token that has to be passed to the `/login/verify` endpoint
   - `salt` - it has to be used to hash the original password hash (learn more about login hash [here](#login))

## `POST` `/login/verify` - finalizing request to log in
### requires
a json object body with fields:
   - `token` received from the `/login/` endpoint
   - `hash` - learn more about login hash [here](#login)

### returns
a json object with field:
   - `token` - access token that has to be passed in the `LOBBYN-Token` header in all future requests that require authentication, by default it is valid for 15 minutes and this time is refreshed on every successful request

## `GET` `/user/settings/` - fetching user's settings
It retrieves user's settings based on the `LOBBYN-Token` header.
### requires
a valid `LOBBYN-Token` header

### returns
a json object with fields:
   - `displayName` - internal name of the user

## `PATCH` `/user/setting` - changing user's settings
### requires
a valid `LOBBYN-Token` header and a json object body containing values to change, only valid keys are accepted, all other keys are ignored; since the only valid key is `displayName`, it is the only one that can be changed

## `POST` `/tournament/` - request to create a tournament
### requires
a valid `LOBBYN-Token` header and a json object body with fields:
   - `name`
   - `region` - one of the following: `br1` `eun1` `euw1` `jp1` `kr` `la1` `la2` `me1` `na1` `oc1` `ph2` `ru` `sg2` `th2` `tr1` `tw2` `vn2`
   - `teamSize` - number between 1 and 5
   - `gamemode` - one of the following: `CLASSIC`, `ARAM`
   - `visibility` - one of the following: `PUBLIC`, `PRIVATE` - determines if the tournament is visible to everyone or only to invited players
   - `joinPolicy` - one of the following: `OPEN`, `INVITE-ONLY` - determines if the tournament is open for everyone or only for invited players (there is currently no way to invite players)

### returns
a json object with fields:
   - `tournamentId` - unique ID assigned to this tournament

## `GET` `/tournament/` - fetch tournament's info
### requires
a json object body with field `tournamentId` and optionally a valid `LOBBYN-Token` header if the tournament is private

# Login
To log in, you need to generate a double hash doing the following:
- first generate a hash of the password with salt being `userId` of the account you want to log in as
- generate a hash of the previous hash where salt is the `salt` received in the response from the `/login/` endpoint

Parameters used to generate the hash are available in the response from the `/login/` endpoint.

If login is successful, the server will return a new access `token` used for verification in future requests. Access token has to be included in `LOBBYN-Token` header.

# Exit codes:
- 0: Success
- 1: Config file not found
- 2: Config file not valid
- 3: No SSL certificate found

# Config fields
- `HTTP_PORT` - Port to run the server on natively
- `HTTPS_PORT` - Port to run the server on with stunnel proxy
- `RIOT_API_KEY` - Key to acces Riot API, can be generated [here](https://developer.riotgames.com/)
- `RIOT_CONTINENT` - Routing value to use for the Riot API, available options are: `americas`, `asia`, `europe`
- `TOKEN_LENGTH` - Length of generated tokens
- `BODY_READ_TIMEOUT` - Timeout for reading the body of the request, it is needed to avoid program just hanging on reading the body with invalid `Content-Length` header
- `USER_CREATION_TIMEOUT` - How long token is valid for user creation in seconds
- `LOGIN_REQUEST_TIMEOUT` - How long token is valid for login request seconds
- `ACCESS_SESSION_TIMEOUT` - How long token is valid for login session in seconds, this is refreshed on every successful request
- `CLEANUP_INTERVAL` - How often to check for expired tokens in seconds
- `DISPLAY_NAME_MIN_LENGTH` - Minimum length of the display name
- `DISPLAY_NAME_MAX_LENGTH` - Maximum length of the display name
- `TOURNAMENT_NAME_MIN_LENGTH` - Minimum length of the tournament name
- `TOURNAMENT_NAME_MAX_LENGTH` - Maximum length of the tournament name

# Known issues
- Body is not read properly when using polish characters (i assume the same for all non-ascii characters)
- README is a mess, I will fix it at some point