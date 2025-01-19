#this should never be run standalone, it should only be accessed by sourcing it from request.sh

LOBBYN_TOURNAMENT_checkRegion(){ #region - can throw error
    local region=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    valid_regions=( 
            br1
            eun1
            euw1
            jp1
            kr
            la1
            la2
            me1
            na1
            oc1
            ph2
            ru
            sg2
            th2
            tr1
            tw2
            vn2
    )
    
    if [[ ! " ${valid_regions[@]} " =~ " $region " ]]; then
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="Invalid region."
        return 400
    fi
}

LOBBYN_TOURNAMENT_checkName(){ #name - can throw error
    local name=$(echo "$1" | tr -d '\n' | jq -sRr @uri)
    local name_length=${#name}

    if [ $name_length -lt $TOURNAMENT_NAME_MIN_LENGTH ] || [ $name_length -gt $TOURNAMENT_NAME_MAX_LENGTH ]; then
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="Invalid tournament name."
        return 400
    fi
}

LOBBYN_TOURNAMENT_checkTeamSize(){ #team_size - can throw error
    local team_size=$(echo "$1" | tr -d '\n' | jq -sRr @uri)

    if [ -z $team_size ] || [ $team_size -lt 1 ] || [ $team_size -gt 5 ]; then
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="Invalid team size."
        return 400
    fi
}

LOBBYN_TOURNAMENT_checkGamemode(){ #gamemode - can throw error
    local gamemode=$(echo "$1" | tr -d '\n' | jq -sRr @uri)

    valid_gamemodes=( 
            CLASSIC
            ARAM
    )
    
    if [[ ! " ${valid_gamemodes[@]} " =~ " $gamemode " ]]; then
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="Invalid gamemode."
        return 400
    fi
}

LOBBYN_TOURNAMENT_checkFormat(){ #format - can throw error
    local format=$(echo "$1" | tr -d '\n' | jq -sRr @uri)

    valid_formats=(
        ROUND_ROBIN
        SINGLE_ELIMINATION
        DOUBLE_ELIMINATION
    )

    if [[ ! " ${valid_formats[@]} " =~ " $format " ]]; then
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="Invalid format."
        return 400
    fi
}

LOBBYN_TOURNAMENT_checkVisibility(){ #visibility - can throw error
    local visibility=$(echo "$1" | tr -d '\n' | jq -sRr @uri)

    valid_visibilities=( 
            public
            private
    )
    
    if [[ ! " ${valid_visibilities[@]} " =~ " $visibility " ]]; then
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="Invalid visibility."
        return 400
    fi
}

LOBBYN_TOURNAMENT_checkJoinPolicy(){ #join_type - can throw error
    local join_policy=$(echo "$1" | tr -d '\n' | jq -sRr @uri)

    valid_join_policies=( 
            open
            invite-only
    )
    
    if [[ ! " ${valid_join_policies[@]} " =~ " $join_policy " ]]; then
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="Invalid join policy."
        return 400
    fi
}

LOBBYN_TOURNAMENT_createEmpty(){ #can throw error
    LOBBYN_TOURNAMENT_ID="T-$(uuidgen)"
    local organizer_id="$1"
    local name="$2"
    local region="$3"
    local team_size="$4"
    local gamemode="$5"
    local format="$6"
    local visibility="$7"
    local join_policy="$8"

    #check if all fields are valid
    bad_fields=""

    LOBBYN_CLEAR_ERROR
    LOBBYN_TOURNAMENT_checkName "$name"
    if [ ! -z "$LOBBYN_ERROR_CODE" ]; then
        bad_fields="$bad_fields name,"
    fi

    LOBBYN_CLEAR_ERROR
    LOBBYN_TOURNAMENT_checkRegion "$region"
    if [ ! -z "$LOBBYN_ERROR_CODE" ]; then
        bad_fields="$bad_fields region,"
    fi

    LOBBYN_CLEAR_ERROR
    LOBBYN_TOURNAMENT_checkTeamSize "$team_size"
    if [ ! -z "$LOBBYN_ERROR_CODE" ]; then
        bad_fields="$bad_fields teamSize,"
    fi

    LOBBYN_CLEAR_ERROR
    LOBBYN_TOURNAMENT_checkGamemode "$gamemode"
    if [ ! -z "$LOBBYN_ERROR_CODE" ]; then
        bad_fields="$bad_fields gamemode,"
    fi

    LOBBYN_CLEAR_ERROR
    LOBBYN_TOURNAMENT_checkFormat "$format"
    if [ ! -z "$LOBBYN_ERROR_CODE" ]; then
        bad_fields="$bad_fields format,"
    fi

    LOBBYN_CLEAR_ERROR
    LOBBYN_TOURNAMENT_checkVisibility "$visibility"
    if [ ! -z "$LOBBYN_ERROR_CODE" ]; then
        bad_fields="$bad_fields visibility,"
    fi

    LOBBYN_CLEAR_ERROR
    LOBBYN_TOURNAMENT_checkJoinPolicy "$join_policy"
    if [ ! -z "$LOBBYN_ERROR_CODE" ]; then
        bad_fields="$bad_fields joinPolicy,"
    fi

    if [ ! -z "$bad_fields" ]; then
        bad_fields="${bad_fields::-1}"
        LOBBYN_ERROR_CODE="400"
        LOBBYN_ERROR_MESSAGE="Invalid fields: $bad_fields"
        return $LOBBYN_ERROR_CODE
    fi

    mkdir -p database/tournaments/$LOBBYN_TOURNAMENT_ID/participants

    jo -p \
        organizer="$organizer_id" \
        moderators="[]" \
        region="$region" \
        status="pending" \
        participantCount=0 \
        teamCount=0 \
    > database/tournaments/$LOBBYN_TOURNAMENT_ID/persistentSettings.json

    jo -p \
        name="$name" \
        description="" \
        teamSize=$team_size \
        gamemode="$gamemode" \
        format=$format \
        visibility="$visibility" \
        joinPolicy="$join_policy" \
    > database/tournaments/$LOBBYN_TOURNAMENT_ID/settings.json

}

LOBBYN_TOURNAMENT_getById(){ #can throw error
    local tournamentId="$1"

    if [ ! -d "database/tournaments/$tournamentId" ]; then
        LOBBYN_ERROR_CODE="404"
        LOBBYN_ERROR_MESSAGE="Tournament not found."
        return $LOBBYN_ERROR_CODE
    fi

    local persistentSettings=$(cat "database/tournaments/$tournamentId/persistentSettings.json")
    local settings=$(cat "database/tournaments/$tournamentId/settings.json")

    local visibility=$(echo "$settings" | jq -r '.visibility')

    if [ "$visibility" = "private" ]; then
        LOBBYN_ERROR_CODE="403"
        #TODO CHECK IF USER IS IN THE TOURNAMENT
        LOBBYN_ERROR_MESSAGE="Tournament is private."
        return $LOBBYN_ERROR_CODE
    fi

    LOBBYN_TOURNAMENT_ID="$tournamentId"
    LOBBYN_TOURNAMENT_NAME=$(echo "$settings" | jq -r '.name')
    LOBBYN_TOURNAMENT_DESCRIPTION=$(echo "$settings" | jq -r '.description')
    LOBBYN_TOURNAMENT_TEAMSIZE=$(echo "$settings" | jq -r '.teamSize')
    LOBBYN_TOURNAMENT_GAMEMODE=$(echo "$settings" | jq -r '.gamemode')
    LOBBYN_TOURNAMENT_FORMAT=$(echo "$settings" | jq -r '.format')
    LOBBYN_TOURNAMENT_VISIBILITY="$visibility"
    LOBBYN_TOURNAMENT_JOIN_POLICY=$(echo "$settings" | jq -r '.joinPolicy')
    LOBBYN_TOURNAMENT_ORGANIZER_ID=$(echo "$persistentSettings" | jq -r '.organizer')
    LOBBYN_USER_getNameById "$LOBBYN_TOURNAMENT_ORGANIZER_ID"
    LOBBYN_TOURNAMENT_ORGANIZER_NAME="$LOBBYN_USER_NAME"
    LOBBYN_TOURNAMENT_REGION=$(echo "$persistentSettings" | jq -r '.region')
    LOBBYN_TOURNAMENT_MODERATORS=$(echo "$persistentSettings" | jq -r '.moderators')
    LOBBYN_TOURNAMENT_STATUS=$(echo "$persistentSettings" | jq -r '.status')
    LOBBYN_TOURNAMENT_PARTICIPANT_COUNT=$(echo "$persistentSettings" | jq -r '.participantCount')
    LOBBYN_TOURNAMENT_TEAM_COUNT=$(echo "$persistentSettings" | jq -r '.teamCount')
    
    LOBBYN_TOURNAMENT_PERSISTENT_INFO=$(jo -p \
        id="$LOBBYN_TOURNAMENT_ID" \
        organizerId="$LOBBYN_TOURNAMENT_ORGANIZER_ID" \
        region="$LOBBYN_TOURNAMENT_REGION" \
        moderators="$LOBBYN_TOURNAMENT_MODERATORS" \
        status="$LOBBYN_TOURNAMENT_STATUS" \
        participantCount=$LOBBYN_TOURNAMENT_PARTICIPANT_COUNT \
        teamCount=$LOBBYN_TOURNAMENT_TEAM_COUNT \
    )

    LOBBYN_TOURNAMENT_MODIFIABLE_INFO=$(jo -p \
        name="$LOBBYN_TOURNAMENT_NAME" \
        description="$LOBBYN_TOURNAMENT_DESCRIPTION" \
        teamSize=$LOBBYN_TOURNAMENT_TEAMSIZE \
        gamemode="$LOBBYN_TOURNAMENT_GAMEMODE" \
        format="$LOBBYN_TOURNAMENT_FORMAT" \
        visibility="$LOBBYN_TOURNAMENT_VISIBILITY" \
        joinPolicy="$LOBBYN_TOURNAMENT_JOIN_POLICY" \
    )
}