#this should never be run standalone, it should only be accessed by sourcing it from request.sh
import clear

LOBBYN_USER_createUser(){ #userId, password
    local userId="$1"
    local password="$2"
    local display_name="$3"

    mkdir -p database/users/$userId

    echo -n "$password" | argon2 "$userId" -e -l $ARGON2_LENGTH -t $ARGON2_ITERATIONS -k $ARGON2_MEMORY -p $ARGON2_PARALLELISM > database/users/$userId/password
    touch "database/users/$userId/riot_accounts"
    echo -e "$display_name" > "database/users/$userId/display_name"
}

LOBBYN_USER_deleteUser(){ #userId - can throw error
    local userId="$1"

    if [ ! -d "database/user/$userId" ]; then
        LOBBYN_ERROR_CODE=404
        LOBBYN_ERROR_MESSAGE="User not found."
        return $LOBBYN_ERROR_CODE
    fi 

    local riot_accounts
    mapfile -t riot_accounts < "database/users/$userId/riot_accounts"

    for puuid in "${riot_accounts[@]}"; do
        rm -f "database/riot_accounts/$puuid"
    done

    rm -rf "database/users/$userId"
}

LOBBYN_USER_linkPuuid(){ #userId, puuid, region - can throw error
    local userId="$1"
    local puuid="$2"
    local region="$3"

    if [ -f "database/riot_accounts/$puuid" ]; then
        LOBBYN_ERROR_CODE=409
        LOBBYN_ERROR_MESSAGE="PUUID already linked to another user"
        return $LOBBYN_ERROR_CODE
    fi

    if [ ! -d "database/users/$userId" ]; then
        LOBBYN_ERROR_CODE=404
        LOBBYN_ERROR_MESSAGE="User not found."
        return $LOBBYN_ERROR_CODE
    fi

    echo "$puuid" >> database/users/$userId/riot_accounts
    echo "$(jo -p owner=$userId region=$region)" > database/riot_accounts/$puuid
}

LOBBYN_USER_unlinkPuuid(){ #userId, puuid - can throw error
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

LOBBYN_USER_checkId(){ #userId - can throw error
    local userId="$1"

    if [ ! -d "database/users/$userId" ]; then
        LOBBYN_ERROR_CODE=404
        LOBBYN_ERROR_MESSAGE="User not found."
        return $LOBBYN_ERROR_CODE
    fi
}

LOBBYN_USER_getIdByPuuid(){ #puuid - can throw error
    local puuid="$1"

    if [ ! -f "database/riot_accounts/$puuid" ]; then
        LOBBYN_ERROR_CODE=404
        LOBBYN_ERROR_MESSAGE="PUUID not found"
        return $LOBBYN_ERROR_CODE
    fi

    LOBBYN_USER_ID=$(cat "database/riot_accounts/$puuid" | jq -r '.owner')
}

LOBBYN_USER_getRiotAccountsPuuidById(){ #userId - can throw error
    local userId="$1"

    if [ ! -f "database/users/$userId/riot_accounts" ]; then
        LOBBYN_ERROR_CODE=404
        LOBBYN_ERROR_MESSAGE="User not found."
        return $LOBBYN_ERROR_CODE
    fi

    mapfile -t LOBBYN_USER_RIOT_ACCOUNTS_PUUIDS < "database/users/$userId/riot_accounts"
}

#only use this function from /user/
LOBBYN_USER_checkIfPuuidInVerificationProcess(){ #puuid - can throw error
    local puuid="$1"
    local token
    for token in tmp/*; do
        if [ ! -f $token ]; then
            continue
        fi

        local expiration=$(cat $token | jq -r '.expiration')

        if [ "$expiration" -lt $(date +%s) ]; then
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

#only use this function from /login/
LOBBYN_USER_checkIfUserIdInLoginProcess(){ #userId - can throw error
    local userId="$1"
    for token in tmp/*; do
        if [ ! -f $token ]; then
            continue
        fi

        local type="$(cat $token | jq -r '.type')"

        if [ ! "$type" = "loginRequest" ]; then
            continue
        fi

        local expiration="$(cat $token | jq -r '.expiration')"

        if [ "$expiration" -lt $(date +%s) ]; then
            continue
        fi

        local userId_to_verify="$(cat $token | jq -r '.data.userId')"

        if [ "$userId_to_verify" = "$userId" ]; then
            LOBBYN_ERROR_CODE=409
            LOBBYN_ERROR_MESSAGE="User login request already exists. Respond to existing one or wait for it to expire."
            return $LOBBYN_ERROR_CODE
        fi
    done
}

#only use this function from /login/
LOBBYN_USER_checkIfUserLoggedIn(){ #userId - can throw error
    local userId="$1"

    for token in tmp/*; do
        if [ ! -f $token ]; then
            continue
        fi

        local type="$(cat $token | jq -r '.type')"

        if [ ! "$type" = "access" ]; then
            continue
        fi

        local expiration="$(cat $token | jq -r '.expiration')"

        if [ "$expiration" -lt $(date +%s) ]; then
            continue
        fi

        local userId_to_verify="$(cat $token | jq -r '.data.userId')"

        if [ "$userId_to_verify" = "$userId" ]; then
            LOBBYN_ERROR_CODE=409
            LOBBYN_ERROR_MESSAGE="User already logged in."
            return $LOBBYN_ERROR_CODE
        fi
    done
}