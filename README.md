# Available endpoints
### GET
- `/` - returns a simple text message with credits
- `/info/` - returns request info in format: `ip={}, method={}, endpoint={}`
- `/summoner/{name}/{tagline}/` - returns summoner info for given name and tagline, fetched from Riot API

### POST
- `/echo/` - returns the body of the request

# Exit codes:
- 0: Success
- 1: Config file not found
- 2: Config file not valid
- 3: Invalid Content-Length header

# Config fields
- `RIOT_API_KEY` - Key to acces Riot API, generated [here](https://developer.riotgames.com/)
- `PORT` - Port to run the server on
- `BODY_READ_TIMEOUT` - Timeout for reading the body of the request, it is needed to avoid 

# Known issues
- When using `/echo/` with body being multiple backslashes, server returns invalid Content-Length header, low priority, echo is just for testing purposes