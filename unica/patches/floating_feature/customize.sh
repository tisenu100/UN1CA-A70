READ_AND_APPLY_CONFIGS()
{
    local CONFIG_FILE="$SRC_DIR/target/$TARGET_CODENAME/sff.sh"

    if [ -f "$CONFIG_FILE" ]; then
        while read -r i; do
            [[ "$i" = "#"* ]] && continue
            [[ -z "$i" ]] && continue

            if echo -n "$i" | grep -q "="; then
                if [[ -z "$(echo -n "$i" | cut -d "=" -f 2)" ]]; then
                    SET_FLOATING_FEATURE_CONFIG "$(echo -n "$i" | cut -d "=" -f 1)" --delete
                else
                    SET_FLOATING_FEATURE_CONFIG "$(echo -n "$i" | cut -d "=" -f 1)" "$(echo -n "$i" | cut -d "=" -f 2)"
                fi
            else
                echo "Malformed string in target/$TARGET_CODENAME/sff.sh: \"$i\""
                return 1
            fi
        done < "$CONFIG_FILE"
    fi
}

# Apply target floating feature
READ_AND_APPLY_CONFIGS