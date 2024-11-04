LOBBYN_CLEAR_ERROR(){
    for var in "${!LOBBYN_ERROR_@}"; do
        unset "$var"
    done
}