#!/usr/bin/env bash

# Use pactl to list input sources

mapfile -t lines < <(pactl list short sources | grep -v ".monitor")

if [ "${#lines[@]}" -eq 0 ]; then
  notify-send "Rofi Audio" "No input devices found"
  exit 1
fi

menu=""
for line in "${lines[@]}"; do
  index=$(echo "$line" | awk '{print $1}')
  desc=$(pactl list sources | awk -v idx="$index" '
    $0 ~ "Source #"idx {found=1}
    found && /Description:/ {sub(/^[ \t]*Description: /,""); print; exit}
  ')
  menu+="$index: $desc\n"
done

chosen=$(printf "%b" "$menu" | rofi -dmenu -p "Input device" -i)

[ -z "$chosen" ] && exit 0

sel_index="${chosen%%:*}"

# Set default source
pactl set-default-source "$sel_index"

notify-send "Rofi Audio" "Switched input to: ${chosen#*: }"
