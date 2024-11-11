#this should never be run standalone, it should only be accessed by sourcing it from request.sh

#LOBBYN_TOKEN - token
#LOBBYN_TOKEN_EXPIRATION - token expiration time
#LOBBYN_TOKEN_DATA - token data

#tokens go into tmp
LOBBYN_TOKEN_generate(){ #data, expiration, type
    LOBBYN_TOKEN_DATA="$1"
    LOBBYN_TOKEN=$(openssl rand -base64 $(( ($TOKEN_LENGTH * 3 + 3) / 4 )) | tr -dc 'A-Za-z0-9' | head -c $TOKEN_LENGTH)
    LOBBYN_TOKEN_EXPIRATION=$(($(date +%s) + $2))
    LOBBYN_TOKEN_TYPE="$3"

    jo -p expiration=$LOBBYN_TOKEN_EXPIRATION type="$LOBBYN_TOKEN_TYPE" data="$LOBBYN_TOKEN_DATA" > "tmp/$LOBBYN_TOKEN"
}

LOBBYN_TOKEN_get(){ #token - can throw error
    local token="$1"

    if [ ! -f "tmp/$token" ]; then
        LOBBYN_ERROR_CODE=404
        LOBBYN_ERROR_MESSAGE="Token not found."
        return $LOBBYN_ERROR_CODE
    fi

    LOBBYN_TOKEN=$token
    LOBBYN_TOKEN_EXPIRATION=$(cat "tmp/$token" | jq -r '.expiration')
    LOBBYN_TOKEN_DATA=$(cat "tmp/$token" | jq -r '.data')
    LOBBYN_TOKEN_TYPE=$(cat "tmp/$token" | jq -r '.type')
    
    if [ $LOBBYN_TOKEN_EXPIRATION -lt $(date +%s) ]; then
        LOBBYN_ERROR_CODE=401
        LOBBYN_ERROR_MESSAGE="Token expired."
        return $LOBBYN_ERROR_CODE
    fi

}

LOBBYN_TOKEN_extend(){ #token, expiration
    local token="$1"
    local expiration=$2

    LOBBYN_CLEAR_ERROR
    LOBBYN_TOKEN_get "$token"

    if [ ! -z $LOBBYN_ERROR_CODE ]; then
        return $LOBBYN_ERROR_CODE
    fi

    LOBBYN_TOKEN_EXPIRATION=$(($(date +%s) + $expiration))
    jq --argjson expiration $LOBBYN_TOKEN_EXPIRATION '.expiration = $expiration' "tmp/$LOBBYN_TOKEN" > "tmp/$LOBBYN_TOKEN.tmp" && mv "tmp/$LOBBYN_TOKEN.tmp" "tmp/$LOBBYN_TOKEN"
}

LOBBYN_TOKEN_close(){ #token
    rm -f "tmp/$1"
}