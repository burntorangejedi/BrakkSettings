import re
import urllib.request

url = "https://www.wowhead.com/guide/professions/knowledge-points"

with urllib.request.urlopen(url) as response:
    html = response.read().decode("utf-8")

items = {}
pattern = re.compile(r'item=(\d+)[^"]*">([^<]+)<')

for item_id, name in pattern.findall(html):
    items[int(item_id)] = name.strip()

output_file = "knowledge_items.lua"
with open(output_file, "w", encoding="utf-8") as f:
    for item_id in sorted(items):
        f.write(f"{item_id}, -- {items[item_id]}\n")

print(f"Wrote {len(items)} items to {output_file}")
