#!/bin/bash
# Generates a simple multi-page test PDF in ~/Downloads (no dependencies besides python3)

read -p "How many pages to generate: " pages

if ! [[ "$pages" =~ ^[1-9][0-9]*$ ]]; then
  echo "Invalid number: $pages"
  exit 1
fi

output_path=~/Downloads/test-${pages}-pages.pdf

python3 - "$pages" "$output_path" <<'EOF'
import sys

pages = int(sys.argv[1])
output_path = sys.argv[2]

objs = ["<< /Type /Catalog /Pages 2 0 R >>"]
kids = " ".join(f"{3 + i * 2} 0 R" for i in range(pages))
objs.append(f"<< /Type /Pages /Kids [{kids}] /Count {pages} >>")
font_id = 3 + pages * 2
for i in range(pages):
    n = i + 1
    text = (f"BT /F1 36 Tf 72 720 Td (Test page {n}) Tj /F1 14 Tf 0 -40 Td "
            f"(This is a sample PDF for testing. Page {n} of {pages}.) Tj ET")
    objs.append(f"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents {4 + i * 2} 0 R "
                f"/Resources << /Font << /F1 {font_id} 0 R >> >> >>")
    objs.append(f"<< /Length {len(text)} >>\nstream\n{text}\nendstream")
objs.append("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>")

out = b"%PDF-1.4\n"
offsets = []
for i, o in enumerate(objs, 1):
    offsets.append(len(out))
    out += f"{i} 0 obj\n{o}\nendobj\n".encode()
xref = len(out)
out += f"xref\n0 {len(objs) + 1}\n0000000000 65535 f \n".encode()
for off in offsets:
    out += f"{off:010d} 00000 n \n".encode()
out += f"trailer\n<< /Size {len(objs) + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF\n".encode()

with open(output_path, "wb") as f:
    f.write(out)
EOF

echo "Created $output_path"
