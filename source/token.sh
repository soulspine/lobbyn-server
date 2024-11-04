#this should never be run standalone, it should only be accessed by sourcing it from request.sh

#LOBBYN_TOKEN - token
#LOBBYN_TOKEN_EXPIRATION - token expiration time
#LOBBYN_TOKEN_DATA - token data

#tokens go into tmp
LOBBYN_TOKEN_generate(){
    LOBBYN_TOKEN_DATA="$1"
    LOBBYN_TOKEN=$(openssl rand -base64 $(( ($TOKEN_LENGTH * 3 + 3) / 4 )) | tr -dc 'A-Za-z0-9' | head -c $TOKEN_LENGTH)
    LOBBYN_TOKEN_EXPIRATION=$(($(date +%s) + $2))

    jo -p expiration="$LOBBYN_TOKEN_EXPIRATION" data="$LOBBYN_TOKEN_DATA" > "tmp/$LOBBYN_TOKEN"
}

LOBBYN_TOKEN_get(){
    local token="$1"

    if [ ! -f "tmp/$token" ]; then
        LOBBYN_ERROR_CODE=404
        LOBBYN_ERROR_MESSAGE="Token not found."
        return $LOBBYN_ERROR_CODE
    fi

    LOBBYN_TOKEN=$token
    LOBBYN_TOKEN_EXPIRATION=$(cat "tmp/$token" | jq -r '.expiration')
    LOBBYN_TOKEN_DATA=$(cat "tmp/$token" | jq -r '.data')
    
    if [ $LOBBYN_TOKEN_EXPIRATION -lt $(date +%s) ]; then
        LOBBYN_ERROR_CODE=401
        LOBBYN_ERROR_MESSAGE="Token expired."
        return $LOBBYN_ERROR_CODE
    fi

}

LOBBYN_TOKEN_close(){
    local token="$1"
    rm -f "tmp/$token"
}

#only use this function from /user/
LOBBYN_TOKEN_checkIfPuuidInVerificationProcess(){
    local puuid="$1"
    local token
    for token in tmp/*; do
        if [ ! -f $token ]; then
            continue
        fi

        local expiration=$(cat $token | jq -r '.expiration')

        if [ "$expiration" -lt $(date +%s) ]; then
            rm -f $token
            continue
        fi

        local puuid_to_verify=$(cat $token | jq -r '.data.puuid')

        if [ "$puuid_to_verify" = "$puuid" ]; then
            LOBBYN_ERROR_CODE=409
            LOBBYN_ERROR_MESSAGE="User creation request already exists. Respond to existing one or wait for it to expire."
            return $LOBBYN_ERROR_CODE
        fi
    done
}