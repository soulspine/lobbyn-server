#this should never be run standalone, it should only be accessed by sourcing it from request.sh
import token clear user

LOBBYN_LOGIN_initial(){ #userId - can throw error
    local userId="$1"

    LOBBYN_CLEAR_ERROR
    LOBBYN_USER_checkIfUserIdInLoginProcess $userId

    if [ ! -z "$LOBBYN_ERROR_CODE" ]; then
        return $LOBBYN_ERROR_CODE
    fi

    local salt=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | head -c $TOKEN_LENGTH)
    local default_hash=$(cat database/users/$userId/password)

    LOBBYN_LOGIN_SALT=$salt
    
    local hash=$(echo -n "$default_hash" | argon2 "$salt" -e -l $ARGON2_LENGTH -t $ARGON2_ITERATIONS -k $ARGON2_MEMORY -p $ARGON2_PARALLELISM)

    LOBBYN_TOKEN_generate "$(jo -p userId=$userId salt=$salt hash=$hash)" "$LOGIN_REQUEST_TIMEOUT"

    LOBBYN_LOGIN_TOKEN=$LOBBYN_TOKEN
}

LOBBYN_LOGIN_finalize(){ #token, received_hash - can throw error
    local token="$1"
    local received_hash="$2"

    LOBBYN_CLEAR_ERROR
    LOBBYN_TOKEN_get $token

    if [ -z "$LOBBYN_ERROR_CODE" ]; then
        return $LOBBYN_ERROR_CODE
    fi

}