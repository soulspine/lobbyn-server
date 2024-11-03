#this should never be run standalone, it should only be accessed by sourcing it from request.sh

LOBBYN_USER_createUser(){
    local userId="$1"
    local password="$2"

    mkdir -p database/users/$userId

    echo -n "$password" | argon2 "$userId" -e -l $ARGON2_LENGTH -t $ARGON2_ITERATIONS -k $ARGON2_MEMORY -p $ARGON2_PARALLELISM > database/users/$userId/password
    touch "database/users/$userId/riot_accounts"
}

LOBBYN_USER_linkPuuid(){
    local userId="$1"
    local puuid="$2"
    local region="$3"

    if [ -f "database/riot_accounts/$puuid" ]; then
        LOBBYN_ERROR_CODE=409
        LOBBYN_ERROR_MESSAGE="PUUID already linked to another user"
        return $LOBBYN_ERROR_CODE
    fi

    echo "$puuid" >> database/users/$userId/riot_accounts
    echo "$(jo -p owner=$userId region=$region)" > database/riot_accounts/$puuid
}

LOBBYN_USER_unlinkPuuid(){
    local userId="$1"
    local puuid="$2"

    if [ ! -f "database/riot_accounts/$puuid" ]; then
        LOBBYN_ERROR_CODE=404
        LOBBYN_ERROR_MESSAGE="PUUID not found"
        return $LOBBYN_ERROR_CODE
    fi

    sed -i "/$puuid/d" database/users/$userId/riot_accounts
    rm -f "database/riot_accounts/$puuid"
}

LOBBYN_USER_verifyPassword(){
    local hash=$1

    if [ "$hash" = "$(cat database/users/$puuid/password)" ]; then
        return 0
    else
        return 1
    fi
}