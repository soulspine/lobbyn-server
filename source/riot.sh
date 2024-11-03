#this should never be run standalone, it should only be accessed by sourcing it from request.sh

LOBBYN_RIOT_getUserByName(){
    local username=$(echo "$1" | tr -d '\n' | jq -sRr @uri)
    local tagline=$(echo "$2" | tr -d '\n' | jq -sRr @uri)
    local region=$(echo "$3" | tr -d '\n' | jq -sRr @uri)

    local user_request=$(curl -s -X GET "https://$LOBBYN_RIOT_CONTINENT.api.riotgames.com/riot/account/v1/accounts/by-riot-id/$username/$tagline" -H "X-Riot-Token: $RIOT_API_KEY")
    local status_code=$(echo $user_request | jq -r '.status.status_code')

    if [ ! "$status_code" = "null" ]; then
        LOBBYN_RIOT_USER=""
        LOBBYN_ERROR_CODE="$status_code"
        LOBBYN_ERROR_MESSAGE=$(echo $user_request | jq -r '.status.message')
        return $status_code
    fi

    local puuid=$(echo "$user_request" | jq -r '.puuid')

    local summoner_request=$(curl -s -X GET "https://$region.api.riotgames.com/lol/summoner/v4/summoners/by-puuid/$puuid" -H "X-Riot-Token: $RIOT_API_KEY")

    if [ -z "$summoner_request" ]; then
        LOBBYN_RIOT_USER=""
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="$region is not a valid region"
        return 400
    fi

    LOBBYN_RIOT_USER="$summoner_request"
}

LOBBYN_RIOT_getUserByPuuid(){
    local puuid=$(echo "$1" | tr -d '\n' | jq -sRr @uri)
    local region=$(echo "$2" | tr -d '\n' | jq -sRr @uri)

    local summoner_request=$(curl -s -X GET "https://$region.api.riotgames.com/lol/summoner/v4/summoners/by-puuid/$puuid" -H "X-Riot-Token: $RIOT_API_KEY")

    if [ -z "$summoner_request" ]; then
        LOBBYN_RIOT_USER=""
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="Invalid puuid"
        return 400
    fi

    LOBBYN_RIOT_USER="$summoner_request"
}