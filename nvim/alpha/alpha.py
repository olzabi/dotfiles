input_file = "play.txt"
output_file = "play_fmt.txt"

with open(input_file, "r",encoding="utf-8") as f:
    content = f.read()

frames = content.split("SPLIT")
fmt_frames = []
for frame in frames:
    frame_lines = frame.strip().split("\n")
    fmt_frames.append("Frame:\n" + "\n".join(frame_lines) + "\n=")

with open(output_file, "w", encoding="utf-8") as f:
    f.write("\n".join(fmt_frames))

print(f"Formatted as {output_file}")
