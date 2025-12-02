#!/usr/bin/env bash

# Use pactl (works with PulseAudio & PipeWire's pulse emulation)

# Get list of output sinks: index + description
mapfile -t lines < <(pactl list short sinks)

if [ "${#lines[@]}" -eq 0 ]; then
  notify-send "Rofi Audio" "No output devices found"
  exit 1
fi

# Build a menu: "index: description"
menu=""
for line in "${lines[@]}"; do
  # Fields: index name driver sample_rate state ...
  index=$(echo "$line" | awk '{print $1}')
  desc=$(pactl list sinks | awk -v idx="$index" '
    $0 ~ "Sink #"idx {found=1}
    found && /Description:/ {sub(/^[ \t]*Description: /,""); print; exit}
  ')
  menu+="$index: $desc\n"
done

chosen=$(printf "%b" "$menu" | rofi -dmenu -p "Output device" -i)

[ -z "$chosen" ] && exit 0

# Extract index before the colon
sel_index="${chosen%%:*}"

# Set default sink
pactl set-default-sink "$sel_index"

# Move currently playing streams to the new sink
for input in $(pactl list short sink-inputs | awk '{print $1}'); do
  pactl move-sink-input "$input" "$sel_index"
done

notify-send "Rofi Audio" "Switched output to: ${chosen#*: }"
