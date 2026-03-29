#!/bin/bash

# Path to the temporary flag
FLAG="/tmp/hypr_ocr_active"

case "$1" in
    hold)
        # 1. Create the flag so the release event knows to stay quiet
        touch "$FLAG"
        # 2. Run your OCR script
        ~/.config/hypr/scripts/ocr.sh
        ;;
    release)
        # 1. If the flag exists, it means the long-press (OCR) already happened
        if [ -f "$FLAG" ]; then
            rm "$FLAG"
        else
            # 2. If no flag exists, it was a quick tap, so take a normal screenshot
            grim -g "$(slurp)" - | wl-copy
        fi
        ;;
esac
